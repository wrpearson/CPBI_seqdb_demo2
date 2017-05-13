#!/bin/sh

################
## this is a sample script that tests most of the instructions in:
##
## "Using Relational Databases for Improved Sequence Similarity
## Searching and Large-Scale Genomic Analyses" Current Protocols in
## Bioinformatics, Unit 9.4, 2017
##
## This script assumes it is being run in a new, empty directory, that
## will hold the sequence databases and the seqdb_demo/ scripts in the
## "seqdb_demo/" subdirectory
##
## In addition, the two mysql commands run as "-u root" require
## interaction to provide the root password

## download the sequence accession2taxid data:
curl -O https://zenodo.org/record/377027/files/qfo_demo.gz
curl -O https://zenodo.org/record/377027/files/qfo_pdb.accession2taxid.gz
curl -O https://zenodo.org/record/377027/files/qfo_prot.accession2taxid.gz

## download the seqdb_demo sql and scripts
curl -O http://faculty.virginia.edu/wrpearson/CPBI_seqdb_demo2/CPBI_seqdb_demo.tar2.gz
tar zxvf CPBI_seqdb_demo2.tar.gz

## create the database
cd seqdb_demo
mysql -u root -p < create_seqdb_demo.sql
mysql -u seqdb_writer -pwriter_pass seqdb_demo < seqdb_demo.sql

# check that tables are present
mysql -useqdb_reader -preader_pass -e 'show tables; describe annot;' seqdb_demo

# uncompress the sequence data and load the database
gunzip ../qfo_demo.gz
load_seqdb_local.pl --do_load ../qfo_demo
# alternatively
# load_seqdb_local.pl ../qfo_demo
# mysql -u seqdb_writer -p  seqdb_demo < load_seqdb_local.sql 

## check that sequences are loaded
mysql -useqdb_reader -preader_pass -e 'select count(*) from protein; select count(*) from annot; select * from protein where prot_id=790;' seqdb_demo


# download the NCBI taxonomy data
mkdir ../taxdata
load_taxonomy_local.pl --do_load --DOFTP ../taxdata

# check that the taxonomy tables are loaded
# (1,2) check for the number of taxa, and list human taxon_name's
mysql -useqdb_reader -preader_pass -e 'select count(*) from taxon; select * from taxon_name where taxon_id=9606;' seqdb_demo
# (2) list sequence information on a protein
mysql -useqdb_reader -preader_pass -e 'select db, acc, taxon_id, descr from annot where prot_id=790;' seqdb_demo

## return to initial directory so that the qfo_prot_accession2taxid
## and qfo_pdb_accession2taxid files, which map taxon_id's to
## accessions, can be loaded
cd ..
mysql -u seqdb_writer -pwriter_pass seqdb_demo < seqdb_demo/qfo_load_accession2taxid.sql

# return to seqdb_demo to extract human sequences
cd seqdb_demo
mysql -rN -useqdb_reader -preader_pass seqdb_demo < human.sql > human.fasta

# list the number of human sequences from each of the databases
mysql -useqdb_reader -preader_pass -e 'select db, count(acc) as acc_cnt from annot where taxon_id=9606 group by db;' seqdb_demo

# produce a set of mammalian sequences
mysql -rN -u seqdb_reader -preader_pass seqdb_demo < mammalia_seq.sql > mammalia.fasta

# return to seqdb_demo to 
mysql -rN -u seqdb_reader -preader_pass seqdb_demo < mammalia_acc.sql > mammalia.acc

# return to .. to put qfo_demo in blast format
cd ..
makeblastdb -in qfo_demo -title qfo_demo -parse_seqids -dbtype prot

cd seqdb_demo
curl http://www.uniprot.org/uniprot/P30711.fasta > gstt1_human.fasta

echo `date`
blastp -query gstt1_human.fasta -seqidlist mammalia.acc -db ../qfo_demo > gstt1_v_mammalia.blastp
echo `date`

################
## done with seqdb_demo creation/manipulation, build search_demo database
################

mysql -u root -p < create_search_demo.sql    # must be run interactively
mysql -u seqdb_writer -pwriter_pass search_demo < search_demo.sql
mysql -u seqdb_reader -preader_pass -e 'show tables; describe search_hit;' search_demo

# build blast format database from previously created human.fasta file
echo `date`
makeblastdb -in human.fasta -title human_up -out human_up -parse_seqids -dbtype prot

# extract seqdb_demo E. coli sequences for ecoli_v_human search
echo `date`
mysql -u seqdb_reader -preader_pass seqdb_demo < ecoli.sql > ecoli_up.fasta

# compare ecoli_up.fasta to human_up blast database
echo `date`
blastp -num_threads 8 -outfmt 7 -query ecoli_up.fasta -db human_up -evalue 1.0 > ecoli_v_human.bp

# load results of ecoli/human comparison
echo `date`
load_search_bl_tab.pl --tag ecoli_v_human_bp --algo blastp --doload ecoli_v_human.bp &

# characterize ecoli_human homologs
echo `date`
mysql -useqdb_reader -preader_pass search_demo < ecoli_v_human_shared.sql

# run ecoli sequences vs qfo_demo sequences -- takes 20 - 60 min on multicore machine
blastp -num_threads 16 -outfmt 7 -query ecoli_up.fasta -db ../qfo_demo -evalue 1.0 > ecoli_v_qfo.bp

# load ecoli_v_qfo results
load_search_bl_tab.pl --tag ecoli_v_qfo_bp --algo blastp --doload ecoli_v_qfo.bp > load_ec_qfo.log

## do the final analysis of E. coli homologs in the three kingdoms
echo `date`
mysql -useqdb_writer -pwriter_pass -e 'source ecoli_v_qfo_kingdom.sql; source ecoli_qfo_kingdom_summ.sql;' search_demo
