SELECT title, page_title2 FROM (
SELECT
page_title AS title,
REGEXP_REPLACE(page_title, '_\\(.*\\)$', '') AS page_title2
FROM (
SELECT
page_title
from page
WHERE page_namespace = 0
and page_is_redirect = 0
and page_title REGEXP '_\\(.*\\)$'
) AS tt
) AS tt2
WHERE NOT EXISTS (select 1 FROM page WHERE page_namespace = 0 and page_title = tt2.page_title2);

