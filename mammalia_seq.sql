SELECT CONCAT('>',db,'|',acc,' ',descr,"\n",seq)
FROM   taxon AS all_mam
       JOIN taxon AS mam_tx
           ON (all_mam.left_id BETWEEN mam_tx.left_id AND mam_tx.right_id)
       JOIN taxon_name as mam_name ON(mam_tx.taxon_id=mam_name.taxon_id)
       JOIN annot ON (annot.taxon_id=all_mam.taxon_id)
       JOIN protein USING(prot_id)
WHERE db='up'
  AND mam_name.name = 'Mammalia'
  AND mam_name.class = 'scientific name';
