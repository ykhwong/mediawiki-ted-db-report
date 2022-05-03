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

; 일반 문서 수의 집계 방식 참고
{| class="wikitable"
|+
|<b>집계 분류</b>
|<b>설명</b>
|<b>비고</b>
|-
|전통적인 미디어위키(위키백과 등) 집계 방식
|[[백:막다른 문서|막다른 문서]], 넘겨주기 문서 수 제외
|[[특:최근바뀜|최근바뀜]], [[백:대문|대문]]에 표시되는 일반 문서 수
|-
|일부 타 위키(나무위키 등)의 집계 방식
|막다른 문서, 넘겨주기 문서 수 포함
|막다른 문서 수와 넘겨주기 문서 수를 별도로 집계하지 않음
|-
|현재 보고 계신 통계의 집계 방식
|막다른 문서, 넘겨주기 문서 수 포함
|전체 문서 수의 일반 이름공간 항목에 해당
|}
※ [[백:막다른 문서|막다른 문서]]: 다른 위키백과 문서로 향하는 내부 링크가 포함되지 않은 문서
-------------------

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
my $total_cnt = 0;
while (my $row = $cursor->fetchrow_hashref()) {
	my $page_title = sprintf("%s || %s || %s || %s || %s ", $row->{'page_namespace'}, $namespace{$row->{'page_namespace'}}, ($row->{'notredir'} + $row->{'redir'}), $row->{'notredir'}, $row->{'redir'});
	my $table_row = sprintf("| %s\n|-", $page_title);
	if ($row->{'page_namespace'} eq 0) {
		$total_cnt = $row->{'notredir'} + $row->{'redir'};
	}
	push @output, $table_row;
}

setlocale(LC_TIME, $^O eq 'MSWin32' ? "Korean_Korea.utf8" : "ko_KR.utf8");
$ENV{TZ} = $timezone_area;
my $current_of = localtime->strftime($timezone_str);;
$current_of = "{{#if:{{{1|}}}|$total_cnt|" . $current_of . "}}";
my $final_result = sprintf($report_template, $current_of, join("\n", @output));

$cursor->finish();
$conn->disconnect();

printf("%s", $final_result);
