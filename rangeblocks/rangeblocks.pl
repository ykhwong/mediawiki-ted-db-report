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
! IP
! 차단한 관리자
! 타임스탬프
! 만기일
! 차단 이유
! 부분 차단 여부
|-
%s
|}
';

my $conn = DBI->connect("DBI:mysql:database=$dbname;host=$host;mysql_read_default_file=$default_file");
my $cursor = $conn->prepare('
SELECT DISTINCT
  bt_address,
  actor_name,
  bl_timestamp,
  bl_expiry,
  comment_text,
  bl_sitewide
FROM block
JOIN block_target
ON bl_target = bt_id
JOIN comment
ON bl_reason_id = comment_id
JOIN actor
ON bl_by_actor = actor_id
WHERE bt_user IS NULL AND bt_address REGEXP "\/"
');
$cursor->execute();

my $i = 1;
my @output = ();
while (my $row = $cursor->fetchrow_hashref()) {
	my $ip = sprintf("[[사용자토론:%s|%s]]", $row->{'bt_address'}, $row->{'bt_address'});
	my $actor = $row->{'actor_name'};
	my $timestamp = $row->{'bl_timestamp'};
	my $expiry = $row->{'bl_expiry'};
	my $comment = $row->{'comment_text'};
	my $sitewide = $row->{'bl_sitewide'};
	if ($sitewide =~ /1/) {
		$sitewide = "아니오";
	} else {
		$sitewide = "예";
	}
	my $table_row = sprintf("| %d || %s || %s || %s || %s || %s \n|| %s\n|-", $i, $ip, $actor, $timestamp, $expiry, $comment, $sitewide);
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
