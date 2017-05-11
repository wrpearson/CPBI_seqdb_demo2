#!/usr/bin/perl -w

use strict;

################
# load_taxonomy_local.pl -- load the names.dmp and nodes.dmp data from
# the NCBI /pub/taxonomy/taxdump.tar.gz file to populate the
# seqdb_demo "taxon_name" and "taxon" tables.
#
# usage -- load_taxonomy_local.pl --user seqdb_writer --pass writer_pass --host localhost --DOFTP 0 --do_load --taxdir /slib/taxonomy
#
# --DOFTP downloads the files necessary to --taxdir before extracting
#         the names.dmp and nodes.dmp files
#
################

use DBI;
use Getopt::Long;

my ($db_type, $db, $host, $user, $pass) = ("mysql", "seqdb_demo", "localhost", "seqdb_writer", "writer_pass");
my ($do_load, $DOFTP, $taxdir, $clean_up) = ( 1, 0, "",0);

GetOptions("db|database=s" => \$db,
	   "cleanup|clean_up|clean-up!" => \$clean_up,
           "user=s" => \$user,
	   "do_load|doload|do-load!" => \$do_load,
	   "DOFTP" => \$DOFTP,
	   "FTPdown" => \$DOFTP,
           "pass|password=s" => \$pass,
	   "taxdir=s" => \$taxdir,
           "host=s" => \$host,
          );

unless ($taxdir) {
  $taxdir = shift(@ARGV) # what is the $taxdir directory?
}

# remove trailing directory separator, if necessary:
$taxdir =~ s%/$%%;

# go get the files we need:
if ($DOFTP) {
    my $ftp_url = "ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy";

    system("cd $taxdir; curl --silent -O $ftp_url/taxdump.tar.gz");
    system("cd $taxdir; tar -zxf taxdump.tar.gz");
}

my $connect = "dbi:mysql";
$connect .= "(AutoCommit=>1):database=$db";

if ($host) {
    $connect .= ";host=$host";
}

my $dbh = DBI->connect($connect,
		       $user,
		       $pass,
		       { RaiseError => 1,
			 AutoCommit => 1,
			 PrintError => 1
		       }
		      ) or die $DBI::errstr;

my %sth = (
   get_children => q{SELECT taxon_id FROM taxon WHERE parent_id = ?},
   set_left => q{UPDATE taxon SET left_id = ? WHERE taxon_id = ?},
   set_right => q{UPDATE taxon SET right_id = ? WHERE taxon_id = ?},
   );

# prepare all our statements
@sth{keys %sth} = map { $dbh->prepare($_) } values %sth;

# my @locktables = qw(taxon_gc taxon taxon_name annot);
my @locktables = qw( taxon taxon_name);

# lock all the tables we'll need:
$dbh->do('LOCK TABLES ' . join(", ", map { $_ .= ' WRITE' } @locktables));

my ($ins, $upd, $del, $nas);

################
# empty and repopulat taxon_name

open(NAME_IN, "<$taxdir/names.dmp") or die $!;
open(NAME_OUT, ">TAX_NAMES.TAB") or die $!;
while(my $line = <NAME_IN>) {
  chomp($line);
  my ($taxon_id,$name, $u_name, $class) = split(/\t\|\t?/,$line);
  print NAME_OUT join("\t",($taxon_id, $name, $class)),"\n";
}
close NAME_IN;
close NAME_OUT;

if ($do_load) {
  $dbh->do(q{DELETE FROM taxon_name});
  $dbh->do(q{ALTER TABLE taxon_name AUTO_INCREMENT=1});
  $dbh->do(q{LOAD DATA LOCAL INFILE "TAX_NAMES.TAB" INTO TABLE taxon_name (taxon_id, name, class)});
  if ($clean_up) { unlink("TAX_NAMES.TAB");}
}

print STDERR "  taxon_name reloaded:  @{[ scalar localtime ]}\n";

open(NODES_IN, "<$taxdir/nodes.dmp") or die $!;
open(NODES_OUT, ">TAX_NODES.TAB") or die $!;
while (my $line = <NODES_IN>) {
  chomp($line);
  print NODES_OUT join("\t",(split(/\s*\|\s*/o, $line))[0..2]),"\n";
}
close(NODES_IN);
close(NODES_OUT);

if ($do_load) {
  $dbh->do(q{DELETE FROM taxon});
  $dbh->do(q{LOAD DATA LOCAL INFILE "TAX_NODES.TAB" INTO TABLE taxon (taxon_id, parent_id, rank)});
  if ($clean_up) { unlink("TAX_NODES.TAB");}
}

print STDERR "  taxon/nodes reloaded:  @{[ scalar localtime ]}\n";

$dbh->do('UNLOCK TABLES');

print "    rebuilding nested set @{[ scalar localtime ]}\n";

##### rebuild the nested set left/right id':

$dbh->do('LOCK TABLES taxon WRITE');

my $nodectr = 0;
handle_subtree(1);

$dbh->do('UNLOCK TABLES');

# clean up statement/database handles:
for my $sth (values %sth) {
  if (ref($sth) && $sth->{Active}) {
    $sth->finish();
  }
}

print "ended @{[scalar localtime]}\n";

$dbh->disconnect();

sub handle_subtree {

  my $id = shift;

  $sth{set_left}->execute(++$nodectr, $id);

  $sth{get_children}->execute($id);
  for my $child ( @{$sth{get_children}->fetchall_arrayref()} ) {
    handle_subtree($child->[0]) unless $child->[0] == $id;
  }

  $sth{set_right}->execute(++$nodectr, $id);
}
