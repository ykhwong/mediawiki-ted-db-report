use strict;
use warnings;
use Time::Piece;
use POSIX qw(tzset);
use DBI;
 
my $host='kowiki.analytics.db.svc.eqiad.wmflabs';
my $dbname='kowiki_p';
my $default_file='~/replica.my.cnf';

# Strings
my $timezone_str = '%Y년 %m월 %d일 %H:%M (KST)';
my $timezone_area = 'Asia/Seoul';
my $report_template = '
마지막 갱신: <onlyinclude>%s</onlyinclude>

== 토론 이름공간 ==
{| class="wikitable sortable plainlinks" style="width:100%%; margin:auto;"
|- style="white-space:nowrap;"
! 순번
! 문서 이름
! 크기
|-
%s
|}
';

my $report_template2 = '
== 위키백과토론 이름공간 ==
{| class="wikitable sortable plainlinks" style="width:100%%; margin:auto;"
|- style="white-space:nowrap;"
! 순번
! 문서 이름
! 크기
|-
%s
|}
';

my $conn = DBI->connect("DBI:mysql:database=$dbname;host=$host;mysql_read_default_file=$default_file");
my $cursor = $conn->prepare("
SELECT
        '토론' AS ns_name,
        REPLACE(SUBSTRING_INDEX(page_title, '/', 1), '_', ' ') AS parent,
        SUM(page_len) / 1024 / 1024 AS total_size
FROM page
WHERE page_namespace = 1
GROUP BY page_namespace, parent
ORDER BY total_size DESC
LIMIT 100;
");
$cursor->execute();

my $i = 1;
my @output = ();
while (my $row = $cursor->fetchrow_hashref()) {
	my $page_title = sprintf("[[토론:%s]] || %s", $row->{'parent'}, $row->{'total_size'});
	my $table_row = sprintf("| %d\n| %s\n|-", $i, $page_title);
	push @output, $table_row;
	$i++;
}

$cursor = $conn->prepare("
SELECT
        '위키백과토론' AS ns_name,
        REPLACE(SUBSTRING_INDEX(page_title, '/', 1), '_', ' ') AS parent,
        SUM(page_len) / 1024 / 1024 AS total_size
FROM page
WHERE page_namespace = 5
GROUP BY page_namespace, parent
ORDER BY total_size DESC
LIMIT 100;
");
$cursor->execute();

$i = 1;
my @output2 = ();
while (my $row = $cursor->fetchrow_hashref()) {
	my $page_title = sprintf("[[위키백과토론:%s]] || %s", $row->{'parent'}, $row->{'total_size'});
	my $table_row = sprintf("| %d\n| %s\n|-", $i, $page_title);
	push @output2, $table_row;
	$i++;
}

$ENV{TZ} = $timezone_area;
my $current_of = localtime->strftime($timezone_str);;
my $final_result = sprintf($report_template, $current_of, join("\n", @output)) . sprintf($report_template2, join("\n", @output));

$cursor->finish();
$conn->disconnect();

printf("%s", $final_result);
