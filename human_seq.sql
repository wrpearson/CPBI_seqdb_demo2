--
-- Basic Protocol 2 -- extract human protein sequences with Uniprot accession
-- this is a simpler version of the SQL, that uses the taxon_id directly
--
SELECT CONCAT(">", db, "|", acc, "| ", descr, "\n", seq)
FROM   protein
       INNER JOIN annot USING (prot_id)
WHERE  db='up'
  AND  taxon_id=9606;
