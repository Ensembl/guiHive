# This is a Dockerfile to run a guiHive server in a container
#
# docker build -t guihive .
#
# docker run -p 8081:8080 -it guihive		## Start the server. Port mapping = external:internal
# docker run -p 8082:8080 -it guihive bash	## If you need to do any prior maintenance/tuning - do it in bash, then manually run the CMD below.

FROM ubuntu:16.04

RUN mkdir /guihive_all

RUN apt-get update -y \
 && apt-get install git golang curl sqlite3 mysql-client libmariadb-client-lgpl-dev libpq-dev libexpat1-dev graphviz -y \
 && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# RUN apt-get install vim perl-doc iputils-ping net-tools apt-file -y

RUN ln -s /usr/bin/mariadb_config /usr/bin/mysql_config

RUN curl -L https://cpanmin.us | perl - App::cpanminus

RUN cd /guihive_all ; git clone https://github.com/Ensembl/ensembl-hive.git

RUN cd /guihive_all ; git clone https://github.com/Ensembl/guiHive.git

RUN cd /guihive_all/ensembl-hive ; git checkout master

RUN cpanm --installdeps --with-recommends /guihive_all/ensembl-hive

RUN cpanm --installdeps --with-recommends /guihive_all/guiHive

RUN /guihive_all/guiHive/guihive-deploy.sh

RUN cd /guihive_all/guiHive/server ; go build

EXPOSE 8080

CMD [ "/guihive_all/guiHive/server/server" ]
