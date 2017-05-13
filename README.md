## SQL and Perl scripts to support "Using Relational Databases for Improved Sequence Similarity Searching and Large-Scale Genomic Analyses"
### Current Protocols in Bioinformatics, Unit 9.4

#### May 12, 2017

Programs | description
---------| -----------
`load_seqdb_local.pl` | Load a FASTA format sequence database into the seqdb_demo database
`load_taxonomy_local.pl` | load information from the NCBI taxonomy database into seqdb_demo database
`load_search_bl_tab.pl` | load a set of search results in BLAST tabular format into the search_demo database

SQL scripts | description
------------| -----------
`create_seqdb_demo.sql` | create the `seqdb_demo` database and assign user permissions
`seqdb_demo.sql` | initialize the tables in `seqdb_demo`
`load_seqdb_local.sql` | SQL to load PROTEIN.TAB, ANNOT.TAB, and INFO.TAB into `seqdb_demo`
`qfo_load_accession2taxid.sql` | associate accessions from the `qfo_demo` database with sequences in `seqdb_demo`
`load_accession2taxid.sql` | associate accessions from the NCBI `nr` database with sequences in `seqdb_demo`
`human_seq.sql` | produce a set of human Uniprot sequences in FASTA format
`mammalia_seq.sql` | produce a set of mammalian Uniprot sequences in FASTA format from `seqdb_demo`
`mammalia_acc.sql` | produce a set of accessions for mammalian Uniprot sequences from `seqdb_demo`
`ecoli_seq.sql` | produce a set of E. coli Uniprot sequences in FASTA format
`create_search_demo.sql` | create the `search_demo` database and assign user permissions
`search_demo.sql` | initialize the tables in `search_demo`
`ecoli_v_human_shared.sql` | report counts of E. coli sequences in human, and vice-versa, using `search_demo`
`ecoli_v_human_hits.sql` | report best scores between E. coli and human sequences using `search_demo`
`ecoli_v_qfo_kingdom.sql` | build a temporary table listing the `query_id` and kingdom `taxon_id`
`ecoli_v_qfo_kingdom_summ.sql` | summarize hits between E. coli queries and sequences in `qfo_demo`

In addition, the `run_seqdb_demo.sh` script is provided, which
exercises all the steps outlined in Unit 9.4.  However, this script
*must* be downloaded before the CPBI_seqdb_demo2 package, because it
downloads the package.

William R Pearson
wrp@virginia.edu
