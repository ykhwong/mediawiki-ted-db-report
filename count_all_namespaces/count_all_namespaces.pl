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

{| class="wikitable sortable" 
!이름공간 ID
!이름공간
!전체 문서 수
!넘겨주기가 아닌 문서
!넘겨주기 문서
|-
%s
|}
';
my %namespace = (
    0 => "일반",
    1 => "토론",
    2 => "사용자",
    3 => "사용자토론",
    4 => "위키백과",
    5 => "위키백과토론",
    6 => "파일",
    7 => "파일토론",
    8 => "미디어위키",
    9 => "미디어위키토론",
    10 => "틀",
    11 => "틀토론",
    12 => "도움말",
    13 => "도움말토론",
    14 => "분류",
    15 => "분류토론",
    100 => "포털",
    101 => "포털토론",
    102 => "위키프로젝트",
    103 => "위키프로젝트토론",
    118 => "초안",
    119 => "초안토론",
    828 => "모듈",
    829 => "모듈토론"
);


my $conn = DBI->connect("DBI:mysql:database=$dbname;host=$host;mysql_read_default_file=$default_file");
my $cursor = $conn->prepare("
SELECT
  page_namespace,
  MAX(notredir) AS notredir,
  MAX(redir) AS redir
FROM (
  SELECT page.page_namespace,
         IF( page_is_redirect, COUNT(page.page_namespace), 0 ) AS redir,
         IF( page_is_redirect, 0, COUNT(page.page_namespace)) AS notredir
  FROM page
  GROUP BY page_is_redirect, page_namespace
  ORDER BY page_namespace, page_is_redirect
) AS pagetmp
GROUP BY page_namespace;
");
$cursor->execute();

my @output = ();
while (my $row = $cursor->fetchrow_hashref()) {
	my $page_title = sprintf("%s || %s || %s || %s || %s ", $row->{'page_namespace'}, $namespace{$row->{'page_namespace'}}, ($row->{'notredir'} + $row->{'redir'}), $row->{'notredir'}, $row->{'redir'});
	my $table_row = sprintf("| %s\n|-", $page_title);
	push @output, $table_row;
}

setlocale(LC_TIME, $^O eq 'MSWin32' ? "Korean_Korea.utf8" : "ko_KR.utf8");
$ENV{TZ} = $timezone_area;
my $current_of = localtime->strftime($timezone_str);;
my $final_result = sprintf($report_template, $current_of, join("\n", @output));

$cursor->finish();
$conn->disconnect();

printf("%s", $final_result);
