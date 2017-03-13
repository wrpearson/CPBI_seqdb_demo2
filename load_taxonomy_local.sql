use seqdb_demo;
--
delete from taxon_name;
alter table taxon_name auto_increment=1;
load data local infile "TAX_NAMES.TAB" into table taxon_name (taxon_id, name, class);
-- 
delete from taxon;
load data local infile "TAX_NODES.TAB" into table taxon (taxon_id, parent_id, rank);
