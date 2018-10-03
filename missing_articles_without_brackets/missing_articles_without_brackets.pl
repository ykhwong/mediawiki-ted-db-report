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

동음이의 성격의 괄호가 포함된 문서가 존재하지만 동음이의를 뒷받침해줄 문서가 존재하지 않습니다. 넘겨주기, 동음이의어 문서, 또는 일반적인 백과사전 내용의 문서로 생성해야 합니다.

{| class="wikitable sortable plainlinks" style="width:100%%; margin:auto;"
|- style="white-space:nowrap;"
! 순번
! 괄호가 포함된 문서
! 생성이 필요한 문서
|-
%s
|}
';

my $conn = DBI->connect("DBI:mysql:database=$dbname;host=$host;mysql_read_default_file=$default_file");
my $cursor = $conn->prepare(q"
SELECT title, title2
FROM
(
SELECT
        page_title AS title,
        REGEXP_REPLACE(page_title, '_\\\\(.+\\\\)$', '') AS title2
FROM page
WHERE page_namespace = 0
AND page_is_redirect = 0
AND page_title REGEXP '_\\\\(.+\\\\)$'
) AS t
WHERE NOT EXISTS (SELECT 1 FROM page WHERE page_title = t.title2)
;
");
$cursor->execute();

my $i = 1;
my @output = ();
while (my $row = $cursor->fetchrow_hashref()) {
	my $page_title = sprintf("[[:%s]] || [[:%s]]", $row->{'title'}, $row->{'title2'});
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

