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

동음이의 성격의 괄호가 포함된 문서로 넘겨주고 있는 문서 중 넘겨주기가 적절한지 확인이 필요한 문서를 나열합니다.

# 넘겨주기 목적지 문서를 넘겨주기 출발지 문서로 이동해 주시거나
# 넘겨주기 출발지 문서의 넘겨주기를 끊고 동음이의 문서로 만드는 것을 고려해 주십시오.

그러나 노래, 음반 등의 작품 문서의 경우는 확인 대상에서 제외될 수 있습니다.

{| class="wikitable sortable plainlinks" style="width:100%%; margin:auto;"
|- style="white-space:nowrap;"
! 순번
! 넘겨주기 출발지
! 넘겨주기 목적지
|-
%s
|}
';

my $conn = DBI->connect("DBI:mysql:database=$dbname;host=$host;mysql_read_default_file=$default_file");
my $cursor = $conn->prepare(q"
SELECT DISTINCT target_title FROM (
	SELECT DISTINCT
	  page_title as target_title,
          REGEXP_REPLACE(page_title, '_\\\\(.*\\\\)$', '') as source_title
	FROM page
	WHERE page_namespace = 0
	      AND page_is_redirect = 0
	      AND page_title REGEXP '_\\\\(.*\\\\)$'
) AS t
WHERE EXISTS 
      (SELECT 1 FROM page JOIN redirect ON rd_from = page_id WHERE page_title = t.source_title AND page_is_redirect = 1
       AND rd_namespace = 0 AND rd_title = t.target_title
	)
;
");
$cursor->execute();

my $i = 1;
my @output = ();
while (my $row = $cursor->fetchrow_hashref()) {
	my $src_page = $row->{'target_title'};
	my $target_page = $src_page;
	$src_page =~ s/(_| )\(.*//;
	my $page_title = sprintf("[[:%s]] || [[:%s]]", $src_page, $target_page);
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
