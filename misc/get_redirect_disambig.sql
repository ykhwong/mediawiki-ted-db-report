SELECT DISTINCT target_title FROM (
	SELECT DISTINCT
	  page_title as target_title,
          REGEXP_REPLACE(page_title, '_\\(동음이의\\)$', '') as source_title
	FROM page
	WHERE page_namespace = 0
	      AND page_is_redirect = 0
	      AND page_title REGEXP '_\\(동음이의\\)$'
) AS t
WHERE EXISTS 
      (SELECT 1 FROM page JOIN redirect ON rd_from = page_id WHERE page_title = t.source_title AND page_is_redirect = 1
       AND rd_namespace = 0 AND rd_title = t.target_title
	)
;
