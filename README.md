# XWiki

Running on Tomcat 7, connect to external MySQL.

## Communication

EXPOSE 8080
VOLUME /var/lib/tomcat7

## Run

  1. Create a Volume Container

        docker run --name xwiki-container --volume /var/lib/mysql mwaeckerlin/xwiki true
  2. Run a MySQL Container and connect to Volume

        docker run -d --name xwiki-mysql --volumes-from xwiki-container -e MYSQL_ROOT_PASSWORD=$(pwgen -s 16 1) mysql
  3. Run XWiki

        docker run -d --name xwiki --link xwiki-mysql:sql --volumes-from xwiki-container -p 8080:8080 mwaeckerlin/xwiki
  4. Head your browser to http://localhost:8080/xwiki
