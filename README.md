## guiHive -- Graphic user interface for the eHive production system

This repository contains the guiHive code, a graphic user interface to easily interact with the eHive production system.

### Status

This code is in early development. New commits are added continuosly and there is no guarantee that it compiles.

### Installation

#### Pre-requisites

In order to work with this application you need the following installed in your system:

* Git client  : To code this repository (http://git-scm.com/downloads).
* eHive API   : If you require to download and install the eHive system, please follow these instructions: (http://www.ensembl.org/info/docs/eHive/installation.html). Note that the guiHive is in sync with the latest eHive code.
* Go tools    : The server of guiHive is written in the Go programming language. Since the current guiHive version doesn't include binaries for the server you will need to compile it.

#### Compilation

Once you have all the dependencies installed and up to date (specially the eHive code) follow these steps:

* Clone the guiHive repository (if you haven't done yet) and cd into it.

* Set the GUIHIVE_BASEDIR environmental variable to point to your guiHive/src folder. Something like this should work:
     $ export GUIHIVE_BASEDIR=$PWD/src
(Note: To make this change permanent include the $GUIHIVE_BASEDIR variable in your ~/.bashrc or ~/.profile file)

* cd into guiHive/src/server and build the web server
     $ cd $GUIHIVE_BASEDIR/server
     $ go build

* This will create the "server" executable in the current directory

#### Running

* Execute the server:
    $ ./server

* Open your preferred browser (check the browser compatibility first!) and go the following URL:
   127.0.0.1:12345/static/
(Note: you can change the port when invoking the server executable using the -port option)

You shouuld now be able to connect to your database and start monitoring your pipeline.

### Browser compatibility
