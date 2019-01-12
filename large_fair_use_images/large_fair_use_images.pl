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
my $timezone_str = '%Y�� %-m�� %-d�� (%a) %H:%M (KST)';
my $timezone_area = 'Asia/Seoul';
my $report_template = q(
������ ����: <onlyinclude>%s</onlyinclude>

�Ʒ��� [[��Ű���:������_���۹���_������_�̿�#�̹���]]���� �����ϴ� ������ �׸� �߿� ������ ũ�⸦ �������� �ʴ� �׸� ������ �����մϴ�.

);

my $report_template1 = q(
{| class="wikitable sortable plainlinks" style="width:100%%; margin:auto;"
|- style="white-space:nowrap;"
! ����
! ���� �̸�
|-
%s
|}

);

my $conn = DBI->connect("DBI:mysql:database=$dbname;host=$host;mysql_read_default_file=$default_file");
my $cursor = $conn->prepare(q(
SELECT * FROM
( SELECT page_title FROM page JOIN categorylinks ON page.page_id = categorylinks.cl_from WHERE page.page_namespace = 6 AND page.page_is_redirect = 0  AND
categorylinks.cl_to = '������_�ΰ�' ) AS pt
WHERE EXISTS (
  SELECT 1 FROM image WHERE pt.page_title=img_name AND IMG_MAJOR_MIME='image' AND (IMG_WIDTH*IMG_HEIGHT)>10000
);
));
$cursor->execute();

my $i = 1;
my (@output, @output2, @output3, @output4);
while (my $row = $cursor->fetchrow_hashref()) {
	my $page_title = sprintf("[[����:%s]]", $row->{'page_title'});
	my $table_row = sprintf("| %d\n| %s\n|-", $i, $page_title);
	push @output, $table_row;
	$i++;
}

$cursor = $conn->prepare(q(
SELECT * FROM
( SELECT page_title FROM page JOIN categorylinks ON page.page_id = categorylinks.cl_from WHERE page.page_namespace = 6 AND page.page_is_redirect = 0  AND
categorylinks.cl_to = '������_���๰' ) AS pt
WHERE EXISTS (
  SELECT 1 FROM image WHERE pt.page_title=img_name AND IMG_MAJOR_MIME='image' AND ((IMG_WIDTH*IMG_HEIGHT)>100000 OR IMG_WIDTH>200 OR IMG_HEIGHT>600)
);
));
$cursor->execute();

$i = 1;
while (my $row = $cursor->fetchrow_hashref()) {
	my $page_title = sprintf("[[����:%s]]", $row->{'page_title'});
	my $table_row = sprintf("| %d\n| %s\n|-", $i, $page_title);
	push @output2, $table_row;
	$i++;
}
$cursor = $conn->prepare(q(
SELECT * FROM
( SELECT page_title FROM page JOIN categorylinks ON page.page_id = categorylinks.cl_from WHERE page.page_namespace = 6 AND page.page_is_redirect = 0  AND
categorylinks.cl_to = '����_ǥ��' ) AS pt
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
	my $page_title = sprintf("[[����:%s]]", $row->{'page_title'});
	my $table_row = sprintf("| %d\n| %s\n|-", $i, $page_title);
	push @output3, $table_row;
	$i++;
}

$cursor = $conn->prepare(q(
SELECT * FROM
( SELECT page_title FROM page JOIN categorylinks ON page.page_id = categorylinks.cl_from WHERE page.page_namespace = 6 AND page.page_is_redirect = 0  AND
( categorylinks.cl_to = '��ȭ_���' OR categorylinks.cl_to = '����_����_���' OR categorylinks.cl_to = '��_������_��ũ����' OR categorylinks.cl_to = '�ڷ�����_���' OR
  categorylinks.cl_to = '����ũ�μ���Ʈ_��ǰ��_��ũ����' OR categorylinks.cl_to = '��_����Ʈ������_��ũ����' OR categorylinks.cl_to = '������_����_����_��ũ����' OR
  categorylinks.cl_to = '������_����Ʈ����_��ũ����' OR categorylinks.cl_to = '������_����Ʈ������_��ũ����'
 ) ) AS pt
WHERE EXISTS (
  SELECT 1 FROM image WHERE pt.page_title=img_name AND IMG_MAJOR_MIME='image' AND (IMG_WIDTH*IMG_HEIGHT)>40000
);
));
$cursor->execute();

$i = 1;
while (my $row = $cursor->fetchrow_hashref()) {
	my $page_title = sprintf("[[����:%s]]", $row->{'page_title'});
	my $table_row = sprintf("| %d\n| %s\n|-", $i, $page_title);
	push @output4, $table_row;
	$i++;
}



setlocale(LC_TIME, $^O eq 'MSWin32' ? "Korean_Korea.utf8" : "ko_KR.utf8");
$ENV{TZ} = $timezone_area;
my $current_of = localtime->strftime($timezone_str);;
my $final_result = sprintf($report_template, $current_of);

$final_result .= q(
== ������ �ΰ� ==
[[:�з�:������ �ΰ�]]�� ���� �׸� �� ���� ������ ���� 10,000 �ȼ��� �ʰ��� �׸��Դϴ�.
);
$final_result .= sprintf($report_template1, join("\n", @output));

$final_result .= q(
== ������ ���๰ ==
[[:�з�:������ ���๰]]�� ���� �׸� �� ���ΰ� 200 �ȼ�, ���ΰ� 600 �ȼ��� �ʰ��ϰų�, ���� ������ ���� 100,000 �ȼ��� �ʰ��� �׸��Դϴ�.
);
$final_result .= sprintf($report_template1, join("\n", @output2));

$final_result .= q(
== ���� ǥ�� ���� ==
[[:�з�:���� ǥ��]]�� ���� �׸� �� ���ο� ���� �� ª�� ���� �������� 150 �ȼ� �̻�, 250 �ȼ� ���ϸ� �������� �ʴ� �׸��Դϴ�.
);
$final_result .= sprintf($report_template1, join("\n", @output3));

$final_result .= q(
== ĸó ���� ==
[[:�з�:��ȭ ���]], [[:�з�:���� ���� ���]], [[:�з�:�� ������ ��ũ����]], [[:�з�:�ڷ����� ���]], [[:�з�:����ũ�μ���Ʈ ��ǰ�� ��ũ����]], [[:�з�:�� ����Ʈ������ ��ũ����]], [[:�з�:������ ���� ���� ��ũ����]], [[:�з�:������ ����Ʈ���� ��ũ����]], [[:�з�:������ ����Ʈ������ ��ũ����]]�� ���� �׸� �� ���� ������ ���� 40,000 �ȼ��� �ʰ��ϴ� �׸��Դϴ�.
);
$final_result .= sprintf($report_template1, join("\n", @output4));

$cursor->finish();
$conn->disconnect();

printf("%s", $final_result);
