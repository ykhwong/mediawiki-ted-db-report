use strict;
no warnings;
use MediaWiki::Bot;
use Time::Piece;
use POSIX qw(tzset);
use POSIX qw(locale_h);
use Encode qw(decode encode);
#use locale;
use DBI;
use User::pwent;

my $host='kowiki.analytics.db.svc.eqiad.wmflabs';
my $dbname='kowiki_p';
my $default_file='/data/project/tedbot/replica.my.cnf';
my $timezone_str = '%Y년 %-m월 %-d일 (%a) %H:%M (KST)';
my $timezone_area = 'Asia/Seoul';

my $conn = DBI->connect("DBI:mysql:database=$dbname;host=$host;mysql_read_default_file=$default_file");
my $cursor = $conn->prepare("
SELECT a.user_name, a.user_editcount, b.ug_group
	FROM user AS a
	LEFT JOIN user_groups AS b
	ON ug_user = user_id
	WHERE user_editcount > '4999'
	ORDER BY user_editcount desc;
");
$cursor->execute();

my $bot_ko = MediaWiki::Bot->new({
	assert      => 'user',
	protocol    => 'https',
	host        => 'ko.wikipedia.org',
	agent       => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.66 Safari/537.36 Edg/80.0.361.40'
}) or die(0);
my $timezone_str = '%Y년 %-m월 %-d일 (%a) %H:%M (KST)';
my @placeholder;
my @excluded;
my $hold = 0;
foreach my $ls (split /\n/, $bot_ko->get_text(decode('utf-8', "위키백과:기여가 많은 위키백과 사용자 명단/자리 채움"))) {
	if ($ls =~ /^\s*<pre/i) {
		$hold = 1;
		next;
	}
	if ($hold eq 1 && $ls !~ /^\s*\<\/pre\>/i) {
		$ls =~ s/ +/_/g;
		push @placeholder, (encode('utf-8', $ls));
	}
}

$hold=0;
foreach my $ls (split /\n/, $bot_ko->get_text(decode('utf-8', "위키백과:기여가 많은 위키백과 사용자 명단/제외 목록"))) {
	if ($ls =~ /^\s*<pre/i) {
		$hold = 1;
		next;
	}
	if ($hold eq 1 && $ls !~ /^\s*\<\/pre\>/i) {
		$ls =~ s/ +/_/g;
		push @excluded, (encode('utf-8', $ls));
	}

}

setlocale(LC_TIME, $^O eq 'MSWin32' ? "Korean_Korea.utf8" : "ko_KR.utf8");
$ENV{TZ} = $timezone_area;
my $current_of = localtime->strftime($timezone_str);
print "== 편집 횟수에 따른 사용자 목록 ==\n";
print "* 갱신 일자: " . $current_of . "\n";

my $working = 0;
my $rows = $cursor->rows;
my $tmp_list = "";
while (my $row = $cursor->fetchrow_hashref()) {
	$tmp_list .= $row->{'user_name'} . "\t" . $row->{"user_editcount"} . "\t" . $row->{"ug_group"} . "\n";
}

my $prev_name = "";
my $first=1;
my $wikitext;
foreach my $ls (split /\n/, $tmp_list) {
	my $cur_name = (split /\t/, $ls)[0];
	my $cur_name2 = $cur_name; $cur_name2 =~ s/ +/_/g;
	my $contrib = (split /\t/, $ls)[1];
	my $right = (split /\t/, $ls)[2];
	my $is_placeholder = 0;
	if ($right =~ /bot/) {
		next;
	}

	my $skip = 0;
	foreach my $itm (@excluded) {
		if ($itm eq ${cur_name2}) {
			$skip = 1;
			last;
		}
	}
	if ($skip eq 1) {
		next;
	}
	foreach my $itm (@placeholder) {
		if ($itm eq ${cur_name2}) {
			$is_placeholder = 1;
			last;
		}
	}
	$right =~ s/interface-admin/인터페이스 관리자/i;
	$right =~ s/bot/봇/i;
	$right =~ s/sysop/관리자/i;
	$right =~ s/checkuser/검사관/i;
	$right =~ s/oversight/기록보호자/i;
	$right =~ s/suppress/기록보호자/i;
	$right =~ s/extendedconfirmed/자동 인증/i;
	$right =~ s/autopatrolled/점검 면제/i;
	$right =~ s/uploader/업로더/i;
	$right =~ s/rollbacker/일괄 되돌리기 기능 사용자/i;
	$right =~ s/bureaucrat/사무관/i;
	if ($first eq 1) {
		$wikitext = '# (' . $contrib . '회) ';
		if ($is_placeholder eq 1) {
			$wikitext .= '[자리 채움]';
		} else {
			$wikitext .= '{{사용자2|1=' . $cur_name2 . '}}';
		}
		if ($is_placeholder eq 0 && $right =~ /\S/) {
			$wikitext .= ' (' . $right;
		}
		$first = 0;
		$prev_name = $cur_name;
		next;
	}
	if ($is_placeholder eq 0) {
		if ($prev_name eq $cur_name) {
			$wikitext .= ', ' . $right;
		} else {
			$wikitext .= "\n" . '# (' . $contrib . '회) ' . '{{사용자2|1=' . $cur_name2 . '}}';
			if ($right =~ /\S/) {
				$wikitext .= ' (' . $right;
			}
		}
	}
	$prev_name = $cur_name;
}

$cursor->finish();
$conn->disconnect();

my $newWikitext;
foreach my $ls (split /\n/, $wikitext) {
	if ($ls !~ /(\]|\}\})\s*$/) {
		$ls .= ")";
	}
	$ls =~ s/, 자동 인증, /, /;
	$ls =~ s/\Q (자동 인증)\E//;
	$ls =~ s/\Q (자동 인증, \E/ (/;
	$ls =~ s/\Q, 자동 인증)\E/)/;

	$newWikitext .= $ls . "\n";
}

