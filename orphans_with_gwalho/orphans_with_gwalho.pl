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

my $conn = DBI->connect("DBI:mysql:database=$dbname;host=$host;mysql_read_default_file=$default_file");
my $cursor = $conn->prepare(q"
SELECT DISTINCT page_title from page
JOIN categorylinks
ON cl_from = page_id
WHERE page_namespace = 0
and page_is_redirect = 0
and page_title REGEXP '_\\\\(.*\\\\)$'
and NOT EXISTS
  (select pl_from from linktarget JOIN pagelinks ON lt_id = pl_target_id where pl_from_namespace = 0 and page_title = lt_title )
and NOT CL_TO REGEXP '^(삭제_신청_문서|위키백과_넘나들기|식별자_넘겨주기)$'
;
");
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
