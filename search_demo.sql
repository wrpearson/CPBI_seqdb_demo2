--
-- Basic Protocol 3 - declare tables in search_demo
--
-- Table structure for table search
--

DROP TABLE IF EXISTS search;
CREATE TABLE search (
  search_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  tag varchar(50) DEFAULT NULL,
  comment text,
  file_date int(10) DEFAULT NULL,
  file_name varchar(50) DEFAULT NULL,
  algo text,
  algo_ver text,
  queryct int(10) unsigned NOT NULL DEFAULT '0',
  querysize int(10) unsigned NOT NULL DEFAULT '0',
  libct int(10) unsigned NOT NULL DEFAULT '0',
  libsize int(10) unsigned NOT NULL DEFAULT '0',
  matrix text,
  cmd text,
  PRIMARY KEY (search_id),
  UNIQUE KEY tag (tag)
);

--
-- Table structure for table search_hit
--

DROP TABLE IF EXISTS search_hit;
CREATE TABLE search_hit (
  hit_id int(12) unsigned NOT NULL AUTO_INCREMENT,
  search_id int(10) unsigned NOT NULL DEFAULT '0',
  query_id int(10) unsigned DEFAULT NULL,
  l_acc char(40) DEFAULT NULL,
  bits double unsigned DEFAULT NULL,
  expect double unsigned DEFAULT NULL,
  expect2 double unsigned DEFAULT NULL,
  percid double unsigned DEFAULT NULL,
  alen int(10) unsigned NOT NULL DEFAULT '0',
  mismat int(10) unsigned NOT NULL DEFAULT '0',
  gaps int(10) unsigned NOT NULL DEFAULT '0',
  qbegin int(10) unsigned NOT NULL DEFAULT '0',
  qend int(10) unsigned NOT NULL DEFAULT '0',
  lbegin int(10) unsigned NOT NULL DEFAULT '0',
  lend int(10) unsigned NOT NULL DEFAULT '0',
  hit_rank int(4) DEFAULT '0',
  hsp_rank int(4) DEFAULT '0',
  align_str text,
  annot_str text,
  annot_cnt int(4) DEFAULT '0',
  PRIMARY KEY (hit_id),
  KEY search_id (search_id),
  KEY query_id (query_id),
  KEY l_acc (l_acc),
  KEY hit_rank (hit_rank),
  KEY search_id_qseq_lseq (search_id,query_id,l_acc),
  KEY hsp_rank (hsp_rank)
);

--
-- Table structure for table search_query
--

DROP TABLE IF EXISTS search_query;
CREATE TABLE search_query (
  query_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  db char(4) NOT NULL DEFAULT '',
  acc char(20) DEFAULT NULL,
  qlen int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (query_id),
  KEY db (db),
  KEY acc (acc)
);

