# This is a Dockerfile to run a guiHive server in a container
#
# docker build -t guihive -f docker/Dockerfile .
#
# docker run --name guihive_server -p 8081:8080 -d guihive	## Start the server. Port mapping = external:internal
# docker run -p 8082:8080 -it guihive bash			## If you need to do any prior maintenance/tuning - do it in bash, then manually run the CMD below.

# Build the server
FROM golang:1.17 AS go_builder
RUN apt-get update -y
ADD server /tmp/server
RUN cd /tmp/server && go build

# Deploy all the guiHive and eHive checkouts
FROM alpine AS deployer
RUN apk add git bash
ADD guihive-deploy.sh /tmp/guiHive/
RUN bash /tmp/guiHive/guihive-deploy.sh
RUN rm -rf /tmp/guiHive/clones

FROM ensemblorg/ensembl-hive

# Install common utilities and known guiHive Perl dependencies with apt (faster than CPAN)
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
 && apt-get install -y --no-install-recommends \
            libhtml-parser-perl libhtml-template-perl libjson-perl libjson-pp-perl liburi-perl \
 && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ARG DEPLOY_LOCATION=/repo/guiHive
COPY --from=deployer /tmp/guiHive $DEPLOY_LOCATION

# Install guiHive and eHive Perl dependencies (across *all* versions) using eHive's helper scripts
RUN /repo/ensembl-hive/docker/setup_cpan.Ubuntu-16.04.sh $DEPLOY_LOCATION $DEPLOY_LOCATION/ensembl-hive/*

COPY --from=go_builder /tmp/server/server $DEPLOY_LOCATION/server/

EXPOSE 8080

CMD [ "/repo/guiHive/server/server" ]
