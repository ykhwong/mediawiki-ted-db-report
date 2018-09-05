LANG=ko_KR.utf8
UTIL='mysql'
HOST=kowiki.analytics.db.svc.eqiad.wmflabs
DBNAME=kowiki_p
DEFAULT_FILE='~/replica.my.cnf'
MYSQL_CMD="mysql --defaults-file=$DEFAULT_FILE -h $HOST $DBNAME"
USERID=Ykhwong

for cmd in $UTIL
do
        $cmd --help 1>/dev/null 2>/dev/null
        RETCODE=$?
        if [ $RETCODE -ne 0 ]; then
                echo "The following utility is not available: $cmd"
                exit $RETCODE
        fi
done

REV_USER=$(echo 'SELECT REV_USER FROM `revision` WHERE REV_USER_TEXT = '"'${USERID}'"' LIMIT 1;' | $MYSQL_CMD | tail -1)
RETCODE=$?
if [ $RETCODE -ne 0 ]; then
	exit $RETCODE
fi

echo "SELECT DISTINCT page_namespace AS namespace, 'rev' AS type, page_title AS page_title,
                page_len, page_is_redirect, rev_timestamp AS rev_timestamp,
                rev_user, rev_user_text AS username, rev_len, rev_id 
            FROM "'`kowiki_p`.`page`
            JOIN `kowiki_p`.`revision_userindex` ON page_id = rev_page'"
            WHERE  rev_user = '${REV_USER}' AND rev_timestamp > 1
            AND rev_parent_id = '0'  AND page_namespace = '0'
            AND page_is_redirect = '0' 
            ORDER BY rev_id DESC
;" | $MYSQL_CMD

