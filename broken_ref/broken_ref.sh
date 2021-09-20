LANG=ko_KR.utf8
UTIL='expr wget date sed perl grep'
URL='https://ko.wikipedia.org/w/index.php?title=%ED%8A%B9%EC%88%98:%EA%B2%80%EC%83%89&limit=5000&offset=0&profile=default&search=%22%EC%9D%B4%EB%A6%84%EC%9D%84+%EA%B0%80%EC%A7%84+%EC%A3%BC%EC%84%9D%EC%97%90+%EC%A0%9C%EA%B3%B5%ED%95%9C+%ED%85%8D%EC%8A%A4%ED%8A%B8%EA%B0%80+%EC%97%86%EC%8A%B5%EB%8B%88%EB%8B%A4%22&advancedSearch-current=%7B%7D&ns0=1&searchToken=9n2dczqm4013jdxlrcaw5b3m2'
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
for sth in `wget -qO- $URL | perl -pe 's/title="/\ntitle="/mg' | grep -P '^title=' | perl -pe 's/(^title="|" +data-serp-pos=.*)//g' | grep -vP '>' | perl -pe 's/^\*+$|(More options|더 많은 옵션)"//'`
do
	echo "| $CNT || [[$sth]]"
	echo "|-"
	CNT=`expr $CNT + 1`
done
echo "|}"

unset IFS
