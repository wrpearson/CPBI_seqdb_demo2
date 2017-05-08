--
-- this file requires that the temporary table "temp_results" exists
--
DROP TABLE IF EXISTS kingdom_counts;
CREATE TEMPORARY TABLE kingdom_counts (
  query_id INT(10) UNSIGNED PRIMARY KEY,
  bact_cnt INT(10) UNSIGNED,
  arch_cnt int(10) UNSIGNED, 
  euk_cnt int(10) UNSIGNED
) engine=MEMORY;

INSERT INTO kingdom_counts (query_id)
  SELECT DISTINCT query_id FROM temp_results ;

-- count archaeal hits
UPDATE kingdom_counts AS kc 
  JOIN (SELECT query_id, COUNT(query_id) AS cnt
        FROM temp_results JOIN seqdb_demo.taxon_name USING(taxon_id)
        WHERE name='Archaea' AND class='scientific name' GROUP BY query_id) AS arch USING(query_id)
   SET kc.arch_cnt=arch.cnt;

-- count bacterial hits
UPDATE kingdom_counts AS kc
  JOIN (SELECT query_id, count(query_id) AS cnt
        FROM temp_results JOIN seqdb_demo.taxon_name USING(taxon_id)
        WHERE name='Bacteria' AND class='scientific name' GROUP BY query_id) AS bact USING(query_id)
   SET kc.bact_cnt=bact.cnt;

-- count eukaryote hits
UPDATE kingdom_counts AS kc
  JOIN (SELECT query_id, count(query_id) AS cnt
        FROM temp_results JOIN seqdb_demo.taxon_name USING(taxon_id)
        WHERE name='Eukaryota' AND class='scientific name' GROUP BY query_id) AS euk USING(query_id)
   SET kc.euk_cnt=euk.cnt;

-- produce summary -- no hits to any kingdom (other than E. coli)
SELECT COUNT(DISTINCT(query_id)) AS NO_NULL FROM kingdom_counts
 WHERE bact_cnt IS NOT NULL and arch_cnt IS NOT NULL and euk_cnt IS NOT NULL;

-- bact,euk not null, arch null
SELECT COUNT(DISTINCT(query_id)) AS arch_NULL from kingdom_counts
 WHERE bact_cnt IS NOT NULL and arch_cnt IS NULL and euk_cnt IS not NULL;

-- arch, euk not null, bact null
SELECT COUNT(DISTINCT(query_id)) AS bact_NULL from kingdom_counts
 WHERE bact_cnt IS NULL and arch_cnt IS not NULL and euk_cnt IS not NULL;

-- bact, arch not null, euk null
SELECT COUNT(DISTINCT(query_id)) AS euk_NULL from kingdom_counts
 WHERE bact_cnt IS NOT NULL and arch_cnt IS not NULL and euk_cnt IS NULL;

-- bact, arch null, euk not null
SELECT COUNT(DISTINCT(query_id)) AS arch_bact_NULL from kingdom_counts
 WHERE bact_cnt IS NULL and arch_cnt IS NULL and euk_cnt IS not NULL;

-- arch, euk null, bact not null
SELECT COUNT(DISTINCT(query_id)) AS arch_euk_NULL from kingdom_counts
 WHERE bact_cnt IS NOT NULL and arch_cnt IS NULL and euk_cnt IS NULL;

-- bact, euk null, arch not null
SELECT COUNT(DISTINCT(query_id)) AS bact_euk_NULL from kingdom_counts
 WHERE bact_cnt IS NULL and arch_cnt IS not NULL and euk_cnt IS NULL;

-- all null (must be zero)
SELECT COUNT(DISTINCT(query_id)) AS ALL_NULL from kingdom_counts
 WHERE bact_cnt IS NULL and arch_cnt IS NULL and euk_cnt IS NULL;
