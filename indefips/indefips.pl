use strict;
use warnings;
use utf8;
use Encode qw(decode);
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
차단 이유에 "(proxy|Proxy|VPN|토르|Tor|^tor|프록시)"가 포함되지 않은, 무기한 차단된 IP 목록입니다.

마지막 갱신: <onlyinclude>%s</onlyinclude>

{| class="wikitable sortable plainlinks" style="width:100%%; margin:auto;"
|- style="white-space:nowrap;"
! 순번
! IP
! 차단한 관리자
! 타임스탬프
! 차단 이유
! 부분 차단 여부
|-
%s
|}
';

my $conn = DBI->connect("DBI:MariaDB:database=$dbname;host=$host;mariadb_read_default_file=$default_file", undef, undef, { RaiseError => 1, PrintError => 0 });
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
LEFT JOIN comment_block
ON bl_reason_id = comment_id
LEFT JOIN actor
ON bl_by_actor = actor_id
WHERE bl_expiry = \'infinity\'
AND bt_user IS NULL
AND bt_address IS NOT NULL
AND NOT COALESCE(comment_text, \'\') REGEXP \'(proxy|Proxy|VPN|토르|Tor|^tor|프록시)\'
ORDER BY bl_timestamp, bt_address;
');
$cursor->execute();

# 이 파일은 use utf8 이므로, DB에서 바이트열(varbinary/blob)로 받은 값은 decode 해야 출력 시 깨지지 않음
sub to_text {
	my $s = shift;
	return '' unless defined $s;
	return utf8::is_utf8($s) ? $s : decode('UTF-8', $s);
}

my $i = 1;
my @output = ();
while (my $row = $cursor->fetchrow_hashref()) {
	my $address = to_text($row->{'bt_address'});
	my $ip = sprintf("[[사용자토론:%s|%s]]", $address, $address);
	my $actor = to_text($row->{'actor_name'});
	my $timestamp = $row->{'bl_timestamp'};
	my $comment = to_text($row->{'comment_text'});
	my $sitewide = $row->{'bl_sitewide'};
	if ($sitewide =~ /1/) {
		$sitewide = "아니오";
	} else {
		$sitewide = "예";
	}
	my $table_row = sprintf("| %d || %s || %s || %s || %s || %s\n|-", $i, $ip, $actor, $timestamp, $comment, $sitewide);
	push @output, $table_row;
	$i++;
}

setlocale(LC_TIME, $^O eq 'MSWin32' ? "Korean_Korea.utf8" : "ko_KR.utf8");
$ENV{TZ} = $timezone_area;
my $current_of = localtime->strftime($timezone_str);;
$current_of = decode('UTF-8', $current_of);
my $final_result = sprintf($report_template, $current_of, join("\n", @output));

$cursor->finish();
$conn->disconnect();

binmode(STDOUT, ':encoding(UTF-8)');
printf("%s", $final_result);
