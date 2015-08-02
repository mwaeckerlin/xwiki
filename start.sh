#!/bin/bash -ex

if [ -n "${SQL_ENV_MYSQL_ROOT_PASSWORD}" ]; then

    # MySQL

    if [ -z "${SQL_ENV_MYSQL_ROOT_PASSWORD}" -o \
        -z "${SQL_PORT_3306_TCP_ADDR}" -o \
        -z "${SQL_PORT_3306_TCP_PORT}" ]; then
        echo "You must link to a MY SQL container with --link <container>:mysql" \
            1>&2
        exit 1
    fi

    # wait for mysql to become ready
    for ((i=0; i<20; ++i)); do
        if nmap -p ${SQL_PORT_3306_TCP_PORT} ${SQL_PORT_3306_TCP_ADDR} \
            | grep -q ${SQL_PORT_3306_TCP_PORT}'/tcp open'; then
            break;
        fi
        sleep 1
    done

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

elif [ -n "${SQL_ENV_POSTGRES_PASSWORD}" ]; then

    # PostgreSQL
    
    if [ -z "${SQL_ENV_POSTGRES_PASSWORD}" -o \
        -z "${SQL_PORT_5432_TCP_ADDR}" -o \
        -z "${SQL_PORT_5432_TCP_PORT}" ]; then
        echo "You must link to an SQL container (mysql or postgres) with --link <container>:postgres" \
            1>&2
        exit 1
    fi
    
    # wait for postgres to become ready
    for ((i=0; i<20; ++i)); do
        if nmap -p ${SQL_PORT_5432_TCP_PORT} ${SQL_PORT_5432_TCP_ADDR} \
            | grep -q ${SQL_PORT_5432_TCP_PORT}'/tcp open'; then
            break;
        fi
        sleep 1
    done
    
    if test $(PGPASSWORD=${SQL_ENV_POSTGRES_PASSWORD} psql -lqt -U postgres -h sql | cut -d \| -f 1 | grep -w xwiki | wc -l) -eq 0; then
        echo "**** Setup Database (first run)"
        MY_SQL_PASSWD=$(pwgen -s 16 1)
        PGPASSWORD=${SQL_ENV_POSTGRES_PASSWORD} psql -U postgres -h sql -c "create database xwiki with owner=postgres encoding='unicode' TABLESPACE=pg_default;"
        PGPASSWORD=${SQL_ENV_POSTGRES_PASSWORD} psql -U postgres -h sql --dbname=xwiki -c "create user xwiki password '${MY_SQL_PASSWD}' valid until 'infinity'"
        PGPASSWORD=${SQL_ENV_POSTGRES_PASSWORD} psql -U postgres -h sql --dbname=xwiki -c "grant all on schema public to xwiki"
    fi
    if ! grep -q jdbc:postgresql://sql/xwiki /var/lib/tomcat7/webapps/${XWIKI_ROOT}/WEB-INF/hibernate.cfg.xml; then
        sed '/<!-- PostgreSQL configuration./,/-->/{   # find commented out Postgres block
           /-->/d;                            # move end of comment from end of block ...
           0,/^ *$/s//    -->\n\n/            # ... to the first empty line
           s,jdbc:postgresql:xwiki,jdbc:postgresql://sql/xwiki,                  # fix database host
           s,connection.password">xwiki,connection.password">'${MY_SQL_PASSWD}', # fix sql password
         };
         /<!-- Configuration for the default database/,/<!--/{ # find enabled first database block
           /-->/d;                            # move end of comment from end of block ...          
           0,/<!--/!s,.*<!--,    -->\n\n\n&,  # ... before begin of next block
         }
        ' -i.bak /var/lib/tomcat7/webapps/${XWIKI_ROOT}/WEB-INF/hibernate.cfg.xml
    fi
    
else
    
    echo "Please link to a database container, either mysql or postgres."
    echo "A postgres container must be setup with a password variable."
    exit 1
  
fi

if ! grep -q environment.permanentDirectory /var/lib/tomcat7/webapps/${XWIKI_ROOT}/WEB-INF/xwiki.properties; then
fi

echo "**** Run Tomcat"
CATALINA_HOME=/usr/share/tomcat7 CATALINA_TMPDIR=/tmp CATALINA_BASE=/var/lib/tomcat7 /usr/share/tomcat7/bin/catalina.sh run
