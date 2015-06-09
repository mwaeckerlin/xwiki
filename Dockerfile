FROM ubuntu:latest
MAINTAINER mwaeckerlin

RUN apt-get update -y
RUN apt-get install -y wget xml2 unzip mysql-client pwgen tomcat7 libmysql-java

WORKDIR /usr/share/tomcat7/lib
RUN ln -s ../../java/mysql-connector-java.jar .

USER tomcat7
WORKDIR /var/lib/tomcat7/webapps
RUN wget -qO/tmp/xwiki.war \
    http://download.forge.ow2.org/xwiki/$(wget -qO- http://download.forge.ow2.org/xwiki \
                                          | html2 \
                                          | sed -n 's,/html/body/pre/a/@href=\(xwiki-enterprise-web-[0-9]\+.[0-9]\+.[0-9]\+.war\),\1,p' \
                                          | sort | tail -1)
RUN unzip /tmp/xwiki.war -d /var/lib/tomcat7/webapps/xwiki
RUN rm /tmp/xwiki.war

USER root
RUN apt-get autoremove --purge -y wget xml2 unzip
USER tomcat7

VOLUME /var/lib/tomcat7
EXPOSE 8080
ADD start.sh /start.sh
CMD /start.sh
