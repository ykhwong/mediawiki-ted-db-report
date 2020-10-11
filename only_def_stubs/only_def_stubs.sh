LANG=ko_KR.utf8
UTIL='expr wget date sed perl grep'
URL='https://ko.wikipedia.org/w/index.php?title=%ED%8A%B9%EC%88%98:%EA%B2%80%EC%83%89&limit=5000&offset=0&ns0=1&search=hastemplate%3A%22%ED%86%A0%EB%A7%89%EA%B8%80%22+insource%3A%2F%EC%9D%B4%EB%8B%A4%5C.%2F+insource%3A%2F%28%EC%9D%80%7C%EB%8A%94%29+%2F+-insource%3A%2F%5C..%2A%5C.%2F+-insource%3A%2F%5C%2A%2F+-insource%3A%2F%3D%3D%2F+-hastemplate%3A%22%EB%8F%99%EC%9D%8C%EC%9D%B4%EC%9D%98%22+-hastemplate%3A%22%EB%8F%99%EB%AA%85%EC%9D%B4%EC%9D%B8%22+-hastemplate%3A%22%EC%83%89%EC%9D%B8+%EB%AA%A8%EC%9D%8C+%EB%AC%B8%EC%84%9C%22&advancedSearch-current={}'
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
echo '다음은 {{틀|토막글}} 틀을 사용하는 문서 중에 한 줄 정의만 존재하는 것으로 의심되는 문서를 나열한 것입니다. 이 목록은 기계적으로 수집된 것이며 완전한 목록임을 보장하지는 않습니다.'
echo '{| class="wikitable sortable plainlinks" style="width:100%; margin:auto;"'
echo '|- style="white-space:nowrap;"'
echo '! 순번 !! 문서 이름'
echo '|-'
IFS='
'
for sth in `wget -qO- $URL | perl -pe 's/title="/\ntitle="/mg' | grep -P '^title=' | perl -pe 's/(^title="|" +data-serp-pos=.*)//g' | grep -vP '>' | perl -pe 's/^\*+$//'`
do
	echo "| $CNT || [[$sth]]"
	echo "|-"
	CNT=`expr $CNT + 1`
done
echo "|}"

unset IFS
