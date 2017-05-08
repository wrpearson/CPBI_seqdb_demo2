#!/usr/bin/perl -w

# read the current specified file and add new sequence data to the
# database, replacing any previous data.

use strict;
use Getopt::Long;

my ($do_load, $load_only, $do_log, $log_inc) = (0,0,0,2000000);
my ($db_type, $db, $host, $user, $password) = ("mysql", "seqdb_demo", "localhost", "seq_user", "seq_password");

print STDERR "#",join(" ",($0,@ARGV)),"\n";

GetOptions(
	   "db_type=s" => \$db_type,
	   "db|database=s" => \$db,
	   "user=s" => \$user,
	   "password=s" => \$password,
	   "host=s" => \$host,
	   'do_load'=> \$do_load,
	   'load_only'=> \$load_only,
    	   'log'=>\$do_log,
          );

# filename should be specified at command line
my $seqfile = shift(@ARGV) or die "Usage: $0 filename\n";

# define the preferred database source annotation order:

my ($added, $new) = (0,0);

my %new_db = ();

# open three files, ANNOT.TAB, PROTEIN.TAB, INFO.TAB which can be loaded later
#

if ($load_only) {
  load_db($db_type);
  exit(0);
}

print STDERR " [ @{[scalar localtime]} ... \n";

my $prot_id = 0;
open(my $IFD, ">INFO.TAB") || die "cannot open INFO.TAB";
open(my $AFD, ">ANNOT.TAB") || die "cannot open ANNOT.TAB";
open(my $SFD, ">PROTEIN.TAB") || die "cannot open PROTEIN.TAB";

# read in the sequences from database:
open(SEQ, $seqfile) or die $!;

my ($seq, $header) = ("", "");
while (my $line = <SEQ>) {

  chomp($line);

  if ($line =~ m/^>/) {
    if ($header) {
      $added++;
      process_header($header, $prot_id);
      process_seq($seq, $prot_id);
      $seq="";
    }
    $prot_id++;
    $header = $line;
  }
  else {
    $seq .= $line;
  }

  if ($do_log && (($prot_id % $log_inc) == ($log_inc-1))) {
    print STDERR "  ".scalar(localtime)." $prot_id\n";
  }
}

if ($header) {
  $added++;
  process_header($header, $prot_id);
  process_seq($seq, $prot_id);
}

# write out INFO.TAB
process_info($added);

if ($do_load) {
  load_db($db_type);
}

close(SEQ);
close($AFD);
close($SFD);

#print "@{[scalar localtime]} ] Added $added new sequence@{[$added != 1 ? 's' : '']}, $new new annots\n";
print STDERR "@{[scalar localtime]} ] Added $added new sequence@{[$added > 1 ? 's' : '']}, $new new annots\n";
print STDERR "\n";

exit(0);

sub process_header {
  my ($header, $prot_id) = @_;

  $header =~ s/^>//;
  if ($header =~ m/^pdb/ && $header =~ m/\-\001/) {
    $header =~ s/\-\001/\->/g;
  }

  my @annots = map {
    my %data;
    @data{qw(seqid desc)} = ($_ =~ m/^(\S+)\s+(.+)$/o);
    \%data;
  } split(/\001/, $header);

  # now add all the entries:
  for my $annot ( @annots ) {
    if ($annot->{seqid}) {
      add_annot($annot, $prot_id);
    }
    else {
      warn "corrupted header at $prot_id :: $header";
    }
  }
}

sub process_seq {
  my ($seq, $prot_id) = @_;

  $seq =~ s/\W|\d|_//sg; # strip non-alphanumeric and numeric characters (leaving alpha)

  # add the protein sequence:
  print $SFD join("\t",($prot_id, $seq, length($seq))),"\n";
}

sub process_info {
  my ($added) = @_;

  ################################################################
  # get the unix epoch datetime for the database file, which can be converted back with FROM_UNIXTIME()
  # and the number of nr entries

  my $file_date = (stat($seqfile))[9];

  if ($db_type =~ m/pg/) {
    my $time_stamp = scalar(localtime($file_date));
    $time_stamp =~ s/^\w{3}\s//;
    print $IFD join("\t",($time_stamp, $added)),"\n";
  }
  else {
    print $IFD join("\t",($file_date, $added)),"\n";
  }
  close $IFD;
}

sub add_annot {
    my ($annot, $protein_id) = @_;

    # no longer have databases, all database code, and $pref, is deprecated
    # no longer have $gi in distribution

    my $seqid = $annot->{seqid};

    unless ($seqid) {
      warn(" missing seqid: ".$annot->{desc}." at $protein_id");
      return;
    }

    my ($db, $acc, $ver, $id1, $id2) = ('\N',"",'\N','\N',"","");
    if ($seqid =~ m/\|/) {
      ($db, $id1, $id2) = split(/\|/,$seqid);
      if ($db eq 'pir' || $db eq 'prf') {
	$acc = $id2;
      }
      elsif ($db eq 'pdb') {
	$acc = $id1.$id2;
      }
      else {
	# not pir/pdb/
	unless ($new_db{$db}) {
	  warn "new DB: $seqid";
	  $new_db{$db} = $seqid;
	}
	if ($id1) {
	  $acc = $id1;
	}
	elsif ($id2) {
	  $acc = $id2;
	}
	else {
	  $acc = $seqid;
	}
      }
    }
    else {
      # refseq/uniprot/genbank...
      ($acc,$ver) = ($seqid =~ m/^(\w+)\.?(\d*)$/);

      unless ($acc) {
	warn "missing acc/ver: $seqid";
	$acc = $seqid;
      }

      if ($acc =~ m/^[A-Z]P_/) {
	$db = 'ref';
      }
      elsif ($acc =~ m/^[OPQ][0-9][A-Z0-9]{3}[0-9]|[A-NR-Z][0-9]([A-Z][A-Z0-9]{2}[0-9]){1,2}$/) {
	$db = 'up';
	$annot->{desc} =~ s/RecName: Full=//g;
	$annot->{desc} =~ s/AltName: Full=//g;
	$annot->{desc} =~ s/; Short=/; /g;
      }
    }

    unless (defined($annot->{desc})) {
      $annot->{desc} = "";
    }
    print $AFD join("\t",($protein_id,$db, $acc, $ver, $annot->{desc})),"\n";
    $new++;
}

## both methods for providing the database password should be considered insecure.
## 

sub load_db {
  my ($db_type) = @_;

  $host = "-h $host" if $host;

  if ($db_type =~ m/pg/) {
    $ENV{PGPASSWORD}=$password;
    system(qq(psql $host -U $user $db < load_seqdb_local.psql));
  }
  else {
    $ENV{MYSQL_PW}=$password;
    system(qq(mysql $host -u $user -p$password $db < load_seqdb_local.sql));
  }
}
