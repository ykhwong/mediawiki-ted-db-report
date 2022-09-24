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

문서 제목에서 연도 식별자만 있는 일반 문서를 나열합니다. (목록 문서 제외)

총 문서 수: %d

{| class="wikitable sortable plainlinks" style="width:100%%; margin:auto;"
|- style="white-space:nowrap;"
! 문서
|-
%s
|}
';

my $conn = DBI->connect("DBI:mysql:database=$dbname;host=$host;mysql_read_default_file=$default_file");
my $cursor = $conn->prepare(q"
SELECT
        page_title
FROM page
WHERE page_namespace = 0 AND page_is_redirect = 0
AND page_title REGEXP '_\\\\([0-9]+년\\\\)$'
AND page_title NOT REGEXP '_목록_'
ORDER BY page_title ASC
;
");
$cursor->execute();

my @output = ();
my $cnt = 0;
while (my $row = $cursor->fetchrow_hashref()) {
	my $page_title = sprintf("[[:%s]]", $row->{'page_title'});
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
