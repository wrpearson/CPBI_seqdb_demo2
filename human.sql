--
-- Basic Protocol 2 -- extract human protein sequences with Uniprot accession
--
SELECT CONCAT(">", db, "|", acc, "| ", descr, "\n", seq)
FROM   protein
       INNER JOIN annot USING (prot_id)
       INNER JOIN taxon_name USING (taxon_id)
WHERE  db='up'
  AND  taxon_name.class = "scientific name"
  AND  taxon_name.name = "Homo sapiens";
