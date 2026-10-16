use strict;
use warnings;
use Time::Piece;
use POSIX qw(tzset);
use POSIX qw(locale_h);
use locale;
use DBI;
use Encode qw(decode);
use User::pwent;

my $host='kowiki.analytics.db.svc.eqiad.wmflabs';
my $dbname='kowiki_p';
my $default_file=getpwuid($<)->dir . "/replica.my.cnf";

# Strings
my $timezone_str = '%Y년 %-m월 %-d일 (%a) %H:%M (KST)';
my $timezone_area = 'Asia/Seoul';
my $report_template = '
마지막 갱신: <onlyinclude>%s</onlyinclude>

문서 제목에 식별자가 있으나 가리키는 글이 없는 일반 문서를 나열합니다.

총 문서 수: %d

{| class="wikitable sortable plainlinks" style="width:100%%; margin:auto;"
|- style="white-space:nowrap;"
! 문서
! 식별자 제외 제목
|-
%s
|}
';

my $conn = DBI->connect("DBI:MariaDB:database=$dbname;host=$host;mariadb_read_default_file=$default_file", undef, undef, { RaiseError => 1, PrintError => 0 });
# - categorylinks.cl_to는 MediaWiki 1.45에서 제거됨 -> cl_target_id + linktarget 사용
# - 제외 분류는 NOT EXISTS로 검사해야 함 (JOIN 후 행 단위로 거르면 다른 분류 행 때문에 제외되지 않음)
# - DBD::MariaDB는 SQL 문을 문자열(Unicode)로 받으므로 한국어 리터럴은 decode 후 전달
my $cursor = $conn->prepare(decode('UTF-8', q"
SELECT page_title FROM page
WHERE page_namespace = 0
AND page_is_redirect = 0
AND page_title REGEXP '_\\\\(.*\\\\)$'
AND NOT EXISTS
  (SELECT 1 FROM linktarget JOIN pagelinks ON lt_id = pl_target_id
   WHERE pl_from_namespace = 0 AND lt_namespace = 0 AND lt_title = page_title)
AND NOT EXISTS
  (SELECT 1 FROM categorylinks JOIN linktarget ON cl_target_id = lt_id
   WHERE cl_from = page_id AND lt_namespace = 14
   AND lt_title IN ('삭제_신청_문서', '위키백과_넘나들기', '식별자_넘겨주기'))
ORDER BY page_title
;
"));
$cursor->execute();

my @output = ();
my $cnt = 0;
while (my $row = $cursor->fetchrow_hashref()) {
	my $p_title = $row->{'page_title'};
	my $p_title2 = $p_title;
	$p_title2 =~ s/_\(.*//;
	my $page_title = sprintf("[[:%s]] || [[:%s]]", $p_title, $p_title2);
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
