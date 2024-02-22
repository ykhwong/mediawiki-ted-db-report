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

다음은 영어 위키백과 링크가 연결된 짧은 일반 문서를 내용이 작은 항목부터 순차적으로 나열합니다. 영어 위키백과 링크는 넘겨주기일 수 있습니다. 동음이의어 및 색인 모음 문서는 제외합니다.

마지막 갱신: <onlyinclude>%s</onlyinclude>

{| class="wikitable sortable plainlinks" style="width:100%%; margin:auto;"
|- style="white-space:nowrap;"
! 순번
! 문서 이름
! 문서 크기
! 영어 문서
! 최초 작성자
|-
%s
|}
';

my $conn = DBI->connect("DBI:mysql:database=$dbname;host=$host;mysql_read_default_file=$default_file");
my $cursor = $conn->prepare("
select DISTINCT(p.page_title) as page_title, p.page_len as page_len, l1.ll_title as ll_title, actor_name
from page p, langlinks l1, revision
JOIN actor ON rev_actor = actor_id
where
p.page_id = rev_page and
rev_parent_id = '0' and
p.page_namespace = 0 and p.page_is_redirect = 0 and
p.page_id = l1.ll_from
and l1.ll_lang='en'
and exists (select 1 from langlinks l2 where l1.ll_from=l2.ll_from and l2.ll_lang='en')
and not exists (select 1 from categorylinks where cl_from = p.page_id and CL_TO REGEXP '^(삭제_신청_문서|위키백과_넘나들기|식별자_넘겨주기|모든_동음이의어_문서|모든_색인_모음_문서)\$')
AND p.page_len < 1000
ORDER BY page_len ASC
limit 5000;
");
$cursor->execute();

my $i = 1;
my @output = ();
while (my $row = $cursor->fetchrow_hashref()) {
	my $page_title = sprintf("[[%s]]", $row->{'page_title'});
	my $page_len = sprintf("%s", $row->{'page_len'});
	my $ll_title = sprintf("[[:en:%s|%s]]", $row->{'ll_title'}, $row->{'ll_title'});
	my $actor_name = sprintf("[[:사용자:%s|%s]]", $row->{'actor_name'}, $row->{'actor_name'});
	my $table_row = sprintf("| %d|| %s|| %s|| %s|| %s\n|-", $i, $page_title, $page_len, $ll_title, $actor_name);
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
