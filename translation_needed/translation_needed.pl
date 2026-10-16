use strict;
use warnings;
use Time::Piece;
use POSIX qw(tzset);
use POSIX qw(locale_h);
use locale;
use DBI;
use Encode qw(decode);
use User::pwent;

my $kowiki_host = 'kowiki.analytics.db.svc.eqiad.wmflabs';
my $enwiki_host = 'enwiki.analytics.db.svc.eqiad.wmflabs';
my $kowiki_db = 'kowiki_p';
my $enwiki_db = 'enwiki_p';
my $default_file = getpwuid($<)->dir . "/replica.my.cnf";

my $timezone_str = '%Y년 %-m월 %-d일 (%a) %H:%M (KST)';
my $timezone_area = 'Asia/Seoul';
my $report_template = '

다음은 영어 위키백과 링크가 연결된 짧은 일반 문서를 내용이 작은 항목부터 순차적으로 나열합니다. 영어 위키백과 링크는 넘겨주기일 수 있습니다. 동음이의어 및 색인 모음 문서는 제외합니다.

마지막 갱신: <onlyinclude>%s</onlyinclude>

{| class="wikitable sortable plainlinks" style="width:100%%; margin:auto;"
|- style="white-space:nowrap;"
! 순번
! 문서 이름
! 문서 크기
! 영어 문서
! 최초 작성자
|-
%s
|}
';

my $ko_conn = DBI->connect("DBI:MariaDB:database=$kowiki_db;host=$kowiki_host;mariadb_read_default_file=$default_file", undef, undef, { RaiseError => 1, PrintError => 0 });

$ko_conn->do("SET SESSION interactive_timeout = 31536000");
$ko_conn->do("SET SESSION wait_timeout = 31536000");

# - categorylinks.cl_to는 MediaWiki 1.45에서 제거됨 -> cl_target_id + linktarget 사용
# - 최초 작성자는 문서의 가장 오래된 판 하나로 결정 (rev_parent_id = 0인 판이 여러 개면 행이 중복되므로)
# - DBD::MariaDB는 SQL 문을 문자열(Unicode)로 받으므로 한국어 리터럴은 decode 후 전달
my $cursor = $ko_conn->prepare(decode('UTF-8', "
SELECT
  p.page_title,
  p.page_len,
  l1.ll_title,
  a.actor_name
FROM page p
JOIN langlinks l1
  ON p.page_id = l1.ll_from AND l1.ll_lang = 'en'
JOIN revision r
  ON r.rev_id = (
    SELECT r2.rev_id
    FROM revision r2
    WHERE r2.rev_page = p.page_id
    ORDER BY r2.rev_timestamp, r2.rev_id
    LIMIT 1
  )
JOIN actor a
  ON r.rev_actor = a.actor_id
WHERE
  p.page_namespace = 0
  AND p.page_is_redirect = 0
  AND p.page_len < 1000
  AND NOT EXISTS (
    SELECT 1
    FROM categorylinks cl
    JOIN linktarget lt ON cl.cl_target_id = lt.lt_id
    WHERE p.page_id = cl.cl_from
      AND lt.lt_namespace = 14
      AND lt.lt_title IN (
        '삭제_신청_문서',
        '위키백과_넘나들기',
        '식별자_넘겨주기',
        '모든_동음이의어_문서',
        '모든_색인_모음_문서'
      )
  )
ORDER BY p.page_len ASC, p.page_title
LIMIT 5000;
"));
$cursor->execute();

my @rows = ();
my @ll_titles = ();
while (my $row = $cursor->fetchrow_hashref()) {
    push @rows, $row;
    push @ll_titles, $row->{'ll_title'};
}
$cursor->finish();
$ko_conn->disconnect();

my $en_conn = DBI->connect("DBI:MariaDB:database=$enwiki_db;host=$enwiki_host;mariadb_read_default_file=$default_file", undef, undef, { RaiseError => 1, PrintError => 0 });

sub get_redirect_flags {
    my ($dbh, $titles_ref) = @_;
    my %results;
    my $batch_size = 1000;
    my @batches;

    while (@$titles_ref) {
        push @batches, [ splice(@$titles_ref, 0, $batch_size) ];
    }

    foreach my $batch (@batches) {
        my @normalized_batch = map { my $t = $_; $t =~ s/ /_/g; $t } @$batch;
        my $placeholders = join(",", map {"?"} @normalized_batch);
        my $sql = "
            SELECT page_title, page_is_redirect
            FROM page
            WHERE page_namespace = 0 AND page_title IN ($placeholders)
        ";
        my $stmt = $dbh->prepare($sql);
        # DBD::MariaDB는 바인드 값도 문자열(Unicode)로 받으므로, DB에서 바이트열로 받은 제목은 decode 후 전달
        # (반환되는 page_title은 바이트열이므로 %results의 키는 기존처럼 바이트열 그대로 비교됨)
        $stmt->execute(map { decode('UTF-8', $_) } @normalized_batch);

        while (my $r = $stmt->fetchrow_hashref()) {
            $results{$r->{'page_title'}} = $r->{'page_is_redirect'};
        }
    }

    return %results;
}

my %en_redirects = get_redirect_flags($en_conn, [ @ll_titles ]);
$en_conn->disconnect();

my $i = 1;
my @output = ();
foreach my $row (@rows) {
    my $page_title = sprintf("[[%s]]", $row->{'page_title'});
    my $page_len = $row->{'page_len'};
    my $ll_title_raw = $row->{'ll_title'};

    # normalize title for comparison
    my $normalized_title = $ll_title_raw;
    $normalized_title =~ s/ /_/g;

    my $redirect_note;
    if (exists $en_redirects{$normalized_title}) {
        $redirect_note = $en_redirects{$normalized_title} == 1 ? ' <span style="background-color: #91ebff;">넘겨주기</span>' : '';
    } else {
        $redirect_note = ' <span style="background-color: #91ebff;">확인불가</span>';
        warn "[확인불가] $ll_title_raw → $normalized_title\n";
    }

    my $ll_title = sprintf("[[:en:%s|%s]]%s", $ll_title_raw, $ll_title_raw, $redirect_note);
    my $actor_name = sprintf("[[:사용자:%s|%s]]", $row->{'actor_name'}, $row->{'actor_name'});

    my $table_row = sprintf("| %d|| %s|| %d|| %s|| %s\n|-", $i, $page_title, $page_len, $ll_title, $actor_name);
    push @output, $table_row;
    $i++;
}

setlocale(LC_TIME, $^O eq 'MSWin32' ? "Korean_Korea.utf8" : "ko_KR.utf8");
$ENV{TZ} = $timezone_area;
my $current_of = localtime->strftime($timezone_str);
my $final_result = sprintf($report_template, $current_of, join("\n", @output));

print $final_result;

