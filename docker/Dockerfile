# This is a Dockerfile to run a guiHive server in a container
#
# docker build -t guihive .
#
# docker run --name guihive_server -p 8081:8080 -d guihive	## Start the server. Port mapping = external:internal
# docker run -p 8082:8080 -it guihive bash			## If you need to do any prior maintenance/tuning - do it in bash, then manually run the CMD below.

FROM ensemblorg/ensembl-hive

# Install common utilities and known guiHive Perl dependencies with apt (faster than CPAN)
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
 && apt-get install curl git libhtml-parser-perl libhtml-template-perl libjson-perl libjson-pp-perl liburi-perl -y \
 && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ARG DEPLOY_LOCATION=/repo/guiHive
RUN curl -L https://raw.githubusercontent.com/Ensembl/guiHive/server/guihive-deploy.sh | bash

# Install guiHive and eHive Perl dependencies (across *all* versions) using eHive's helper scripts
ARG EHIVE_TMP_CHECKOUT=$DEPLOY_LOCATION/ensembl-hive-tmp
RUN mkdir $EHIVE_TMP_CHECKOUT \
    && GIT_DIR=$DEPLOY_LOCATION/clones/ensembl-hive GIT_WORK_TREE=$EHIVE_TMP_CHECKOUT git checkout -qf master \
    && $EHIVE_TMP_CHECKOUT/docker/setup_cpan.Ubuntu-16.04.sh $DEPLOY_LOCATION $DEPLOY_LOCATION/ensembl-hive/* \
    && rm -rf $EHIVE_TMP_CHECKOUT

# Wrap the compilation phase with apt-get install/purge to keep the image small
RUN buildDeps=' \
      golang \
    ' \
    && apt-get update -y \
    && apt-get install -y $buildDeps \
    && rm -rf /var/lib/apt/lists/* \
    && cd $DEPLOY_LOCATION/server && go build \
    && apt-get purge -y --auto-remove $buildDeps

EXPOSE 8080

CMD [ "/repo/guiHive/server/server" ]
