-- SQL to build temporary table associating query_id's with the taxon_id's of their hits
-- this file must be "sourced" before running ecoli_qfo_kingdom_summ.sql

DROP TABLE if exists temp_results;
CREATE TEMPORARY TABLE temp_results (
  query_id INT UNSIGNED NOT NULL DEFAULT 0, 
  taxon_id INT UNSIGNED NOT NULL DEFAULT 0, 
  KEY query_id (query_id),
  KEY taxon_id (taxon_id)
);

INSERT INTO temp_results (query_id, taxon_id)
SELECT query_id, kingdom.taxon_id
FROM   search_hit
JOIN   seqdb_demo.annot as la ON (l_acc=la.acc)
JOIN   seqdb_demo.taxon as lt USING (taxon_id)
JOIN   seqdb_demo.taxon AS kingdom  ON (lt.left_id BETWEEN kingdom.left_id AND kingdom.right_id)
JOIN   seqdb_demo.taxon_name as kingdom_name ON (kingdom.taxon_id = kingdom_name.taxon_id)
JOIN   seqdb_demo.taxon AS ecoli  ON (lt.left_id NOT BETWEEN ecoli.left_id AND ecoli.right_id)
JOIN   seqdb_demo.taxon_name AS ecoli_name ON (ecoli.taxon_id = ecoli_name.taxon_id)
JOIN   search USING(search_id)
WHERE  kingdom_name.name IN ('Bacteria', 'Eukaryota', 'Archaea')
  AND  kingdom_name.class = 'scientific name'
  AND  ecoli_name.name = 'Escherichia coli'
  AND  ecoli_name.class = 'scientific name'
  AND  expect < 1e-6
  AND  tag='ecoli_v_qfo_bp';

-- summarize results

set sql_mode='';
SELECT taxon_id, name, count(query_id) as s_cnt, count(distinct(query_id)) as q_cnt
 FROM  temp_results
 JOIN  seqdb_demo.taxon_name USING(taxon_id)
WHERE  class='scientific name'
GROUP BY name;
