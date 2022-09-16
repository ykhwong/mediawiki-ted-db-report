use strict;
use warnings;
use Time::Piece;
use POSIX qw(tzset);
use POSIX qw(locale_h);
use locale;
use DBI;
use User::pwent;

my $host='kowiki.analytics.db.svc.eqiad.wmflabs';
my $dbname='kowiki_p';
my $default_file=getpwuid($<)->dir . "/replica.my.cnf";

# Strings
my $timezone_str = '%Y년 %-m월 %-d일 (%a) %H:%M (KST)';
my $timezone_area = 'Asia/Seoul';
my $report_template = '
마지막 갱신: <onlyinclude>%s</onlyinclude>

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
  page_title,
  page_len
FROM categorylinks
RIGHT JOIN page ON cl_to = page_title
WHERE page_namespace = 14
AND page_is_redirect = 0
AND cl_to IS NULL
AND NOT EXISTS (SELECT
                  1
                FROM categorylinks
                WHERE cl_from = page_id
                AND cl_to = '위키백과_분류_넘겨주기')
AND NOT EXISTS (SELECT
                  1
                FROM categorylinks
                WHERE cl_from = page_id
                AND cl_to = '숨은_분류')
AND NOT EXISTS (SELECT
                  1
                FROM categorylinks
                WHERE cl_from = page_id
                AND cl_to = '동음이의어_분류')
AND NOT EXISTS (SELECT
                  1
                FROM templatelinks
                JOIN linktarget on tl_target_id = lt_id
                WHERE tl_from = page_id
                AND lt_namespace = 10
                AND lt_title = '추적용_분류')
AND NOT EXISTS (SELECT
                  1
                FROM templatelinks
                JOIN linktarget on tl_target_id = lt_id
                WHERE tl_from = page_id
                AND lt_namespace = 10
                AND lt_title = '빈_분류');
");
$cursor->execute();

my $i = 1;
my @output = ();
while (my $row = $cursor->fetchrow_hashref()) {
	my $page_title = sprintf("[[:분류:%s]] || %s", $row->{'page_title'}, $row->{'page_len'});
	my $table_row = sprintf("| %d\n| %s\n|-", $i, $page_title);
	push @output, $table_row;
	$i++;
}

setlocale(LC_TIME, $^O eq 'MSWin32' ? "Korean_Korea.utf8" : "ko_KR.utf8");
$ENV{TZ} = $timezone_area;
my $current_of = localtime->strftime($timezone_str);;
my $final_result = sprintf($report_template, $current_of, join("\n", @output));

$cursor->finish();
$conn->disconnect();

printf("%s", $final_result);
