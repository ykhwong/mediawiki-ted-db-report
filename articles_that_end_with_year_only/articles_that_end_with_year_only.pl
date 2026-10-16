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

문서 제목에서 연도 식별자만 있는 일반 문서를 나열합니다. (목록 문서 제외)

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
# DBD::MariaDB는 SQL 문을 문자열(Unicode)로 받으므로 한국어 리터럴은 decode 후 전달
my $cursor = $conn->prepare(decode('UTF-8', q"
SELECT
        page_title
FROM page
WHERE page_namespace = 0 AND page_is_redirect = 0
AND page_title REGEXP '_\\\\([0-9]+년\\\\)$'
AND page_title NOT REGEXP '(^|_)목록_'
ORDER BY page_title ASC
;
"));
$cursor->execute();

my @output = ();
my $cnt = 0;
while (my $row = $cursor->fetchrow_hashref()) {
	my $p_title = $row->{'page_title'};
	my $p_title2 = $p_title;
	$p_title2 =~ s/_\([0-9]+년\)$//;
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
