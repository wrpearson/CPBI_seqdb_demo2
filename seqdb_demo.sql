
DROP TABLE IF EXISTS annot;
CREATE TABLE annot (
  prot_id int(10) unsigned NOT NULL DEFAULT '0',
  acc char(20) NOT NULL DEFAULT '',
  ver tinyint(3) unsigned NOT NULL DEFAULT '1',
  db char(10) NOT NULL,
  db_pref tinyint(3) unsigned NOT NULL DEFAULT '0',
  gi int(10) unsigned NOT NULL DEFAULT '0',
  dna_acc char(20) DEFAULT NULL,
  sp_name char(20) DEFAULT NULL,
  taxon_id int(10) unsigned DEFAULT NULL,
  descr text NOT NULL,
  PRIMARY KEY (acc),
  KEY gi (gi),
  KEY prot_id (prot_id),
  KEY db (db),
  KEY db_acc (db,acc),
  KEY taxon_id (taxon_id),
  KEY db_pref (db_pref)
);

--
-- Table structure for table db_info
--

DROP TABLE IF EXISTS db_info;
CREATE TABLE db_info (
  date int(11) DEFAULT NULL,
  prot_entries int(11) DEFAULT NULL
);

--
-- Table structure for table protein
--

DROP TABLE IF EXISTS protein;
CREATE TABLE protein (
  prot_id int(10) unsigned,
  seq text NOT NULL,
  len int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (prot_id),
  KEY len (len)
);

--
-- Table structure for table taxon
--

DROP TABLE IF EXISTS taxon;
CREATE TABLE taxon (
  taxon_id int(10) unsigned NOT NULL DEFAULT '0',
  parent_id int(10) unsigned NOT NULL DEFAULT '0',
  left_id int(10) unsigned NOT NULL DEFAULT '0',
  right_id int(10) unsigned NOT NULL DEFAULT '0',
  rank enum('superphylum','superkingdom','parvorder','kingdom','superclass','infraclass','subphylum','superorder','infraorder','forma','phylum','species subgroup','subtribe','subclass','class','species group','suborder','subgenus','tribe','superfamily','varietas','order','subfamily','no rank','subspecies','family','genus','species','subkingdom') DEFAULT 'no rank',
  PRIMARY KEY (taxon_id),
  KEY parent_id (parent_id),
  KEY left_id (left_id),
  KEY right_id (right_id),
  KEY rank (rank),
  KEY left_right (left_id,right_id),
  KEY left_right_rank (left_id,right_id,rank),
  KEY left_rank (left_id,rank)
);

--
-- Table structure for table taxon_name
--

DROP TABLE IF EXISTS taxon_name;
CREATE TABLE taxon_name (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  taxon_id int(10) unsigned NOT NULL DEFAULT '0',
  name varchar(256) DEFAULT NULL,
  class enum('acronym','anamorph','blast name','common name','equivalent name','genbank acronym','genbank anamorph','genbank common name','genbank synonym','in-part','includes','misnomer','misspelling','preferred acronym','preferred common name','scientific name','synonym','teleomorph','authority','unpublished name') DEFAULT 'common name',
  PRIMARY KEY (id),
  KEY taxon_id (taxon_id),
  KEY class (class),
  KEY name (name)
);

