-- run as administrator
create temporary table acc2tax (acc char(20), accv char(24), taxon_id int(10) unsigned, gi int(10) unsigned, primary key (acc));
load data local infile 'pdb.accession2taxid' into table acc2tax;
update annot join acc2tax using(acc) set annot.taxon_id=acc2tax.taxon_id, annot.gi=acc2tax.gi, annot.db='pdb';
--
delete from acc2tax;
load data local infile 'prot.accession2taxid' into table acc2tax;
update annot join acc2tax using(acc) set annot.taxon_id=acc2tax.taxon_id, annot.gi=acc2tax.gi;
--
