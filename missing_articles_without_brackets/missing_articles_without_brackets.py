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
마지막 갱신: <onlyinclude>%s</onlyinclude>

동음이의 성격의 괄호가 포함된 문서가 존재하지만 동음이의를 뒷받침해줄 문서가 존재하지 않습니다. 넘겨주기, 동음이의어 문서, 또는 일반적인 백과사전 내용의 문서로 생성>해야 합니다.

{| class="wikitable sortable plainlinks" style="width:100%%; margin:auto;"
|- style="white-space:nowrap;"
! 순번
! 괄호가 포함된 문서
! 생성이 필요한 문서
|-
%s
|}
'''

conn = MySQLdb.connect(host=host, db=dbname, read_default_file=default_file)
cursor = conn.cursor()
cursor.execute(r'''
SELECT title, title2
FROM
(
SELECT
        page_title AS title,
        REGEXP_REPLACE(page_title, '_\\(.+\\)$', '') AS title2
FROM page
WHERE page_namespace = 0
AND page_is_redirect = 0
AND page_title REGEXP '_\\(.+\\)$'
) AS t
WHERE NOT EXISTS (SELECT 1 FROM page WHERE page_title = t.title2)
;
''')

i = 1
output = []
for row in cursor.fetchall():
    page_title = '[[:%s]] || [[:%s]]' % (unicode(row[0], 'utf-8'), unicode(row[1], 'utf-8'))
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

