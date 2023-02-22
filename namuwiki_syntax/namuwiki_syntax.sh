LANG=ko_KR.utf8
UTIL='expr wget date sed perl grep cat'
URL='https://ko.wikipedia.org/w/index.php?title=특수:검색&limit=5000&offset=0&profile=default&search=insource%3A%2F%28%5C%5B%5C%2A+%7C%5B%5E%5C%5B%5D%5C%5B%28목차%7C각주%7Cyoutube%29%5C%5D%7C%5C%7B%23색코드%7C%5C%5Binclude%5C%28%7C%5C%5Bbr%5C%5D%7C%5C%7B%5C%7B%5C%7B%5C%2B%5B0-9%5D%29%2F&advancedSearch-current=%7B"namespaces"%3A%5B0%5D%7D'
URL2='https://ko.wikipedia.org/w/index.php?search=insource%3A%2Fhttps*%3A%5C%2F%5C%2Fnamu%5C.wiki%2F+-hastemplate%3A%22%ED%8A%B9%EC%A0%95%ED%8C%90+%EC%82%AD%EC%A0%9C+%EC%8B%A0%EC%B2%AD%22+-hastemplate%3A%22%EC%82%AD%EC%A0%9C+%EC%8B%A0%EC%B2%AD%22+-intitle%3A%2F%EC%9C%84%ED%82%A4%2F&title=%ED%8A%B9%EC%88%98%3A%EA%B2%80%EC%83%89&go=%EB%B3%B4%EA%B8%B0&ns0=1'
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
echo '더 시드 문법이 포함되었거나 포함되었다고 의심되는 문서들입니다. 위키백과에 맞는 문법으로 수정해 주세요. ([[위키백과:다른 사이트에서 오신 분들께 드리는 말씀/나무위키|참고 링크]])'
cat <<"END"
{| class="wikitable" style="text-align:center; width: 750px;"
! width="300px" | 더 시드 문법
! width="450px" |[[미디어위키]] 문법
|-
|<code><nowiki>[* 주석]</nowiki></code>||<code><nowiki><ref>주석</ref></nowiki></code>
|- 
|<code><nowiki>[각주]</nowiki></code><br />||<code><nowiki><references/></nowiki></code><br /><code><nowiki>{{각주}}</nowiki></code>
|-
|<code><nowiki>{{{+1 한단계 커진 글자}}}</nowiki></code>||<code><nowiki><span style="font-size:larger">한단계 커진 글자</span></nowiki></code><br /><code><nowiki>{{글꼴|size=120%|글자}}</nowiki></code>
|-
|<code><nowiki>[include(틀:XXX)]</nowiki></code>||<code><nowiki>{{XXX}}</nowiki></code>
|-
|<code><nowiki>{{{#색코드 색}}}</nowiki></code>||<code><nowiki><span style="color:색코드">색</span></nowiki></code><br /><code><nowiki>{{글씨 색|green|초록색 글씨}}</nowiki></code>
|-
|<code><nowiki>[목차]</nowiki></code>||'''사용하지 않음 (삭제)'''
|-
|<code><nowiki>[youtube(영상 ID)]</nowiki></code><br /><code><nowiki>[[youtube(영상 ID)]]</nowiki></code>||'''사용하지 않음 (삭제)'''
|-
|<code><nowiki>[br]</nowiki></code>||<code><nowiki><br /></nowiki></code>
|}
END
echo ''
echo '{| class="wikitable sortable plainlinks" style="width:100%; margin:auto;"'
echo '|- style="white-space:nowrap;"'
echo '! 순번 !! 문서 이름'
echo '|-'
IFS='
'

for sth in `wget -qO- $URL | perl -pe 's/title="/\ntitle="/mg' | grep -P '^title=' | perl -pe 's/(^title="|" +data-serp-pos=.*)//g' | grep -vP '>|\[' | perl -pe 's/^\*+$|(More options|더 많은 옵션)"//'`
do
	echo "| $CNT || [[${sth}]]"
	echo "|-"
	CNT=`expr $CNT + 1`
done
echo "|}"

CNT=1
echo ''
echo '== 외부 링크(namu.wiki)를 사용하는 문서 =='
echo '동일 문서가 한국어 위키백과에 있다면 한국어 위키백과의 내부 링크로 수정해 주세요.'
echo '{| class="wikitable sortable plainlinks" style="width:100%; margin:auto;"'
echo '|- style="white-space:nowrap;"'
echo '! 순번 !! 문서 이름'
echo '|-'
IFS='
'
for sth in `wget -qO- $URL2 | perl -pe 's/title="/\ntitle="/mg' | grep -P '^title=' | perl -pe 's/(^title="|" +data-serp-pos=.*)//g' | grep -vP '>|\[' | perl -pe 's/^\*+$|(More options|더 많은 옵션)"//'`
do
	echo "| $CNT || [[${sth}]]"
	echo "|-"
	CNT=`expr $CNT + 1`
done
echo "|}"

unset IFS
