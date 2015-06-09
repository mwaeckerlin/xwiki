#!/bin/bash -ex

if ! mysqlshow -u root --password=${SQL_ENV_MYSQL_ROOT_PASSWORD} -h sql xwiki; then
    echo "**** Setup Database (first run)"
    MY_SQL_PASSWD=$(pwgen -s 16 1)
    mysql -u root --password=${SQL_ENV_MYSQL_ROOT_PASSWORD} -h sql -e "create database xwiki default character set utf8 collate utf8_bin"
    mysql -u root --password=${SQL_ENV_MYSQL_ROOT_PASSWORD} -h sql -e "grant all privileges on *.* to xwiki@'%' identified by '${MY_SQL_PASSWD}'"
    sed -e 's,\(<property name="connection.url">\).*\(</property>\),\1jdbc:mysql://sql/xwiki\2,' \
        -e 's,\(<property name="connection.username">\).*\(</property>\),\1xwiki\2,' \
        -e 's,\(<property name="connection.password">\).*\(</property>\),\1'${MY_SQL_PASSWD}'\2,' \
        -e 's,\(<property name="connection.driver_class">\).*\(</property>\),\1com.mysql.jdbc.Driver\2,' \
        -e 's,\(<property name="dialect">\).*\(</property>\),\1org.hibernate.dialect.MySQL5InnoDBDialect\2,' \
        -i /var/lib/tomcat7/webapps/xwiki/WEB-INF/hibernate.cfg.xml
fi

echo "**** Run Tomcat"
CATALINA_HOME=/usr/share/tomcat7 CATALINA_TMPDIR=/tmp CATALINA_BASE=/var/lib/tomcat7 /usr/share/tomcat7/bin/catalina.sh run
