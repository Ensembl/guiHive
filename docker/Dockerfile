# This is a Dockerfile to run a guiHive server in a container
#
# docker build -t guihive .
#
# docker run --name guihive_server -p 8081:8080 -d guihive	## Start the server. Port mapping = external:internal
# docker run -p 8082:8080 -it guihive bash			## If you need to do any prior maintenance/tuning - do it in bash, then manually run the CMD below.

FROM ensembl-hive

RUN apt-get update -y \
 && apt-get install golang libhtml-parser-perl libhtml-template-perl libjson-perl libjson-pp-perl liburi-perl -y \
 && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN git clone https://github.com/Ensembl/guiHive.git /repo/guiHive

RUN cpanm --installdeps --with-recommends /repo/guiHive

RUN /repo/guiHive/guihive-deploy.sh

RUN cd /repo/guiHive/server ; go build

EXPOSE 8080

CMD [ "/repo/guiHive/server/server" ]
