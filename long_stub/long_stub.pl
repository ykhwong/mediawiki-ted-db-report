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
! 문서 길이
|-
%s
|}
';
my $conn = DBI->connect("DBI:MariaDB:database=$dbname;host=$host;mariadb_read_default_file=$default_file", undef, undef, { RaiseError => 1, PrintError => 0 });
# - LIKE에서 '_'는 임의의 한 글자를 뜻하므로 '\_'로 이스케이프 (Perl "" 안이므로 '\\_')
# - DBD::MariaDB는 SQL 문을 문자열(Unicode)로 받으므로 한국어 리터럴은 decode 후 전달
my $cursor = $conn->prepare(decode('UTF-8', "
SELECT DISTINCT
  page_title,
  page_len
FROM page
JOIN categorylinks
  ON categorylinks.cl_from = page.page_id
JOIN linktarget
  ON categorylinks.cl_target_id = linktarget.lt_id
WHERE linktarget.lt_namespace = 14
  AND linktarget.lt_title LIKE '%에\\_관한\\_토막글'
  AND page_namespace = 0
  AND page_is_redirect = 0
  AND page_len > 2000
ORDER BY page_len DESC, page_title
LIMIT 1000;
"));
$cursor->execute();

my $i = 1;
my @output = ();
while (my $row = $cursor->fetchrow_hashref()) {
	my $page_title = sprintf("[[%s]] || %s", $row->{'page_title'}, $row->{'page_len'});
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

