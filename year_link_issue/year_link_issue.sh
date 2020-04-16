LANG=ko_KR.utf8
UTIL='expr wget date sed perl grep cat'
URL1='https://ko.wikipedia.org/w/index.php?title=%ED%8A%B9%EC%88%98:%EA%B2%80%EC%83%89&limit=5000&offset=0&profile=default&search=insource%3A%2F%5C%5B%5C%5B%5B0-9%5D%7B1%2C4%7D%EB%85%84%5C%7C'
URL2='%EB%85%84%5C%5D%5C%5D%2F&advancedSearch-current={}&ns0=1'
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
FULLCNT="2... 1... 9.. 8.. 7.. 6.. 5.. 4.. 3.. 2.. 1.. 9. 8. 7. 6. 5. 4. 3. 2. 1. 9 8 7 6 5 4 3 2 1"

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
IFS=' '
for customitem in ${FULLCNT}
do
echo ''
echo "== `echo ${customitem}년 | sed 's/\./X/g'` =="
echo '{| class="wikitable sortable plainlinks" style="width:100%; margin:auto;"'
echo '|- style="white-space:nowrap;"'
echo '! 순번 !! 문서 이름 !! 일치'
echo '|-'
IFS='
'
CNT=1
HOLD=0
for sth in `wget -qO- ${URL1}${customitem}${URL2}`
do
	if [ $HOLD -eq 1 ]; then
		if [ `echo $sth | grep -cP '<span class="searchmatch">'` -ne 0 ]; then
			SEARCHMATCH=`echo $sth | perl -pe 's/<\/span>.*//' | perl -pe 's/.*\Q<span class="searchmatch">\E//mg' | perl -pe 's/<\/span>.*//'`
			echo "<nowiki>$SEARCHMATCH</nowiki>"
			echo "|-"
			HOLD=0
		fi
	fi
	for sth2 in `echo $sth | grep " data-serp-pos=" | perl -pe 's/title="/\ntitle="/mg' | grep -P '^title='`
	do
		SEARCHMATCH="-"
		if [ $HOLD -eq 1 ]; then
			echo "-"
			echo "|-"
			HOLD=0
		fi
		TITLE=`echo $sth2 | perl -pe 's/(^title="|" +data-serp-pos=.*)//g' | grep -vP '>' | perl -pe 's/^\*+$//'`
		if [ `echo $TITLE | grep -Pc '\S'` -ne 0 ]; then
			for sth3 in `echo $sth2 | grep '<span class="searchmatch">'`
			do
				SEARCHMATCH=`echo $sth2 | perl -pe 's/.*\Q<span class="searchmatch">\E//mg' | perl -pe 's/<\/span>.*//'`
			done
			if [ `echo ${SEARCHMATCH} | grep -cP '^-$'` -ne 0 ]; then
				echo -n "| $CNT || [[${TITLE}]] || "
				HOLD=1
			else
				echo "| $CNT || [[${TITLE}]] || <nowiki>${SEARCHMATCH}</nowiki>"
				echo "|-"
			fi
			CNT=`expr $CNT + 1`
		fi
	done
done
echo "|}"
done

unset IFS
