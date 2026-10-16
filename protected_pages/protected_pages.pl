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

my @main_titles_with_redirect;
my @draft_titles_with_redirect;

# Strings
my $timezone_str = '%Y년 %-m월 %-d일 (%a) %H:%M (KST)';
my $timezone_area = 'Asia/Seoul';
my $report_template = '
마지막 갱신: <onlyinclude>%s</onlyinclude>

보호된 모든 문서를 나열합니다.

{| class="wikitable sortable plainlinks" style="width:100%%; margin:auto;"
|- style="white-space:nowrap;"
! 순번
! 문서 제목
! 보호 단계
! 기한
|-
%s
|}
';

my $conn = DBI->connect("DBI:MariaDB:database=$dbname;host=$host;mariadb_read_default_file=$default_file", undef, undef, { RaiseError => 1, PrintError => 0 });
my $cursor = $conn->prepare("
SELECT
  page_namespace,
  page_is_redirect,
  page_title,
  pr_level,
  pr_expiry
FROM page_restrictions
JOIN page
ON page_id = pr_page
  WHERE pr_type = 'edit'
  AND (pr_expiry = 'infinity' OR pr_expiry > DATE_FORMAT(UTC_TIMESTAMP(), '%Y%m%d%H%i%s'))
ORDER BY page_namespace, pr_expiry, page_title;
");
$cursor->execute();

my $i = 1;
my @output = ();
while (my $row = $cursor->fetchrow_hashref()) {
	my $ns = $row->{'page_namespace'};
	my $title = $row->{'page_title'};
	my $redirect  = $row->{'page_is_redirect'};
	my $pr_level  = $row->{'pr_level'};
	my $pr_expiry  = $row->{'pr_expiry'};
	my $page_title;
	$page_title = "[[:";
	if ($ns eq 1) { $page_title .= "토론:"; }
	elsif ($ns eq 2) { $page_title .= "사용자:"; }
	elsif ($ns eq 3) { $page_title .= "사용자토론:"; }
	elsif ($ns eq 4) { $page_title .= "위키백과:"; }
	elsif ($ns eq 5) { $page_title .= "위키백과토론:"; }
	elsif ($ns eq 6) { $page_title .= "파일:"; }
	elsif ($ns eq 7) { $page_title .= "파일토론:"; }
	elsif ($ns eq 8) { $page_title .= "미디어위키:"; }
	elsif ($ns eq 9) { $page_title .= "미디어위키토론:"; }
	elsif ($ns eq 10) { $page_title .= "틀:"; }
	elsif ($ns eq 11) { $page_title .= "틀토론:"; }
	elsif ($ns eq 12) { $page_title .= "도움말:"; }
	elsif ($ns eq 13) { $page_title .= "도움말토론:"; }
	elsif ($ns eq 14) { $page_title .= "분류:"; }
	elsif ($ns eq 15) { $page_title .= "분류토론:"; }
	elsif ($ns eq 100) { $page_title .= "포털:"; }
	elsif ($ns eq 101) { $page_title .= "포털토론:"; }
	elsif ($ns eq 102) { $page_title .= "위키프로젝트:"; }
	elsif ($ns eq 103) { $page_title .= "위키프로젝트토론:"; }
	elsif ($ns eq 118) { $page_title .= "초안:"; }
	elsif ($ns eq 119) { $page_title .= "초안토론:"; }
	elsif ($ns eq 710) { $page_title .= "TimedText:"; }
	elsif ($ns eq 711) { $page_title .= "TimedText talk:"; }
	elsif ($ns eq 828) { $page_title .= "모듈:"; }
	elsif ($ns eq 829) { $page_title .= "모듈토론:"; }

	$page_title .= $title . "]]";
	if ( $redirect eq 1 ) {
		$page_title .= ' <span style="background-color: #91ebff;">넘겨주기</span>';
	}

	#my $page_title = sprintf("[[:%s]] || [[초안:%s]]", $draft_page, $draft_page);
	my $table_row = sprintf("| %d || %s || %s || %s\n|-", $i, $page_title, $pr_level, $pr_expiry);
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
