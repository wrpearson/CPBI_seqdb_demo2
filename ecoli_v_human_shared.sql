use search_demo;

SELECT COUNT(DISTINCT(query_id)) AS ecoli_shared
FROM search_hit
JOIN search USING (search_id)
WHERE tag = 'ecoli_v_human_bp'
AND expect < 1e-6;

SELECT COUNT(DISTINCT(l_acc)) AS human_shared
FROM search_hit
JOIN search USING (search_id)
WHERE tag = 'ecoli_v_human_bp'
AND expect < 1e-6;
