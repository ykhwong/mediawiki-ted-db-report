LANG=ko_KR.utf8
UTIL='mysql'
HOST=kowiki.analytics.db.svc.eqiad.wmflabs
DBNAME=kowiki_p
DEFAULT_FILE='~/replica.my.cnf'
MYSQL_CMD="mysql --defaults-file=$DEFAULT_FILE -h $HOST $DBNAME"
USERID=A.TedBot

for cmd in $UTIL
do
        $cmd --help 1>/dev/null 2>/dev/null
        RETCODE=$?
        if [ $RETCODE -ne 0 ]; then
                echo "The following utility is not available: $cmd"
                exit $RETCODE
        fi
done

ACTOR_ID=$(echo 'SELECT actor_id from actor where actor_name='"'${USERID}'"' LIMIT 1;' | $MYSQL_CMD | tail -1)
RETCODE=$?
if [ $RETCODE -ne 0 ]; then
	exit $RETCODE
fi

echo "SELECT DISTINCT page_namespace AS \`namespace\`, 'rev' AS \`type\`, page_title, page_is_redirect, page_len
FROM page JOIN revision ON page_id = rev_page WHERE rev_actor = ${ACTOR_ID} AND rev_parent_id = '0' AND page_namespace = '0' AND page_is_redirect = '0'
ORDER BY rev_timestamp DESC;" | $MYSQL_CMD
