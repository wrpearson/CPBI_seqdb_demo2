#!/usr/bin/perl -w

# non Bio::Perl version of load_search_s2.pl that:
# (1) reads a set of files in blast tabular format
# (2) updates the search table only once
# (3) for each file, update the search_query table using SQL (limited number of queries)
# (4) ...  write out the searchd_hit update stuff, then load it using load data local infile
# (5) continue to next file

# $dbh->do(qq(load data local infile '$tab_file' into table searchd_hit;));

####
# 14-Dec-2017 fix $q_acc recognition for no '|' (new NCBI libraries)
#             modify to include number of queries, query lengths

use strict;
use Getopt::Long;
use DBI;

use vars qw( $query_id $port);

my $hostname = `hostname`;

my ($db_type, $db, $host, $user, $pass) = ("mysql", "search_demo", "localhost", "seqdb_writer", "writer_pass");

my $debug = 0;

my $e_cutoff = 0.001;

my ($tag, $comment, $ori_data_file,  $search_id, $do_load, $matrix, $pgm_cmd) = ("", "", "", 0, 0, "BP62",0);

my ($algo, $algo_ver) = qw(BLASTP 2.2.30+);
my ($q_db_arg, $query_cnt) = ("", 0);

GetOptions(
    	   "db_type=s" => \$db_type,
	   "algo=s" => \$algo,
	   "algo_ver=s" => \$algo_ver,
	   "do_load|doload|do-load" => \$do_load,
	   "expect=s" => \$e_cutoff,
	   "host=s" => \$host,
	   "db=s" => \$db,
	   "user=s" => \$user,
	   "matrix=s" => \$matrix,
	   "ori_file=s" => \$ori_data_file,
	   "password=s" => \$pass,
	   "qdb=s" => \$q_db_arg, 
	   "q_db=s" => \$q_db_arg, 
	   "search_id=i" => \$search_id,
	   "tag=s" => \$tag,
	   "comment=s" => \$comment,
	   "pgm_cmd" => \$pgm_cmd,
	  );

my $connect = "dbi:mysql(AutoCommit=>1,RaiseError=>1):database=$db";
$connect .= ";host=$host" if $host;
$connect .= ";port=$port" if $port;

my $dbh = DBI->connect($connect,
		       $user,
		       $pass
		      ) or die $DBI::errstr;

my $upd_search_data = $dbh->prepare( <<EOS );
UPDATE search
  set algo=?, queryct=? where search_id=?
EOS

# first, define the tables and fields:
my %inserts = ( search => [ qw( tag comment file_date file_name algo algo_ver matrix cmd
			      )
                          ],

		search_query => [ qw(db acc qlen) ],

              );

# now, dynamically build and prepare each statement:
for my $name (keys %inserts) {
  my @fields = @{$inserts{$name}};
  $inserts{$name} = $dbh->prepare(
				  "INSERT INTO $name ( " . join(", ", @fields)  .
				  " ) VALUES ( " . join(", ", ("?") x @fields) . " )"
				 );
}

# prepare one more statement to find a lib entry
# if it's already been hit against:

my $find_query2 = $dbh->prepare(q{
    SELECT query_id
    FROM   search_query
    WHERE  db=?
    AND    acc=?
});

## the field names in these two arrays must be the same
my @tab_fields = qw(q_seqid s_seqid percid alen mismat gaps qbegin qend lbegin lend expect bits annot_str);
my @db_fields = qw(search_id query_id l_acc bits expect percid alen mismat gaps qbegin qend lbegin lend hit_rank annot_str);

my $res_handle;
my ($queryct, $querysize) = (0,0);
my $pgm_cmd_str = "";

