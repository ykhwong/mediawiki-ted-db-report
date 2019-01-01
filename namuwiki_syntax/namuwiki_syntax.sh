LANG=ko_KR.utf8
UTIL='expr wget date sed perl grep'
URL='https://ko.wikipedia.org/w/index.php?title=특수:검색&limit=5000&offset=0&profile=default&search=insource%3A%2F%28%5C%5B%5C%2A+%7C%5B%5E%5C%5B%5D%5C%5B%28목차%7C각주%7Cyoutube%29%5C%5D%7C%5C%7B%23색코드%7C%5C%5Binclude%5C%28%7C%5C%5Bbr%5C%5D%7C%5C%7B%5C%7B%5C%7B%5C%2B%5B0-9%5D%29%2F&advancedSearch-current=%7B"namespaces"%3A%5B0%5D%7D'
CNT=1
timezone_area='Asia/Seoul'
timezone_str='%Y년 %-m월 %-d일 (%a) %H:%M (KST)'

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
echo '마지막 갱신: <onlyinclude>'$DATE'</onlyinclude>'
echo ''
echo '나무위키 문법이 포함되었거나 포함되었다고 의심되는 문서들입니다. 위키백과에 맞는 문법으로 수정해 주세요. ([[위키백과:다른 사이트에서 오신 분들께 드리는 말씀/나무위키]] 참고)'
echo ''
echo '{| class="wikitable sortable plainlinks" style="width:100%; margin:auto;"'
echo '|- style="white-space:nowrap;"'
echo '! 순번 !! 문서 이름'
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
