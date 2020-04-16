LANG=ko_KR.utf8
UTIL='expr wget date sed perl grep cat'
URL1='https://ko.wikipedia.org/w/index.php?title=%ED%8A%B9%EC%88%98:%EA%B2%80%EC%83%89&limit=5000&offset=0&ns0=1&search=insource%3A%2F%5C%5B%5C%5B%5B0-9%5D%7B1%2C4%7D%EB%85%84%5C%7C'
URL2='%EB%85%84%5C%5D%5C%5D%2F&advancedSearch-current={}'
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
FULLCNT=`date +'%Y'`
FULLCNT=`expr ${FULLCNT} + 1`

export TZ=":${timezone_area}"
DATE=`date +"${timezone_str}"`
echo '마지막 갱신: <onlyinclude>'$DATE'</onlyinclude>'
echo ''
echo '불필요하거나 잘못된 연도 링크가 포함된 문서 목록입니다. 기계적으로 판단하여 수정하기 어려운 연도 링크가 있으므로 사람의 눈으로 직접 판단하여 수정해 주시면 감사하겠습니다.'
echo ''
cat <<"END"
* 문제가 되는 링크 예시
** <nowiki>[[2020년|2020년]]</nowiki> → <nowiki>[[2020년]]</nowiki>으로 수정 필요
** <nowiki>[[2018년|2020년]]</nowiki> → <nowiki>[[2018년]] 또는 [[2020년]]</nowiki>으로 수정 필요
END
while true
do
FULLCNT=`expr $FULLCNT - 1`
if [ $FULLCNT -eq 0 ]; then
	break
fi
echo ''
echo "== ${FULLCNT}년 =="
echo '{| class="wikitable sortable plainlinks" style="width:100%; margin:auto;"'
echo '|- style="white-space:nowrap;"'
echo '! 순번 !! 문서 이름'
echo '|-'
IFS='
'
CNT=1
for sth in `wget -qO- ${URL1}${FULLCNT}${URL2} | perl -pe 's/title="/\ntitle="/mg' | grep -P '^title=' | perl -pe 's/(^title="|" +data-serp-pos=.*)//g' | grep -vP '>' | perl -pe 's/^\*+$//'`
do
	echo "| $CNT || [[${sth}]]"
	echo "|-"
	CNT=`expr $CNT + 1`
done
echo "|}"
if [ $CNT -ne 1 ]; then
	CNT=`expr $CNT - 1`
	echo "=== 수정 필요 ($CNT건) ==="
	echo "위 목록의 링크에 들어가셔서 <code><nowiki>|${FULLCNT}년]]</nowiki></code>으로 끝나는 링크를 찾아 알맞은 연도로 링크를 수정해 주세요."
fi
done

unset IFS
