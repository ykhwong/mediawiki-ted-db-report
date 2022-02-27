LANG=ko_KR.utf8
UTIL='expr wget date sed perl grep cat'
URL3='https://ko.wikipedia.org/w/index.php?search=insource%3A%2F%5C%7B%5C%7B+%2A%28%EC%82%AC%EC%9A%A9%EC%9E%90%7CUser%29+%2A%3A+%2A%5B%5E%5C%7C%5D%2B%2Fi&title=%ED%8A%B9%EC%88%98:%EA%B2%80%EC%83%89&profile=advanced&fulltext=1&ns0=1'
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
echo '일반 문서에 사용자 문서를 끼워넣은 항목을 나열합니다.'
echo ''
echo '{| class="wikitable sortable plainlinks" style="width:100%; margin:auto;"'
echo '|- style="white-space:nowrap;"'
echo '! 순번 !! 문서 이름 !! 일치'
echo '|-'
IFS='
'
CNT=1
HOLD=0
for sth in `wget -qO- ${URL3}`
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

unset IFS
