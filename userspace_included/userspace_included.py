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
|-
%s
|}
'''

conn = MySQLdb.connect(host=host, db=dbname, read_default_file=default_file)
cursor = conn.cursor()
cursor.execute('''
SELECT DISTINCT
  page_title
FROM page
JOIN pagelinks
ON pl_from = page_id
WHERE page_namespace = 0
AND pl_namespace IN (2,3);
''')

i = 1
output = []
for row in cursor.fetchall():
    page_title = '[[%s]]' % unicode(row[0], 'utf-8')
    table_row = '''| %d
| %s
|-''' % (i, page_title)
    output.append(table_row)
    i += 1

if sys.version_info.major == 2:
    if platform == "win32":
        locale.setlocale(locale.LC_TIME, 'Korean_Korea.utf8')
    else:
        locale.setlocale(locale.LC_TIME, b'ko_KR.utf8')
    timezone_str = timezone_str.encode('utf-8')
    current_of = datetime.datetime.now(timezone(timezone_area)).strftime(timezone_str)
    current_of = current_of.decode('utf-8')
    final_result = report_template % (current_of, '\n'.join(output))
    final_result = final_result.encode('utf-8')
else:
    if platform == "win32":
        locale.setlocale(locale.LC_TIME, 'Korean_Korea.utf8')
    else:
        locale.setlocale(locale.LC_TIME, 'ko_KR.utf8')
    current_of = datetime.datetime.now(timezone(timezone_area)).strftime(timezone_str)
    final_result = report_template % (current_of, '\n'.join(output))

cursor.close()
conn.close()

print(final_result)
