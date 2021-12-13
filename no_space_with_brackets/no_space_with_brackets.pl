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

문서 제목에서 괄호가 포함된 문서 중 괄호 앞에 공백이 없는 문서를 나열합니다.

; 주의사항 (필독)
* "동음이의 구별을 목적으로" 괄호를 사용한 문서의 경우 <b>반드시 괄호 앞에 공백이 있어야 합니다</b>.
** 이는 검색 등에 있어 미디어위키 시스템의 제약으로 인한 것으로, 한국어 문법과는 무관합니다.
** 한국어, 중국어, 일본어 위키백과에서는 이 제약으로 인해 모두 괄호 앞에 띄어쓰기를 사용합니다.
* 예외: "동음이의 구별을 위해서가 아닌" 고유한 명사의 경우 괄호 앞에 띄어쓰기가 없으면 <b>괄호 앞에 공백이 없는 채로 그대로 유지합니다</b>.
** 음반 제목, 사람을 포함한 유무형 문화재, 종교 단체 등의 제목에는 동음이의 구별과 관계 없이 괄호 앞 띄어쓰기가 없는 제목을 사용하는 경우가 있습니다. 이러한 문서들은 <b>제목을 이동하거나 삭제하거나 삭제를 신청하지 말아주십시오</b>.
* 아래 목록에서 제외되는 항목: 제목에 (주)가 포함된 문서

총 문서 수: %d

{| class="wikitable sortable plainlinks" style="width:100%%; margin:auto;"
|- style="white-space:nowrap;"
! 문서
! 넘겨주기 여부
|-
%s
|}
';

my $conn = DBI->connect("DBI:mysql:database=$dbname;host=$host;mysql_read_default_file=$default_file");
my $cursor = $conn->prepare(q"
SELECT
        page_title,
	page_is_redirect
FROM page
WHERE page_namespace = 0
AND page_title REGEXP '[^_]\\\\(.+\\\\)$'
AND page_title NOT REGEXP '_\\\\('
AND page_title NOT REGEXP '\\\\(주\\\\)$'
;
");
$cursor->execute();

my @output = ();
my $cnt = 0;
while (my $row = $cursor->fetchrow_hashref()) {
	my $page_title = sprintf("[[:%s]] || %s", $row->{'page_title'}, $row->{'page_is_redirect'} ? "넘겨주기" : "");
	my $table_row = sprintf("| %s\n|-", $page_title);
	$cnt++;
	push @output, $table_row;
}

setlocale(LC_TIME, $^O eq 'MSWin32' ? "Korean_Korea.utf8" : "ko_KR.utf8");
$ENV{TZ} = $timezone_area;
my $current_of = localtime->strftime($timezone_str);;
my $final_result = sprintf($report_template, $current_of, $cnt, join("\n", @output));

$cursor->finish();
$conn->disconnect();

printf("%s", $final_result);