for my $s_res_file ( @ARGV ) {

  next unless open($res_handle, $s_res_file);

  if ($pgm_cmd) {
    $pgm_cmd_str=<$res_handle>;
    chomp($pgm_cmd_str);
  }

  my ($s_res_name) = ($s_res_file =~ m/^([^.]+)\./);

  $ori_data_file = $s_res_file unless ($ori_data_file);

  $s_res_name .= ".hits";
  open(TFD,">$s_res_name") || die "cannot open $s_res_name";

  while ( my $query_descr = skip_to_results($res_handle)) {

    last unless $query_descr;

    $query_cnt++;

    unless ($search_id) {
	die "Must supply tag for search!\n" unless defined $tag;
	$inserts{search}->execute(
	    $tag, $comment, (stat($ori_data_file))[9], $s_res_file, $algo, $algo_ver, $matrix, $pgm_cmd_str) ;
	$search_id = $inserts{search}->{mysql_insertid};
    }

    my ($q_db, $q_acc, $q_id, $query_id) = ("","","","");
    ($query_id) = ($query_descr =~ m/^(\S+)/);

    if ($query_id =~ m/[\|:]/) {
      ($q_db, $q_acc, $q_id) = split(/[\|:]/,$query_id);
    }
    else {
      ($q_acc) = ($query_id =~ m/^(\w+)/);
      if ($query_id =~ m/^[NXY][PM]_/) {
	$q_acc =~ s/\.\d+$//;
	$q_db = 'ref';
      }
    }


    if ($q_acc =~ m/\.r$/) {
	$q_db .= "R";
	$q_acc =~ s/\.r$//;
    }

    $q_db = $q_db_arg if ($q_db_arg);

    my ($q_len) = ($query_descr =~ m/(\d+) aa$/);

    ## insert query in search_query
    # check to see if query available

    $find_query2->execute($q_db, $q_acc);
    if ($find_query2->rows > 0) {
      ($query_id) = $find_query2->fetchrow_array();
    } else {
      $inserts{search_query}->execute($q_db, $q_acc, $q_len);
      $query_id = $inserts{search_query}->{mysql_insertid};
    }

    my $hit_rank = 0;
    my $hsp_rank = 1;
    while (my $line = <$res_handle>) { # for each result
      if ($line =~ m/^#/) {
	if ($line =~ m/^# (\w+) processed (\d+) queries/) {
	  ($algo, $queryct) = ($1,$2);
	}
	last;
      }
      chomp ($line);
      $hit_rank++;

      my %afields = ();
      @afields{@tab_fields} = split(/\s+/,$line);

      $afields{annot_str} = '\N' unless $afields{annot_str};
      $afields{percid} /= 100.0;	# blast has percent identity, not fraction identity

      next if ($afields{expect} > $e_cutoff);

      if ($afields{s_seqid} =~ m/[\|:]/) {
	@afields{qw(l_db l_acc l_id)} = split(/[\|:]/,$afields{s_seqid});
      }
      else {
	$afields{l_db}= "";
	$afields{l_acc} = $afields{s_seqid};
	if ($afields{s_seqid} =~ m/_/) {
	  $afields{l_db} = 'ref';
	}
      }

      # should not remove "version" for SRR reads
      $afields{l_acc} =~ s/\.\d+$//;

      if (!$afields{l_acc}) {	# don't have accession, get it from Uniprot
	  warn "cannot find acc for $afields{l_acc}" unless ($afields{l_acc});
      }

      @afields{qw(search_id query_id hit_rank)} = ($search_id, $query_id, $hit_rank);

      # now we have all the info, print it to tab file 
      print TFD join("\t", @afields{@db_fields}),"\n";
    }
  }
  close TFD;

  $upd_search_data->execute($algo, $queryct, $search_id);

  print STDERR "file: $s_res_file; tag: $tag; queries: $query_cnt; search_id: $search_id";

  if ($do_load) {
    $dbh->do(qq(load data local infile '$s_res_name' into table search_hit) . "(" . join(",",@db_fields).");");
    unlink($s_res_name);
    print STDERR " -- data loaded";
  }

  print STDERR "\n";
}

## modified for BLAST tabular format
## returns ($query_desc, $algo, $queryct)
#
sub skip_to_results {
  my ($res_handle) = @_;
  my $query_desc;

  while (my $line = <$res_handle>) {
    if ($line =~ m/^# (\w+) processed (\d+) queries$/) {
      return "";	# all done
    }
    if ($line =~ m/^# No hits found/i) {
      return $query_desc;
    }
    if ($line =~ m/^# \d+ hits found/) {
      return $query_desc;
    }
    if ($line =~ m/^# Query:\s+(.*)$/) {
      ($query_desc) = ($1);
    }
  }
  return "";
}
