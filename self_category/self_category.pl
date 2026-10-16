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
! 분류 이름
! 포함하는 페이지 수
! 하위 분류 수
|-
%s
|}
';

my $conn = DBI->connect("DBI:MariaDB:database=$dbname;host=$host;mariadb_read_default_file=$default_file", undef, undef, { RaiseError => 1, PrintError => 0 });
# categorylinks.cl_to는 MediaWiki 1.45에서 제거됨 -> cl_target_id + linktarget 사용
my $cursor = $conn->prepare("
SELECT
  page_title,
  COALESCE(cat_pages, 0) AS cat_pages,
  COALESCE(cat_subcats, 0) AS cat_subcats
FROM page
JOIN categorylinks
ON cl_from = page_id
JOIN linktarget
ON cl_target_id = lt_id
LEFT JOIN category
ON cat_title = page_title
WHERE page_namespace = 14
AND lt_namespace = 14
AND lt_title = page_title
ORDER BY page_title;
");
$cursor->execute();

my $i = 1;
my @output = ();
while (my $row = $cursor->fetchrow_hashref()) {
	my $page_title = sprintf("[[:분류:%s]] || %s || %s", $row->{'page_title'}, $row->{'cat_pages'}, $row->{'cat_subcats'});
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
