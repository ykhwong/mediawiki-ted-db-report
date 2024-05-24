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
! 문서 이름
! 그림 링크 수
! 링크 수
|-
%s
|}
';

my $conn = DBI->connect("DBI:mysql:database=$dbname;host=$host;mysql_read_default_file=$default_file");
my $cursor = $conn->prepare("
SELECT page_title,
  (SELECT COUNT(*)
  FROM imagelinks
  WHERE il_to = page_title) AS imagelinks,
  (SELECT COUNT(*)
  FROM linktarget
  JOIN pagelinks ON lt_id = pl_target_id
  WHERE lt_namespace = 6
    AND lt_title = page_title) AS links
FROM page
WHERE page_namespace = 6
  AND page_is_redirect = 1
HAVING imagelinks + links <= 1
");
$cursor->execute();

my $i = 1;
my @output = ();
while (my $row = $cursor->fetchrow_hashref()) {
        my $page_title = sprintf('<span class="plainlinks">[{{fullurl:File:%s|redirect=no}} %s]</span>', $row->{'page_title'}, $row->{'page_title'});
        my $table_row = sprintf("| %d\n| %s\n| %s\n| %s\n|-", $i, $page_title, $row->{'imagelinks'}, $row->{'links'});
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
