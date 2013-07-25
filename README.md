## guiHive -- Graphic user interface for the eHive production system

This repository contains the guiHive code, a graphic user interface to easily interact with the eHive production system.

### Status

This code is being actively developed. Improvements are being added regularly (mainly in documentation and error reporting), so regular updates of the repo is recommended.


### Installation

#### Pre-requisites

In order to work with this application you need the following installed in your system:

* Git client       : To clone this repository (http://git-scm.com/downloads).
* eHive API        : If you require to download and install the eHive system, please follow these instructions: (http://www.ensembl.org/info/docs/eHive/installation.html). Note that the guiHive is in sync with the latest (stable) eHive code. Please, also note that all the eHive dependecies have to be met (i.e. the ensembl-core API, etc)
* Go tools         : The server of guiHive is written in the Go programming language. Since the current guiHive version doesn't include binaries for the server you will need to compile it.

#### Compilation

Once you have all the dependencies installed and up to date (specially the eHive code) follow these steps:

* Clone the guiHive repository (if you haven't done yet) and cd into it.

* Set the GUIHIVE_BASEDIR environmental variable to point to your guiHive/src folder. Something like this should work:
     $ export GUIHIVE_BASEDIR=$PWD
(Note: To make this change permanent include the $GUIHIVE_BASEDIR variable in your ~/.bashrc or ~/.profile file)

* cd into the "server" folder and build the web server
     $ cd $GUIHIVE_BASEDIR/server
     $ go build

* This will create the "server" executable in the current directory

#### Running

* Execute the server:
    $ ./server

* Open your preferred browser (check the browser compatibility below first!) and go to the following URL:
   127.0.0.1:8080
(Note: The 8080 port is the default one used by guiHive, you can change it when invoking the server executable using the -port option)

You should now be able to connect to your database and start monitoring your pipeline.


### Browser compatibility

All the 3rd party libraries used in guiHive are supposed to work in reasonably recent versions of the good most used web browsers. IE>=9 should also work. If you experience any problem, please, send your comments to mp@ebi.ac.uk

AFAIK everything works fine in Firefox (v7.0.1, v8.0.1, v12.0, v18.0.1), Chrome (v24.0.1312.56), Safari (v5.1.7) and Opera (v12.12).
Note on Firefox: Firefox has experienced a regression in SVG performance (around version 18). Several bugs have been solved lately, making its performance comparable to Chrome (version 24-nightly).

