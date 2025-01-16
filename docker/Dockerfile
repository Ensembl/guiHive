# This is a Dockerfile to run a guiHive server in a container
#
# docker build -t guihive -f docker/Dockerfile .
#
# docker run --name guihive_server -p 8081:8080 -d guihive	## Start the server. Port mapping = external:internal
# docker run -p 8082:8080 -it guihive bash			## If you need to do any prior maintenance/tuning - do it in bash, then manually run the CMD below.

# Build the server
FROM golang:1.22 AS go_builder
RUN apt-get update -y
ADD server /tmp/server
RUN cd /tmp/server && go build

# Deploy all the guiHive and eHive checkouts
FROM ubuntu:noble AS deployer
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
 && apt-get install -y --no-install-recommends git build-essential ca-certificates cpanminus 
ADD guihive-deploy.sh /tmp/guiHive/guihive-deploy.sh
RUN /tmp/guiHive/guihive-deploy.sh

FROM ubuntu:noble
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
 && apt-get install -y --no-install-recommends \
            graphviz ca-certificates \
            libhtml-parser-perl libhtml-template-perl libjson-perl libjson-pp-perl liburi-perl \
            libdbi-perl libdbd-sqlite3-perl libdbd-mysql-perl libcapture-tiny-perl \
            libdatetime-perl libproc-daemon-perl libemail-stuffer-perl libdatetime-format-iso8601-perl \
            libgetopt-argvfile-perl libbsd-resource-perl libchart-gnuplot-perl libgraphviz-perl \
 && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
# requires 'Time::Piece'; requires 'IPC::Cmd'; are already included in ubuntu:noble
ARG DEPLOY_LOCATION=/repo/guiHive
COPY --from=deployer /tmp/guiHive $DEPLOY_LOCATION
COPY --from=go_builder /tmp/server/server $DEPLOY_LOCATION/server/

EXPOSE 8080
CMD [ "/repo/guiHive/server/server" ]
