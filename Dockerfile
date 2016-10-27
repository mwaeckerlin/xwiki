FROM ubuntu:latest
MAINTAINER mwaeckerlin

ENV TARGET ROOT
ENV DATA_BASE /var/lib/tomcat7
ENV TARGETPATH ${DATA_BASE}/webapps/${TARGET]

RUN apt-get update -y
RUN apt-get install -y wget xml2 unzip postgresql-client pwgen tomcat7 libpostgresql-jdbc-java libmysql-java nmap
RUN apt-get install -y mysql-client-5.5

WORKDIR /usr/share/tomcat7/lib
RUN ln -s ../../java/mysql-connector-java.jar .
RUN ln -s ../../java/postgresql-jdbc4-*.jar .
RUN rm -rf ${TARGETPATH}

USER tomcat7
WORKDIR ${DATA_BASE}/webapps
RUN wget -qO/tmp/xwiki.war \
    http://download.forge.ow2.org/xwiki/$(wget -qO- http://download.forge.ow2.org/xwiki \
                                          | html2 \
                                          | sed -n 's,/html/body/pre/a/@href=\(xwiki-enterprise-web-[0-9]\+.[0-9]\+.[0-9]\+.war\),\1,p' \
                                          | sort | tail -1)
RUN ! test -e ${TARGETPATH} || rm -rf ${TARGETPATH}
RUN unzip /tmp/xwiki.war -d ${TARGETPATH}
RUN rm /tmp/xwiki.war
RUN cp /usr/share/java/postgresql-jdbc4-*.jar ${TARGETPATH}/WEB-INF/lib/

USER root
RUN apt-get autoremove --purge -y wget xml2 unzip

USER tomcat7
VOLUME ${DATA_BASE}
EXPOSE 8080
ADD start.sh /start.sh
CMD /start.sh
