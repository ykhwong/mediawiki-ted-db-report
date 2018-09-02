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
timezone_str = '%Y년 %m월 %d일 (%a) %H:%M (KST)'
timezone_area = 'Asia/Seoul'
report_template = '''
마지막 갱신: <onlyinclude>%s</onlyinclude>.

{| class="wikitable sortable" 
!이름공간 ID
!이름공간
!전체 문서 수
!넘겨주기가 아닌 문서
!넘겨주기 문서
|-
%s
|}
'''

namespace = {
    0: "일반",
    1: "토론",
    2: "사용자",
    3: "사용자토론",
    4: "위키백과",
    5: "위키백과토론",
    6: "파일",
    7: "파일토론",
    8: "미디어위키",
    9: "미디어위키토론",
    10: "틀",
    11: "틀토론",
    12: "도움말",
    13: "도움말토론",
    14: "분류",
    15: "분류토론",
    100: "포털",
    101: "포털토론",
    102: "위키프로젝트",
    103: "위키프로젝트토론",
    118: "초안",
    119: "초안토론",
    828: "모듈",
    829: "모듈토론"
}

conn = MySQLdb.connect(host=host, db=dbname, read_default_file=default_file)
cursor = conn.cursor()
cursor.execute('''
SELECT
  page_namespace,
  MAX(notredir) as notredir,
  MAX(redir) as redir
FROM (
  SELECT page.page_namespace,
         IF( page_is_redirect, COUNT(page.page_namespace), 0 ) AS redir,
         IF( page_is_redirect, 0, COUNT(page.page_namespace)) AS notredir
  FROM page
  GROUP BY page_is_redirect, page_namespace
  ORDER BY page_namespace, page_is_redirect
) AS pagetmp
GROUP BY page_namespace;
''')

output = []
for row in cursor.fetchall():
    page_title = '%s || %s || %s || %s || %s ' % ( str(row[0]), namespace[row[0]], str(row[1] + row[2]), str(row[1]), str(row[2]))
    table_row = '''| %s
|-''' % page_title
    output.append(table_row)

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