$cursor = $conn->prepare("
SELECT DISTINCT actor_name, COUNT(page_title) AS cnt
FROM page p
JOIN revision r ON p.page_id = r.rev_page
JOIN actor a ON a.actor_id = r.rev_actor
WHERE r.rev_parent_id = '0'
AND p.page_namespace = '0'
AND p.page_is_redirect = '0'
AND NOT IS_IPV4(actor_name)
AND NOT IS_IPV6(actor_name)
AND NOT EXISTS (SELECT 1 from user_groups WHERE ug_user=actor_user and LOWER(ug_group) = 'bot')
GROUP BY actor_name
HAVING cnt > 100
ORDER BY cnt DESC;
");
$cursor->execute();

$rows = $cursor->rows;
$tmp_list = "";
while (my $row = $cursor->fetchrow_hashref()) {
	$tmp_list .= $row->{'actor_name'} . "\t" . $row->{"cnt"} . "\n";
}

print $newWikitext . "\n";
print "== 신규 문서 작성 수에 따른 사용자 목록 ==\n";
print "* 갱신 일자: " . $current_of . "\n";

foreach my $ls (split /\n/, $tmp_list) {
	my $cur_name = (split /\t/, $ls)[0];
	my $cur_name2 = $cur_name; $cur_name2 =~ s/ +/_/g;
	my $contrib = (split /\t/, $ls)[1];
	my $is_placeholder = 0;
	my $skip = 0;
	foreach my $itm (@excluded) {
		if ($itm eq ${cur_name2}) {
			$skip = 1;
			last;
		}
	}
	if ($skip eq 1) {
		next;
	}
	foreach my $itm (@placeholder) {
		if ($itm eq ${cur_name2}) {
			$is_placeholder = 1;
			last;
		}
	}
	if ($is_placeholder eq 0) {
		print "# ($contrib건) {{사용자2|$cur_name}}\n";
	} else {
		print "# ($contrib건) [자리 채움]\n";
	}
}
