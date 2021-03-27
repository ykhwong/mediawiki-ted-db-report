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
아래는 [[위키백과:비자유_저작물의_공정한_이용#이미지]]에서 설명하는 비자유 그림 중에 지나치게 큰 크기의 그림 파일을 나열합니다. (저장 기준임. 표시 기준의 2배)
);

my $report_template1 = q(
{| class="wikitable sortable plainlinks" style="width:100%%; margin:auto;"
|- style="white-space:nowrap;"
! 순번
! 문서 이름
! 가로
! 세로
! 가로x세로
<!-- ! 생성자 -->
|-
%s
|}
);

my $conn = DBI->connect("DBI:mysql:database=$dbname;host=$host;mysql_read_default_file=$default_file");
#my $cursor = $conn->prepare(q(
#SELECT * FROM
#( SELECT page.page_title, image.img_width, image.img_height, rev_user_text FROM page JOIN categorylinks ON page.page_id = categorylinks.cl_from JOIN image ON page.page_title=image.img_name JOIN revision_userindex ON page_id = rev_page WHERE rev_timestamp > 1 AND rev_parent_id = '0' AND page.page_namespace = 6 AND page.page_is_redirect = 0  AND
#categorylinks.cl_to = '비자유_로고' ) AS pt
#WHERE EXISTS (
#  SELECT 1 FROM image WHERE pt.page_title=img_name AND IMG_MAJOR_MIME='image' AND (IMG_WIDTH*IMG_HEIGHT)>20000
#);
#));

my $cursor = $conn->prepare(q(
SELECT * FROM
( SELECT page.page_title, image.img_width, image.img_height FROM page JOIN categorylinks ON page.page_id = categorylinks.cl_from JOIN image ON page.page_title=image.img_name JOIN revision_userindex ON page_id = rev_page WHERE rev_timestamp > 1 AND rev_parent_id = '0' AND page.page_namespace = 6 AND page.page_is_redirect = 0  AND
categorylinks.cl_to = '비자유_로고' ) AS pt
WHERE EXISTS (
  SELECT 1 FROM image WHERE pt.page_title=img_name AND IMG_MAJOR_MIME='image' AND (IMG_WIDTH*IMG_HEIGHT)>100000
);
));

$cursor->execute();

my $i = 1;
my (@output, @output2, @output3, @output4);
while (my $row = $cursor->fetchrow_hashref()) {
	my $page_title = sprintf("[[:파일:%s]]", $row->{'page_title'});
	my $img_width = sprintf("%s", $row->{'img_width'});
	my $img_height = sprintf("%s", $row->{'img_height'});
	my $img_size = $img_width * $img_height;
	#my $author = sprintf("%s", $row->{'rev_user_text'});
	#my $table_row = sprintf("| %d || %s || %d || %d || %s\n|-", $i, $page_title, $img_width, $img_height, $author);
	my $table_row = sprintf("| %d || %s || %d || %d || %d\n|-", $i, $page_title, $img_width, $img_height, $img_size);
	if ($row->{'page_title'} =~ /\.svg$/i) { next; }
	push @output, $table_row;
	$i++;
}

#$cursor = $conn->prepare(q(
#SELECT * FROM
#( SELECT page.page_title, image.img_width, image.img_height, rev_user_text FROM page JOIN categorylinks ON page.page_id = categorylinks.cl_from JOIN image ON page.page_title=image.img_name JOIN revision_userindex ON page_id = rev_page WHERE rev_timestamp > 1 AND rev_parent_id = '0' AND page.page_namespace = 6 AND page.page_is_redirect = 0  AND
#categorylinks.cl_to = '비자유_건축물' ) AS pt
#WHERE EXISTS (
#  SELECT 1 FROM image WHERE pt.page_title=img_name AND IMG_MAJOR_MIME='image' AND ((IMG_WIDTH*IMG_HEIGHT)>200000 OR IMG_WIDTH>400 OR IMG_HEIGHT>1200)
#);
#));
$cursor = $conn->prepare(q(
SELECT * FROM
( SELECT page.page_title, image.img_width, image.img_height FROM page JOIN categorylinks ON page.page_id = categorylinks.cl_from JOIN image ON page.page_title=image.img_name JOIN revision_userindex ON page_id = rev_page WHERE rev_timestamp > 1 AND rev_parent_id = '0' AND page.page_namespace = 6 AND page.page_is_redirect = 0  AND
categorylinks.cl_to = '비자유_건축물' ) AS pt
WHERE EXISTS (
  SELECT 1 FROM image WHERE pt.page_title=img_name AND IMG_MAJOR_MIME='image' AND ((IMG_WIDTH*IMG_HEIGHT)>200000 OR IMG_WIDTH>400 OR IMG_HEIGHT>1200)
);
));

$cursor->execute();

$i = 1;
while (my $row = $cursor->fetchrow_hashref()) {
	my $page_title = sprintf("[[:파일:%s]]", $row->{'page_title'});
	my $img_width = sprintf("%s", $row->{'img_width'});
	my $img_height = sprintf("%s", $row->{'img_height'});
	my $img_size = $img_width * $img_height;
	#my $author = sprintf("%s", $row->{'rev_user_text'});
	#my $table_row = sprintf("| %d || %s || %d || %d || %s\n|-", $i, $page_title, $img_width, $img_height, $author);
	my $table_row = sprintf("| %d || %s || %d || %d || %d\n|-", $i, $page_title, $img_width, $img_height, $img_size);
	if ($row->{'page_title'} =~ /\.svg$/i) { next; }
	push @output2, $table_row;
	$i++;
}
#$cursor = $conn->prepare(q(
#SELECT * FROM
#( SELECT page.page_title, image.img_width, image.img_height, rev_user_text FROM page JOIN categorylinks ON page.page_id = categorylinks.cl_from JOIN image ON page.page_title=image.img_name JOIN revision_userindex ON page_id = rev_page WHERE rev_timestamp > 1 AND rev_parent_id = '0' AND page.page_namespace = 6 AND page.page_is_redirect = 0  AND
#categorylinks.cl_to = '음반_표지' ) AS pt
#WHERE EXISTS (
#  SELECT 1 FROM image WHERE pt.page_title=img_name AND IMG_MAJOR_MIME='image' AND (
#   ( IMG_WIDTH > IMG_HEIGHT AND IMG_HEIGHT > 500 ) OR
#   ( IMG_WIDTH < IMG_HEIGHT AND IMG_WIDTH > 500 ) OR
#   ( IMG_WIDTH = IMG_HEIGHT AND IMG_WIDTH > 500 )
#  )
#);
#));
$cursor = $conn->prepare(q(
SELECT * FROM
( SELECT page.page_title, image.img_width, image.img_height FROM page JOIN categorylinks ON page.page_id = categorylinks.cl_from JOIN image ON page.page_title=image.img_name JOIN revision_userindex ON page_id = rev_page WHERE rev_timestamp > 1 AND rev_parent_id = '0' AND page.page_namespace = 6 AND page.page_is_redirect = 0  AND
categorylinks.cl_to = '음반_표지' ) AS pt
WHERE EXISTS (
  SELECT 1 FROM image WHERE pt.page_title=img_name AND IMG_MAJOR_MIME='image' AND (
   ( IMG_WIDTH > IMG_HEIGHT AND IMG_HEIGHT > 500 ) OR
   ( IMG_WIDTH < IMG_HEIGHT AND IMG_WIDTH > 500 ) OR
   ( IMG_WIDTH = IMG_HEIGHT AND IMG_WIDTH > 500 )
  )
);
));

$cursor->execute();

$i = 1;
while (my $row = $cursor->fetchrow_hashref()) {
	my $page_title = sprintf("[[:파일:%s]]", $row->{'page_title'});
	my $img_width = sprintf("%s", $row->{'img_width'});
	my $img_height = sprintf("%s", $row->{'img_height'});
	my $img_size = $img_width * $img_height;
	#my $author = sprintf("%s", $row->{'rev_user_text'});

	if ($img_width eq $img_height) {
		$img_width = "'''" . $img_width . "'''";
		$img_height = "'''" . $img_height . "'''";
	}

	#my $table_row = sprintf("| %d || %s || %s || %s || %s\n|-", $i, $page_title, $img_width, $img_height, $author);
	my $table_row = sprintf("| %d || %s || %s || %s || %d\n|-", $i, $page_title, $img_width, $img_height, $img_size);
	if ($row->{'page_title'} =~ /\.svg$/i) { next; }
	push @output3, $table_row;
	$i++;
}

#$cursor = $conn->prepare(q(
#SELECT * FROM
#( SELECT page.page_title, image.img_width, image.img_height, rev_user_text FROM page JOIN categorylinks ON page.page_id = categorylinks.cl_from JOIN image ON page.page_title=image.img_name JOIN revision_userindex ON page_id = rev_page WHERE rev_timestamp > 1 AND rev_parent_id = '0' AND page.page_namespace = 6 AND page.page_is_redirect = 0  AND
#( categorylinks.cl_to = '영화_장면' OR categorylinks.cl_to = '뮤직_비디오_장면' OR categorylinks.cl_to = '비자유_웹_페이지_스크린샷' OR categorylinks.cl_to = '텔레비전_장면' OR
#  categorylinks.cl_to = '마이크로소프트_제품의_스크린샷' OR categorylinks.cl_to = '맥_소프트웨어의_스크린샷' OR categorylinks.cl_to = '비자유_비디오_게임_스크린샷' OR
#  categorylinks.cl_to = '비자유_소프트웨어_스크린샷' OR categorylinks.cl_to = '윈도우_소프트웨어의_스크린샷'
# ) ) AS pt
#WHERE EXISTS (
#  SELECT 1 FROM image WHERE pt.page_title=img_name AND IMG_MAJOR_MIME='image' AND (IMG_WIDTH*IMG_HEIGHT)>80000
#);
#));
$cursor = $conn->prepare(q(
SELECT DISTINCT * FROM
( SELECT page.page_title, image.img_width, image.img_height FROM page JOIN categorylinks ON page.page_id = categorylinks.cl_from JOIN image ON page.page_title=image.img_name JOIN revision_userindex ON page_id = rev_page WHERE rev_timestamp > 1 AND rev_parent_id = '0' AND page.page_namespace = 6 AND page.page_is_redirect = 0  AND
( categorylinks.cl_to = '영화_장면' OR categorylinks.cl_to = '뮤직_비디오_장면' OR categorylinks.cl_to = '비자유_웹_페이지_스크린샷' OR categorylinks.cl_to = '텔레비전_장면' OR
  categorylinks.cl_to = '마이크로소프트_제품의_스크린샷' OR categorylinks.cl_to = '맥_소프트웨어의_스크린샷' OR categorylinks.cl_to = '비자유_비디오_게임_스크린샷' OR
  categorylinks.cl_to = '비자유_소프트웨어_스크린샷' OR categorylinks.cl_to = '윈도우_소프트웨어의_스크린샷'
 ) ) AS pt
WHERE EXISTS (
  SELECT 1 FROM image WHERE pt.page_title=img_name AND IMG_MAJOR_MIME='image' AND (IMG_WIDTH*IMG_HEIGHT)>80000
);
));

$cursor->execute();

$i = 1;
while (my $row = $cursor->fetchrow_hashref()) {
	my $page_title = sprintf("[[:파일:%s]]", $row->{'page_title'});
	my $img_width = sprintf("%s", $row->{'img_width'});
	my $img_height = sprintf("%s", $row->{'img_height'});
	my $img_size = $img_width * $img_height;
	#my $author = sprintf("%s", $row->{'rev_user_text'});
	#my $table_row = sprintf("| %d || %s || %d || %d || %s\n|-", $i, $page_title, $img_width, $img_height, $author);
	my $table_row = sprintf("| %d || %s || %d || %d || %d \n|-", $i, $page_title, $img_width, $img_height, $img_size);
	if ($row->{'page_title'} =~ /\.svg$/i) { next; }
	push @output4, $table_row;
	$i++;
}



setlocale(LC_TIME, $^O eq 'MSWin32' ? "Korean_Korea.utf8" : "ko_KR.utf8");
$ENV{TZ} = $timezone_area;
my $current_of = localtime->strftime($timezone_str);;
my $final_result = sprintf($report_template, $current_of);

$final_result .= q(
== 비자유 로고 ==
* 참조: [[:분류:비자유 로고]]
* 기준: 가로 세로의 곱을 100,000 픽셀을 초과 (저장 기준임. 표시 기준의 2배)
);
$final_result .= sprintf($report_template1, join("\n", @output));

$final_result .= q(
== 비자유 건축물 ==
* 참조: [[:분류:비자유 건축물]]
* 기준: 가로가 400 픽셀, 세로가 1200 픽셀을 초과 또는 가로 세로의 곱이 200,000 픽셀을 초과 (저장 기준임. 표시 기준의 2배)
);
$final_result .= sprintf($report_template1, join("\n", @output2));

$final_result .= q(
== 음반 표지 사진 ==
* 참조: [[:분류:음반 표지]]
* 기준: 가로, 세로 중 짧은 것을 기준으로 500 픽셀을 초과 (저장 기준임. 표시 기준의 2배)
);
$final_result .= sprintf($report_template1, join("\n", @output3));

$final_result .= q(
== 캡처 사진 ==
* 참조: [[:분류:영화 장면]], [[:분류:뮤직 비디오 장면]], [[:분류:비자유 웹 페이지 스크린샷]], [[:분류:텔레비전 장면]], [[:분류:마이크로소프트 제품의 스크린샷]], [[:분류:맥 소프트웨어의 스크린샷]], [[:분류:비자유 비디오 게임 스크린샷]], [[:분류:비자유 소프트웨어 스크린샷]], [[:분류:윈도우 소프트웨어의 스크린샷]]
* 기준: 가로 세로의 곱이 80,000 픽셀을 초과하는 그림입니다. (저장 기준임. 표시 기준의 2배)
);
$final_result .= sprintf($report_template1, join("\n", @output4));

$cursor->finish();
$conn->disconnect();

printf("%s", $final_result);
