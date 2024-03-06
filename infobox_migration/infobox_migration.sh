LANG=ko_KR.utf8
UTIL='expr wget date sed perl grep'
URL='https://ko.wikipedia.org/w/index.php?title=%ED%8A%B9%EC%88%98:%EA%B2%80%EC%83%89&limit=500&offset=0&ns10=1&search=hastemplate%3A%22%EC%A0%95%EB%B3%B4%EC%83%81%EC%9E%90+%EC%B9%B8%22+-intitle%3A%2F%5C%2F%28%EC%84%A4%EB%AA%85%EB%AC%B8%EC%84%9C%7C%EC%97%B0%EC%8A%B5%EC%9E%A5%29%2F+insource%3A%2F%5C%7B%5C%7B%EC%A0%95%EB%B3%B4%EC%83%81%EC%9E%90%5B+_%5D%2B%EC%B9%B8%2F&searchToken=e72kigfwsfjaquwyrleue0jb3'

out() {
	wget -qO- $1 | perl -pe 's/data-serp-pos="\d+">/\ntitle=/mg' | grep -P '^title=' | sed 's/^title=//' | perl -pe 's/<\/a>.+//mg'
}

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
echo '{| class="wikitable sortable plainlinks" style="width:100%; margin:auto;"'
echo '|- style="white-space:nowrap;"'
echo '! 순번 !! 문서 이름'
echo '|-'
IFS='
'
for sth in `( out $URL ) | sort -u`

do
	echo "| $CNT || [[$sth]]"
	echo "|-"
	CNT=`expr $CNT + 1`
done
echo "|}"

unset IFS
