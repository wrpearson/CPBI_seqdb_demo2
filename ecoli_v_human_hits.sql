use search_demo;
SELECT expect as 'E()', percid, alen,
        q.acc, substr(q.descr,1,24) as Ecoli_prot,
	 l_acc, substr(l.descr,1,24) as Human_prot
  FROM search_hit
  JOIN search_query USING(query_id)
  JOIN seqdb_demo.annot AS q ON(q.acc=search_query.acc)
  JOIN seqdb_demo.annot AS l ON(l.acc=l_acc)
  WHERE search_id=1 AND hit_rank=1 ORDER by bits DESC LIMIT 20;
