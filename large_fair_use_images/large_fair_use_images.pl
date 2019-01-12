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
my $report_template = q(
마지막 갱신: <onlyinclude>%s</onlyinclude>

아래는 [[위키백과:비자유_저작물의_공정한_이용#이미지]]에서 설명하는 비자유 그림 중에 정해진 크기를 만족하지 않는 그림 파일을 나열합니다.

);

my $report_template1 = q(
{| class="wikitable sortable plainlinks" style="width:100%%; margin:auto;"
|- style="white-space:nowrap;"
! 순번
! 문서 이름
|-
%s
|}

);

my $conn = DBI->connect("DBI:mysql:database=$dbname;host=$host;mysql_read_default_file=$default_file");
my $cursor = $conn->prepare(q(
SELECT * FROM
( SELECT page_title FROM page JOIN categorylinks ON page.page_id = categorylinks.cl_from WHERE page.page_namespace = 6 AND page.page_is_redirect = 0  AND
categorylinks.cl_to = '비자유_로고' ) AS pt
WHERE EXISTS (
  SELECT 1 FROM image WHERE pt.page_title=img_name AND IMG_MAJOR_MIME='image' AND (IMG_WIDTH*IMG_HEIGHT)>10000
);
));
$cursor->execute();

my $i = 1;
my (@output, @output2, @output3, @output4);
while (my $row = $cursor->fetchrow_hashref()) {
	my $page_title = sprintf("[[:파일:%s]]", $row->{'page_title'});
	my $table_row = sprintf("| %d\n| %s\n|-", $i, $page_title);
	push @output, $table_row;
	$i++;
}

$cursor = $conn->prepare(q(
SELECT * FROM
( SELECT page_title FROM page JOIN categorylinks ON page.page_id = categorylinks.cl_from WHERE page.page_namespace = 6 AND page.page_is_redirect = 0  AND
categorylinks.cl_to = '비자유_건축물' ) AS pt
WHERE EXISTS (
  SELECT 1 FROM image WHERE pt.page_title=img_name AND IMG_MAJOR_MIME='image' AND ((IMG_WIDTH*IMG_HEIGHT)>100000 OR IMG_WIDTH>200 OR IMG_HEIGHT>600)
);
));
$cursor->execute();

$i = 1;
while (my $row = $cursor->fetchrow_hashref()) {
	my $page_title = sprintf("[[:파일:%s]]", $row->{'page_title'});
	my $table_row = sprintf("| %d\n| %s\n|-", $i, $page_title);
	push @output2, $table_row;
	$i++;
}
$cursor = $conn->prepare(q(
SELECT * FROM
( SELECT page_title FROM page JOIN categorylinks ON page.page_id = categorylinks.cl_from WHERE page.page_namespace = 6 AND page.page_is_redirect = 0  AND
categorylinks.cl_to = '음반_표지' ) AS pt
WHERE EXISTS (
  SELECT 1 FROM image WHERE pt.page_title=img_name AND IMG_MAJOR_MIME='image' AND NOT (
   ( IMG_WIDTH > IMG_HEIGHT AND IMG_HEIGHT >= 150 AND IMG_HEIGHT <= 250 ) OR
   ( IMG_WIDTH < IMG_HEIGHT AND IMG_WIDTH >= 150 AND IMG_WIDTH <= 250 ) OR
   ( IMG_WIDTH = IMG_HEIGHT AND IMG_WIDTH >= 150 AND IMG_WIDTH <= 250 )
  )
);
));
$cursor->execute();

$i = 1;
while (my $row = $cursor->fetchrow_hashref()) {
	my $page_title = sprintf("[[:파일:%s]]", $row->{'page_title'});
	my $table_row = sprintf("| %d\n| %s\n|-", $i, $page_title);
	push @output3, $table_row;
	$i++;
}

$cursor = $conn->prepare(q(
SELECT * FROM
( SELECT page_title FROM page JOIN categorylinks ON page.page_id = categorylinks.cl_from WHERE page.page_namespace = 6 AND page.page_is_redirect = 0  AND
( categorylinks.cl_to = '영화_장면' OR categorylinks.cl_to = '뮤직_비디오_장면' OR categorylinks.cl_to = '웹_페이지_스크린샷' OR categorylinks.cl_to = '텔레비전_장면' OR
  categorylinks.cl_to = '마이크로소프트_제품의_스크린샷' OR categorylinks.cl_to = '맥_소프트웨어의_스크린샷' OR categorylinks.cl_to = '비자유_비디오_게임_스크린샷' OR
  categorylinks.cl_to = '비자유_소프트웨어_스크린샷' OR categorylinks.cl_to = '윈도우_소프트웨어의_스크린샷'
 ) ) AS pt
WHERE EXISTS (
  SELECT 1 FROM image WHERE pt.page_title=img_name AND IMG_MAJOR_MIME='image' AND (IMG_WIDTH*IMG_HEIGHT)>40000
);
));
$cursor->execute();

$i = 1;
while (my $row = $cursor->fetchrow_hashref()) {
	my $page_title = sprintf("[[:파일:%s]]", $row->{'page_title'});
	my $table_row = sprintf("| %d\n| %s\n|-", $i, $page_title);
	push @output4, $table_row;
	$i++;
}



setlocale(LC_TIME, $^O eq 'MSWin32' ? "Korean_Korea.utf8" : "ko_KR.utf8");
$ENV{TZ} = $timezone_area;
my $current_of = localtime->strftime($timezone_str);;
my $final_result = sprintf($report_template, $current_of);

$final_result .= q(
== 비자유 로고 ==
[[:분류:비자유 로고]]에 속한 그림 중 가로 세로의 곱이 10,000 픽셀을 초과한 그림입니다.
);
$final_result .= sprintf($report_template1, join("\n", @output));

$final_result .= q(
== 비자유 건축물 ==
[[:분류:비자유 건축물]]에 속한 그림 중 가로가 200 픽셀, 세로가 600 픽셀을 초과하거나, 가로 세로의 곱이 100,000 픽셀을 초과한 그림입니다.
);
$final_result .= sprintf($report_template1, join("\n", @output2));

$final_result .= q(
== 음반 표지 사진 ==
[[:분류:음반 표지]]에 속한 그림 중 가로와 세로 중 짧은 것을 기준으로 150 픽셀 이상, 250 픽셀 이하를 만족하지 않는 그림입니다.
);
$final_result .= sprintf($report_template1, join("\n", @output3));

$final_result .= q(
== 캡처 사진 ==
[[:분류:영화 장면]], [[:분류:뮤직 비디오 장면]], [[:분류:웹 페이지 스크린샷]], [[:분류:텔레비전 장면]], [[:분류:마이크로소프트 제품의 스크린샷]], [[:분류:맥 소프트웨어의 스크린샷]], [[:분류:비자유 비디오 게임 스크린샷]], [[:분류:비자유 소프트웨어 스크린샷]], [[:분류:윈도우 소프트웨어의 스크린샷]]에 속한 그림 중 가로 세로의 곱이 40,000 픽셀을 초과하는 그림입니다.
);
$final_result .= sprintf($report_template1, join("\n", @output4));

$cursor->finish();
$conn->disconnect();

printf("%s", $final_result);
