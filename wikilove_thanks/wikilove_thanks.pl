use strict;
use warnings;
use Time::Piece;
use POSIX qw(tzset);
use POSIX qw(locale_h);
use locale;
use DBI;

my $host='kowiki.analytics.db.svc.eqiad.wmflabs';
my $dbname='kowiki_p';
my $default_file='~/replica.my.cnf';

# Strings
my $timezone_str = '%Y�� %-m�� %-d�� (%a) %H:%M (KST)';
my $timezone_area = 'Asia/Seoul';
my $report_template = '
������ ����: <onlyinclude>%s</onlyinclude>

== ��Ű����� ���� ���� ��� ==
{| class="wikitable sortable plainlinks" style="width:100%%; margin:auto;"
|- style="white-space:nowrap;"
! ����
! �����
! Ƚ��
|-
%s
|}
';

my $report_template2 = '
== ��Ű����� ���� ���� ��� ==
{| class="wikitable sortable plainlinks" style="width:100%%; margin:auto;"
|- style="white-space:nowrap;"
! ����
! �����
! Ƚ��
|-
%s
|}
';

my $report_template3 = '
== ����(����)�� ���� ǥ�� ��� ==
{| class="wikitable sortable plainlinks" style="width:100%%; margin:auto;"
|- style="white-space:nowrap;"
! ����
! �����
! Ƚ��
|-
%s
|}
';

my $report_template4 = '
== ����(����)�� ���� ���� ��� ==
{| class="wikitable sortable plainlinks" style="width:100%%; margin:auto;"
|- style="white-space:nowrap;"
! ����
! �����
! Ƚ��
|-
%s
|}
';



my $conn = DBI->connect("DBI:mysql:database=$dbname;host=$host;mysql_read_default_file=$default_file");
my $cursor = $conn->prepare("
SELECT
    user_name,
    count(user_name) AS counts
    FROM wikilove_log, user
    WHERE wll_sender = user_id
    AND NOT EXISTS (SELECT 1 from ipblocks WHERE ipb_address = user_name)
    GROUP BY wll_sender
    ORDER BY counts DESC
    LIMIT 50;
");
$cursor->execute();

my $i = 1;
my @output = ();
while (my $row = $cursor->fetchrow_hashref()) {
	my $page_title = sprintf("[[�����:%s|%s]] || %d", $row->{'user_name'}, $row->{'user_name'}, $row->{'counts'});
	my $table_row = sprintf("| %d\n| %s\n|-", $i, $page_title);
	push @output, $table_row;
	$i++;
}

$cursor = $conn->prepare("
SELECT
    user_name,
    count(user_name) AS counts
    FROM wikilove_log, user
    WHERE wll_receiver = user_id
    AND NOT EXISTS (SELECT 1 from ipblocks WHERE ipb_address = user_name)
    GROUP BY wll_receiver
    ORDER BY counts DESC
    LIMIT 50;
");
$cursor->execute();

$i = 1;
my @output2 = ();
while (my $row = $cursor->fetchrow_hashref()) {
	my $page_title = sprintf("[[�����:%s|%s]] || %d", $row->{'user_name'}, $row->{'user_name'}, $row->{'counts'});
	my $table_row = sprintf("| %d\n| %s\n|-", $i, $page_title);
	push @output2, $table_row;
	$i++;
}

$cursor = $conn->prepare("
select user.user_name as user_name, count(user_name) as counts
from logging
join user on log_actor = user.user_id
where log_type = 'thanks'
AND NOT EXISTS (SELECT 1 from ipblocks WHERE ipb_address = user_name)
group by user_name
order by counts DESC
LIMIT 100;
");
$cursor->execute();

$i = 1;
my @output3 = ();
while (my $row = $cursor->fetchrow_hashref()) {
	my $page_title = sprintf("[[�����:%s|%s]] || %d", $row->{'user_name'}, $row->{'user_name'}, $row->{'counts'});
	my $table_row = sprintf("| %d\n| %s\n|-", $i, $page_title);
	push @output3, $table_row;
	$i++;
}

$cursor = $conn->prepare("
select log_title as user_name, count(log_title) as counts
from logging
where log_type = 'thanks'
group by user_name
order by counts DESC
LIMIT 100;
");
$cursor->execute();

$i = 1;
my @output4 = ();
while (my $row = $cursor->fetchrow_hashref()) {
	my $page_title = sprintf("[[�����:%s|%s]] || %d", $row->{'user_name'}, $row->{'user_name'}, $row->{'counts'});
	my $table_row = sprintf("| %d\n| %s\n|-", $i, $page_title);
	push @output4, $table_row;
	$i++;
}



setlocale(LC_TIME, $^O eq 'MSWin32' ? "Korean_Korea.utf8" : "ko_KR.utf8");
$ENV{TZ} = $timezone_area;
my $current_of = localtime->strftime($timezone_str);;
my $final_result = sprintf($report_template, $current_of, join("\n", @output)) . sprintf($report_template2, join("\n", @output2)) .
		   sprintf($report_template3, join("\n", @output3)) . sprintf($report_template4, join("\n", @output4));

$cursor->finish();
$conn->disconnect();

printf("%s", $final_result);
