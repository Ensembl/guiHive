# This Makefile builds and installs guihive.
#
# It is not recommended to install guihive this way.
# See the packaging directory on how to build a package instead.
#
# If DESTDIR is not set, the default directories are /usr/local/share/guihive for data and scripts,
# /usr/local/bin/guihive-server for the executable.
#
# If the dependencies are there, you can start guihive like this:
# $ export GUIHIVE_PROJECTDIR=/usr/local/share/guihive/
# $ guihive-server

SHELL = /bin/sh

prefix ?= $(DESTDIR)/usr/local
exec_prefix ?= $(prefix)
bindir ?= $(exec_prefix)/bin
datarootdir ?= $(prefix)/share
datadir ?= $(datarootdir)
BUILD_DIR = guihive

# go compiler doesn't include build id, but RPM packaging needs it
RAND = $(shell head -c20 /dev/urandom|od -An -tx1|tr -d ' \n')

build.stamp: server/server
	mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR)
	DEPLOY_LOCATION=$(BUILD_DIR) sh packaging/setup-guihive.sh
	rm -f $(BUILD_DIR)/guihive-deploy.sh
	rm -f $(BUILD_DIR)/guihive-dev-deploy.sh
	rm -f $(BUILD_DIR)/cpanfile
	rm -f $(BUILD_DIR)/test_dep.pl
	rm -f $(BUILD_DIR)/.gitignore
	rm -f $(BUILD_DIR)/guihive-dev-deploy.sh
	rm -f $(BUILD_DIR)/Makefile
	rm -rf $(BUILD_DIR)/doc
	rm -rf $(BUILD_DIR)/server
	rm -rf $(BUILD_DIR)/clones
	rm -rf $(BUILD_DIR)/docker
	rm -rf $(BUILD_DIR)/packaging
	rm -rf $(BUILD_DIR)/ensembl-hive/*/{.??*,Changelog,cpanfile,LICENSE,perlcriticrc,PULL_REQUEST_TEMPLATE.md,README.md,requirements.txt,setup.py,setup.pyc,setup.pyo,sql}
	rm -rf $(BUILD_DIR)/versions/*/{.??*,README.md,LICENSE.txt}
	find $(BUILD_DIR) -depth -name PipeConfig -type d -exec rm -rf {} \;
	find $(BUILD_DIR) -depth -name Examples -type d -exec rm -rf {} \;
	find $(BUILD_DIR) -depth -name RunnableDB -type d -exec rm -rf {} \;
	touch build.stamp

server/server: server/*.go server/*.mod
	cd server && go build -a -ldflags "-B 0x$(RAND)"

install: server/server build.stamp
	mkdir -p $(bindir)
	cp server/server $(bindir)/guihive-server
	mkdir -p $(datadir)
	cp -r $(BUILD_DIR) $(datadir)

clean:
	rm -f server/server
	rm -rf $(BUILD_DIR)
	rm -f build.stamp

.PHONY: install clean
