LANG=ko_KR.utf8
UTIL='expr wget date sed perl grep'
URL1='https://ko.wikipedia.org/w/index.php?title=%ED%8A%B9%EC%88%98:%EA%B2%80%EC%83%89&limit=5000&offset=0&profile=default&search=insource%3A%2F%5C%5B%5C%5B%28en%7Cceb%7Csv%7Cde%7Cfr%7Cnl%7Cru%7Ces%7Cit%7Cpl%7Cwar%7Cvi%7Cja%7Czh%7Cpt%7Cuk%7Cfa%7Car%7Csr%7Cca%7Cno%7Csh%7Cfi%7Cid%7Chu%7Cko%7Ccs%7Cro%7Cms%7Ctr%7Ceu%7Ceo%7Chy%7Cbg%7Cda%7Che%7Czh-min-nan%7Csk%7Ckk%7Cmin%7Cce%7Chr%7Clt%7Cet%7Csl%7Cbe%7Cel%7Cgl%7Cur%7Cnn%7Csimple%7Caz%7Cuz%7Cla%7Cth%7Chi%7Cka%7Cvo%7Cta%7Cazb%7Ccy%7Cmk%7Ctg%7Cast%7Clv%7Cmg%7Coc%7Ctt%7Ctl%7Cky%7Cbs%7Csq%7Cnew%7Cte%7Czh-yue%7Cbr%7Cbe-tarask%7Cpms%7Caf%7Cbn%7Cml%7Cjv%7Clb%7Cht%29%3A%2F'
URL2='https://ko.wikipedia.org/w/index.php?title=%ED%8A%B9%EC%88%98:%EA%B2%80%EC%83%89&limit=5000&offset=0&profile=default&search=insource%3A%2F%5C%5B%5C%5B%28sco%7Cmr%7Cga%7Cpnb%7Csw%7Cis%7Cba%7Ccv%7Cfy%7Cmy%7Csu%7Clmo%7Cnds%7Can%7Cyo%7Cne%7Cpa%7Cgu%7Cio%7Cbar%7Cscn%7Cals%7Cbpy%7Ckn%7Cku%7Cckb%7Cia%7Cqu%7Carz%7Cmn%7Cbat-smg%7Csi%7Cgd%7Cwa%7Cnap%7Cyi%7Cam%7Cor%7Cbug%7Ccdo%7Cwuu%7Cmap-bms%7Chsb%7Cmai%7Cfo%7Cmzn%7Cxmf%7Cli%7Csah%7Cilo%7Csa%7Cvec%7Ceml%7Cos%7Csd%7Cmrj%7Cmhr%7Chif%7Croa-tara%7Cps%7Cdiq%7Chak%7Cpam%7Czh-classical%7Cbcl%7Cnso%7Cfrr%7Cszl%7Cace%7Cse%7Cmi%7Cnah%7Cnds-nl%29%3A%2F'
URL3='https://ko.wikipedia.org/w/index.php?title=%ED%8A%B9%EC%88%98:%EA%B2%80%EC%83%89&limit=5000&offset=0&profile=default&search=insource%3A%2F%5C%5B%5C%5B%28km%7Crue%7Cbh%7Cvls%7Cgan%7Cnv%7Cso%7Ccrh%7Csc%7Cbo%7Cvep%7Cglk%7Cco%7Ctk%7Cfiu-vro%7Clrc%7Cmyv%7Ckv%7Ccsb%7Cas%7Cgv%7Cudm%7Czea%7Cay%7Cug%7Cie%7Cnrm%7Csn%7Cstq%7Clez%7Cpcd%7Ckw%7Clad%7Cmwl%7Cgn%7Crm%7Cgom%7Ckoi%7Clij%7Cab%7Cmt%7Cfur%7Cdsb%7Cfrp%7Chaw%7Cang%7Cln%7Cdv%7Cext%7Ccbk-zam%7Clo%7Cdty%7Clfn%7Ckab%7Cksh%7Cgag%7Colo%7Cpag%7Cpi%7Cpfl%7Cav%7Cbxr%7Cxal%7Ckrc%7Cpap%7Cha%7Ckaa%7Cza%7Cbjn%7Cpdc%7Crw%7Cgor%7Ctyv%7Cto%7Ckl%7Cnov%29%3A%2F'
URL4='https://ko.wikipedia.org/w/index.php?search=insource%3A%2F%5C%5B%5C%5B%28jam%7Carc%7Ckbd%7Ctpi%7Ckbp%7Ctet%7Cig%7Cki%7Cna%7Cjbo%7Clbe%7Croa-rup%7Cty%7Cmdf%7Ckg%7Cbi%7Cwo%29%3A%2F&title=%ED%8A%B9%EC%88%98%3A%EA%B2%80%EC%83%89&go=%EB%B3%B4%EA%B8%B0'
URL5='https://ko.wikipedia.org/w/index.php?search=insource%3A%2F%5C%5B%5C%5B%28lg%7Csrn%7Czu%7Ctcy%7Cchr%7Cltg%7Csm%7Cinh%7Com%7Cxh%7Cpih%7Ccu%7Crmy%7Ctw%7Cbm%7Ctn%7Crn%7Cchy%7Catj%7Cgot%7Ctum%7Cts%7Cak%7Cst%7Cch%7Cpnt%7Cny%7Css%7Cfj%7Cady%7Ciu%7Csat%7Cee%7Cks%7Cve%7Cik%7Csg%7Cff%7Cdz%7Cti%7Ccr%29%3A%2F&title=%ED%8A%B9%EC%88%98%3A%EA%B2%80%EC%83%89&go=%EB%B3%B4%EA%B8%B0'

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
for sth in `( out $URL1 && out $URL2 && out $URL3 && out $URL4 && out $URL5 ) | sort -u`
do
	echo "| $CNT || [[$sth]]"
	echo "|-"
	CNT=`expr $CNT + 1`
done
echo "|}"

unset IFS

