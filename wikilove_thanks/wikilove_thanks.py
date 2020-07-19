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

== 위키사랑을 많이 보낸 사람 ==
{| class="wikitable sortable plainlinks" style="width:100%%; margin:auto;"
|- style="white-space:nowrap;"
! 순번
! 사용자
! 횟수
|-
%s
|}
'''

report_template2 = '''
== 위키사랑을 많이 받은 사람 ==
{| class="wikitable sortable plainlinks" style="width:100%%; margin:auto;"
|- style="white-space:nowrap;"
! 순번
! 사용자
! 횟수
|-
%s
|}
'''

report_template3 = '''
== 감사를 많이 표한 사람 ==
{| class="wikitable sortable plainlinks" style="width:100%%; margin:auto;"
|- style="white-space:nowrap;"
! 순번
! 사용자
! 횟수
|-
%s
|}
'''

report_template4 = '''
== 감사 표현을 많이 받은 사람 ==
{| class="wikitable sortable plainlinks" style="width:100%%; margin:auto;"
|- style="white-space:nowrap;"
! 순번
! 사용자
! 횟수
|-
%s
|}
'''

conn = MySQLdb.connect(host=host, db=dbname, read_default_file=default_file)
cursor = conn.cursor()
cursor.execute('''
SELECT
    user_name,
    count(user_name) AS counts
    FROM wikilove_log, user
    WHERE wll_sender = user_id
    AND NOT EXISTS (SELECT 1 from ipblocks WHERE ipb_address = user_name)
    GROUP BY wll_sender
    ORDER BY counts DESC
    LIMIT 50;
'''.encode('utf-8'))

i = 1
output = []
for row in cursor.fetchall():
    page_title = '[[사용자:%s|%s]] || %s' % (unicode(row[0], 'utf-8'), unicode(row[0], 'utf-8'), str(row[1]))
    table_row = '''| %d
| %s
|-''' % (i, page_title)
    output.append(table_row)
    i += 1

cursor.execute('''
SELECT
    user_name,
    count(user_name) AS counts
    FROM wikilove_log, user
    WHERE wll_receiver = user_id
    AND NOT EXISTS (SELECT 1 from ipblocks WHERE ipb_address = user_name)
    GROUP BY wll_receiver
    ORDER BY counts DESC
    LIMIT 50;
'''.encode('utf-8'))

i = 1
output2 = []
for row in cursor.fetchall():
    page_title = '[[사용자:%s|%s]] || %s' % (unicode(row[0], 'utf-8'), unicode(row[0], 'utf-8'), str(row[1]))
    table_row = '''| %d
| %s
|-''' % (i, page_title)
    output2.append(table_row)
    i += 1

cursor.execute('''
select user.user_name as user_name, count(user_name) as counts
from logging
join user on log_actor = user.user_id
where log_type = 'thanks'
AND NOT EXISTS (SELECT 1 from ipblocks WHERE ipb_address = user_name)
group by user_name
order by counts DESC
LIMIT 100;
'''.encode('utf-8'))

i = 1
output3 = []
for row in cursor.fetchall():
    page_title = '[[사용자:%s|%s]] || %s' % (unicode(row[0], 'utf-8'), unicode(row[0], 'utf-8'), str(row[1]))
    table_row = '''| %d
| %s
|-''' % (i, page_title)
    output3.append(table_row)
    i += 1

cursor.execute('''
select log_title as user_name, count(log_title) as counts
from logging
where log_type = 'thanks'
group by user_name
order by counts DESC
LIMIT 100;
'''.encode('utf-8'))

i = 1
output4 = []
for row in cursor.fetchall():
    page_title = '[[사용자:%s|%s]] || %s' % (unicode(row[0], 'utf-8'), unicode(row[0], 'utf-8'), str(row[1]))
    table_row = '''| %d
| %s
|-''' % (i, page_title)
    output4.append(table_row)
    i += 1



if sys.version_info.major == 2:
    locale.setlocale(locale.LC_TIME, 'Korean_Korea.utf8' if platform == "win32" else b'ko_KR.utf8')
    current_of = datetime.datetime.now(timezone(timezone_area)).strftime(timezone_str.encode('utf-8')).decode('utf-8')
    final_result = (report_template % (current_of, '\n'.join(output)) + report_template2 % '\n'.join(output2) + report_template3 % '\n'.join(output3) + report_template4 % '\n'.join(output4)).encode('utf-8')
else:
    locale.setlocale(locale.LC_TIME, 'Korean_Korea.utf8' if platform == "win32" else 'ko_KR.utf8')
    current_of = datetime.datetime.now(timezone(timezone_area)).strftime(timezone_str)
    final_result = report_template % (current_of, '\n'.join(output)) + report_template2 % '\n'.join(output2) + report_template3 % '\n'.join(output3) + report_template4 % '\n'.join(output4)

cursor.close()
conn.close()

print(final_result)
