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
my $timezone_str = '%Y년 %-m월 %-d일 (%a) %H:%M (KST)';
my $timezone_area = 'Asia/Seoul';
my $report_template = '
마지막 갱신: <onlyinclude>%s</onlyinclude>

일반 문서와 제목이 중복되는 초안 문서를 나열합니다.

{| class="wikitable sortable plainlinks" style="width:100%%; margin:auto;"
|- style="white-space:nowrap;"
! 순번
! 일반 문서
! 초안 문서
|-
%s
|}
';

my $conn = DBI->connect("DBI:mysql:database=$dbname;host=$host;mysql_read_default_file=$default_file");
my $cursor = $conn->prepare("
SELECT draft_title
FROM
(
SELECT
        distinct(page_title) as draft_title
FROM page
  -- JOIN templatelinks
  -- ON tl_from = page_id
WHERE 
page_namespace = 118
  -- AND NOT tl_title = '삭제_신청'
  -- AND page_is_redirect = 0
) AS t
WHERE EXISTS (
	SELECT 1 FROM page
	WHERE
	page_namespace = 0
	-- AND page_is_redirect = 0
	AND page_title = t.draft_title
);
");
$cursor->execute();

my $i = 1;
my @output = ();
while (my $row = $cursor->fetchrow_hashref()) {
	my $draft_page = $row->{'draft_title'};
	my $page_title = sprintf("[[:%s]] || [[초안:%s]]", $draft_page, $draft_page);
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
