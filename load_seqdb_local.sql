-- must be run as administrative user with write priviledges
delete from annot;
load data local infile "ANNOT.TAB" into table annot (prot_id, db, acc, ver, descr);
delete from protein;
load data local infile "PROTEIN.TAB" into table protein (prot_id, seq, len);
delete from db_info;
load data local infile "INFO.TAB" into table db_info;

