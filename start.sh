#!/bin/bash -ex

if ! mysqlshow -u root --password=${SQL_ENV_MYSQL_ROOT_PASSWORD} -h sql xwiki; then
    echo "**** Setup Database (first run)"
    MY_SQL_PASSWD=$(pwgen -s 16 1)
    mysql -u root --password=${SQL_ENV_MYSQL_ROOT_PASSWORD} -h sql -e "create database xwiki default character set utf8 collate utf8_bin"
    mysql -u root --password=${SQL_ENV_MYSQL_ROOT_PASSWORD} -h sql -e "grant all privileges on *.* to xwiki@'%' identified by '${MY_SQL_PASSWD}'"
fi
if ! grep -q jdbc:mysql://sql/xwiki /var/lib/tomcat7/webapps/${XWIKI_ROOT}/WEB-INF/hibernate.cfg.xml; then
    sed '/<!-- MySQL configuration./,/-->/{   # find commented out MySQL block
           /-->/d;                            # move end of comment from end of block ...
           0,/^ *$/s//    -->\n\n/            # ... to the first empty line
           s,jdbc:mysql://localhost/xwiki,jdbc:mysql://sql/xwiki,                # fix database host
           s,connection.password">xwiki,connection.password">'${MY_SQL_PASSWD}', # fix sql password
         };
         /<!-- Configuration for the default database/,/<!--/{ # find enabled first database block
           /-->/d;                            # move end of comment from end of block ...          
           0,/<!--/!s,.*<!--,    -->\n\n\n&,  # ... before begin of next block
         }
        ' -i.bak /var/lib/tomcat7/webapps/${XWIKI_ROOT}/WEB-INF/hibernate.cfg.xml
fi

echo "**** Run Tomcat"
CATALINA_HOME=/usr/share/tomcat7 CATALINA_TMPDIR=/tmp CATALINA_BASE=/var/lib/tomcat7 /usr/share/tomcat7/bin/catalina.sh run
