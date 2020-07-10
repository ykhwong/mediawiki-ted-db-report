LANG=ko_KR.utf8
UTIL='expr wget date sed perl grep'
URL1='https://ko.wikipedia.org/w/index.php?title=%ED%8A%B9%EC%88%98:%EA%B2%80%EC%83%89&limit=5000&offset=0&profile=default&search=insource%3A%2F%5C%5B%5C%5B%28en%7Cceb%7Csv%7Cde%7Cfr%7Cnl%7Cru%7Ces%7Cit%7Cpl%7Cwar%7Cvi%7Cja%7Czh%7Cpt%7Cuk%7Cfa%7Car%7Csr%7Cca%7Cno%7Csh%7Cfi%7Cid%7Chu%7Cko%7Ccs%7Cro%7Cms%7Ctr%7Ceu%7Ceo%7Chy%7Cbg%7Cda%7Che%7Czh-min-nan%7Csk%7Ckk%7Cmin%7Cce%7Chr%7Clt%7Cet%7Csl%7Cbe%7Cel%7Cgl%7Cur%7Cnn%7Csimple%7Caz%7Cuz%7Cla%7Cth%7Chi%7Cka%7Cvo%7Cta%7Cazb%7Ccy%7Cmk%7Ctg%7Cast%7Clv%7Cmg%7Coc%7Ctt%7Ctl%7Cky%7Cbs%7Csq%7Cnew%7Cte%7Czh-yue%7Cbr%7Cbe-tarask%7Cpms%7Caf%7Cbn%7Cml%7Cjv%7Clb%7Cht%29%3A%2F'

for cmd in $UTIL
do
	$cmd --help 1>/dev/null 2>/dev/null
	RETCODE=$?
	if [ $RETCODE -ne 0 ]; then
		echo "The following utility is not available: $cmd"
		exit $RETCODE
	fi
done

IFS='
'

for sth in `wget -qO- $URL1 | grep -P 'searchmatch">\[\[en:' | perl -pe 's/.*searchmatch">\[\[en://' | perl -pe 's/\]\].*//' | perl -pe 's/.*>//'`
do
	echo $sth
done

unset IFS
