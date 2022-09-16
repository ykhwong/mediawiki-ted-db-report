SELECT
  page_title,
  page_len,
  cat_pages,
  rev_timestamp
FROM revision
JOIN
(SELECT
   page_id,
   page_title,
   page_len,
   cat_pages
 FROM category
 RIGHT JOIN page
 ON cat_title = page_title
 LEFT JOIN categorylinks
 ON page_id = cl_from
 WHERE cl_from IS NULL
 AND page_namespace = 0
 AND page_is_redirect = 0) AS pagetmp
ON rev_page = pagetmp.page_id
AND rev_timestamp = (SELECT
                       MAX(rev_timestamp)
                     FROM revision AS last 
                     WHERE last.rev_page = pagetmp.page_id)
WHERE NOT EXISTS (SELECT 1 FROM templatelinks JOIN linktarget on tl_target_id = lt_id WHERE tl_from = page_id AND lt_namespace = 10
AND ( lt_title = '분류_필요' )
)
;
