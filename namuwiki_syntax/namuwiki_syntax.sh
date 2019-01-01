LANG=ko_KR.utf8
UTIL='expr wget date sed perl grep'
URL='https://ko.wikipedia.org/w/index.php?title=Ư��:�˻�&limit=5000&offset=0&profile=default&search=insource%3A%2F%28%5C%5B%5C%2A+%7C%5B%5E%5C%5B%5D%5C%5B%28����%7C����%7Cyoutube%29%5C%5D%7C%5C%7B%23���ڵ�%7C%5C%5Binclude%5C%28%7C%5C%5Bbr%5C%5D%7C%5C%7B%5C%7B%5C%7B%5C%2B%5B0-9%5D%29%2F&advancedSearch-current=%7B"namespaces"%3A%5B0%5D%7D'
CNT=1
timezone_area='Asia/Seoul'
timezone_str='%Y�� %-m�� %-d�� (%a) %H:%M (KST)'

for cmd in $UTIL
do
	$cmd --help 1>/dev/null 2>/dev/null
	RETCODE=$?
	if [ $RETCODE -ne 0 ]; then
		echo "The following utility is not available: $cmd"
		exit $RETCODE
	fi
done

export TZ=":${timezone_area}"
DATE=`date +"${timezone_str}"`
echo '������ ����: <onlyinclude>'$DATE'</onlyinclude>'
echo ''
echo '������Ű ������ ���ԵǾ��ų� ���ԵǾ��ٰ� �ǽɵǴ� �������Դϴ�. ��Ű����� �´� �������� ������ �ּ���. ([[��Ű���:�ٸ� ����Ʈ���� ���� �е鲲 �帮�� ����/������Ű]] ����)'
echo ''
echo '{| class="wikitable sortable plainlinks" style="width:100%; margin:auto;"'
echo '|- style="white-space:nowrap;"'
echo '! ���� !! ���� �̸�'
echo '|-'
IFS='
'

for sth in `wget -qO- $URL | perl -pe 's/title="/\ntitle="/mg' | grep -P '^title=' | perl -pe 's/(^title="|" +data-serp-pos=.*)//g' | grep -vP '>' | perl -pe 's/^\*+$//'`
do
	echo "| $CNT || [[${sth}]]"
	echo "|-"
	CNT=`expr $CNT + 1`
done
echo "|}"

unset IFS
