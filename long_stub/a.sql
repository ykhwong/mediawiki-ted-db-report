SELECT
  page_title,
  page_len
FROM page
JOIN categorylinks
  ON categorylinks.cl_from = page.page_id
JOIN linktarget
  ON categorylinks.cl_target_id = linktarget.lt_id
WHERE linktarget.lt_title LIKE '%에_관한_토막글'
  AND page_namespace = 0
  AND page_len > 2000
GROUP BY page_title
ORDER BY page_len DESC
LIMIT 1000;
