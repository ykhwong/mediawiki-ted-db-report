# -*- coding: utf-8 -*-
from __future__ import unicode_literals
import datetime
import sys
import locale
from sys import platform
from pytz import timezone
if sys.version_info.major == 2:
    import MySQLdb
else:
    import pymysql as MySQLdb
    sys.stdout = open(sys.stdout.fileno(), mode='w', encoding='utf8', buffering=1)
    def unicode(str1, str2):
      return str1.decode(str2)

host='kowiki.analytics.db.svc.eqiad.wmflabs'
dbname='kowiki_p'
default_file='~/replica.my.cnf'

# Strings
timezone_str = '%Y년 %-m월 %-d일 (%a) %H:%M (KST)'
timezone_area = 'Asia/Seoul'
report_template = '''
마지막 갱신: <onlyinclude>%s</onlyinclude>.

{| class="wikitable sortable plainlinks" style="width:100%%; margin:auto;"
|- style="white-space:nowrap;"
! 순번
! 문서 이름
! 길이
|-
%s
|}
'''

conn = MySQLdb.connect(host=host, db=dbname, read_default_file=default_file)
cursor = conn.cursor()
cursor.execute('''
SELECT
  page_title,
  page_len
FROM page
JOIN categorylinks
ON cl_from = page_id
WHERE page_namespace = 0
AND page_is_redirect = 0
AND cl_to = '살아있는_사람'
ORDER BY page_len ASC
LIMIT 1000;
'''.encode('utf-8'))

i = 1
output = []
for row in cursor.fetchall():
    page_title = '[[%s]] || %s' % (unicode(row[0], 'utf-8'), str(row[1]))
    table_row = '''| %d
| %s
|-''' % (i, page_title)
    output.append(table_row)
    i += 1

if sys.version_info.major == 2:
    locale.setlocale(locale.LC_TIME, 'Korean_Korea.utf8' if platform == "win32" else b'ko_KR.utf8')
    current_of = datetime.datetime.now(timezone(timezone_area)).strftime(timezone_str.encode('utf-8')).decode('utf-8')
    final_result = (report_template % (current_of, '\n'.join(output))).encode('utf-8')
else:
    locale.setlocale(locale.LC_TIME, 'Korean_Korea.utf8' if platform == "win32" else 'ko_KR.utf8')
    current_of = datetime.datetime.now(timezone(timezone_area)).strftime(timezone_str)
    final_result = report_template % (current_of, '\n'.join(output))

cursor.close()
conn.close()

print(final_result)

