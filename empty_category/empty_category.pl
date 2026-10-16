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

{| class="wikitable sortable plainlinks" style="width:100%%; margin:auto;"
|- style="white-space:nowrap;"
! 순번
! 문서 이름
! 크기
|-
%s
|}
';

my $conn = DBI->connect("DBI:MariaDB:database=$dbname;host=$host;mariadb_read_default_file=$default_file", undef, undef, { RaiseError => 1, PrintError => 0 });
# categorylinks.cl_to는 MediaWiki 1.45에서 제거됨 -> cl_target_id + linktarget 사용
# DBD::MariaDB는 SQL 문을 문자열(Unicode)로 받으므로 한국어 리터럴은 decode 후 전달
my $cursor = $conn->prepare(decode('UTF-8', "
SELECT
  page_title,
  page_len
FROM page
WHERE page_namespace = 14
AND page_is_redirect = 0
AND NOT EXISTS (SELECT
                  1
                FROM categorylinks
                JOIN linktarget ON cl_target_id = lt_id
                WHERE lt_namespace = 14
                AND lt_title = page_title)
AND NOT EXISTS (SELECT
                  1
                FROM categorylinks
                JOIN linktarget ON cl_target_id = lt_id
                WHERE cl_from = page_id
                AND lt_namespace = 14
                AND lt_title IN ('위키백과_분류_넘겨주기', '숨은_분류', '동음이의어_분류'))
AND NOT EXISTS (SELECT
                  1
                FROM templatelinks
                JOIN linktarget ON tl_target_id = lt_id
                WHERE tl_from = page_id
                AND lt_namespace = 10
                AND lt_title IN ('추적용_분류', '빈_분류'))
ORDER BY page_title;
"));
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
