
# Building an installable package for guiHive

This directory contains all the files required to build a package for guiHive.
Currently, this builds an RPM for CentOS 7.
Additionally, a package for Perl Proc::Daemon version 0.23 is built, since the one available in CentOS 7 is too old.

# Build requirements

## Go compiler

    sudo yum install epel-release
    sudo yum install golang

## RPM build dependencies

`sudo yum install gcc rpm-build rpm-devel rpmlint make python bash coreutils diffutils patch rpmdevtools perl-ExtUtils-CBuilder perl-Module-Build perl-Test-Simple perl-Proc-ProcessTable`

# Building the packages

    rpmdev-setuptree

This sets up the rpmbuild directories in your $HOME.

git-clone the guihive repository if you haven't yet.
Check out an appropriate branch (e.g. feature/rpm-build).

    cd dir-with-guihive-checkout
    cd ..
    mv dir-with-ehive-checkout guihive-1.0
    tar czf guihive-1.0.tgz guihive-1.0/
    mv guihive-1.0.tgz ~/rpmbuild/SOURCES/
    curl -O https://cpan.metacpan.org/authors/id/A/AK/AKREAL/Proc-Daemon-0.23.tar.gz
    mv Proc-Daemon-0.23.tar.gz ~/rpmbuild/SOURCES/
    cd guihive-1.0
    cp packaging/SPECS/* ~/rpmbuild/SPECS/
    cp packaging/SOURCES/* ~/rpmbuild/SOURCES/
    cd
    rpmbuild -ba rpmbuild/SPECS/perl-Proc-Daemon.spec
    rpmbuild -ba rpmbuild/SPECS/guihive.spec

The packages for Perl Proc::Daemon and guihive should now be ready in ~/rpmbuild/RPMS.

# Installing the packages

    sudo yum install epel-release
    sudo yum install ~/rpmbuild/RPMS/noarch/perl-Proc-Daemon-0.23-1.el7.noarch.rpm ~/rpmbuild/RPMS/x86_64/guihive-1.0-1.el7.x86_64.rpm

# Starting the server

Note that the server binary does not daemonize itself. You might want to use nohup.

    export GUIHIVE_PROJECTDIR=/usr/local/share/guihive/
    guihive-server --port=8080


