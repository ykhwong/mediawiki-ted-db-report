LANG=C
UTIL='expr wget'
URL='https://ko.wikipedia.org/w/index.php?title=%ED%8A%B9%EC%88%98:%EA%B2%80%EC%83%89&limit=5000&offset=0&ns1=1&search=-insource%3A%2F%5B%5E+%5D%2F'
CNT=1

for cmd in $UTIL
do
	$cmd --help 1>/dev/null 2>/dev/null
	RETCODE=$?
	if [ $RETCODE -ne 0 ]; then
		echo "The following utility is not available: $cmd"
		exit $RETCODE
	fi
done

echo '마지막 갱신: <onlyinclude>2018년 8월 28일 (금) 12:05 (KST)</onlyinclude>'
echo ''
echo '{| class="wikitable sortable plainlinks" style="width:100%; margin:auto;"'
echo '|- style="white-space:nowrap;"'
echo '! 순번 !! 문서 이름'
echo '|-'
IFS='
'
for sth in `wget -qO- $URL | sed 's/title="토론:/\ntitle="토론/mg' | sed 's/title="토론:/\ntitle="토론:/mg' | grep -P '^title=' | perl -pe 's/(^title="|" +data-serp-pos=.*)//g'`
do
	echo "| $CNT || [[$sth]]"
	echo "|-"
	CNT=`expr $CNT + 1`
done
echo "|}"

unset IFS
