## guiHive -- Graphic user interface for the eHive production system

This repository contains the guiHive code, a graphic user interface to easily interact with the eHive production system.

### Status

This code is being actively developed. Improvements are being added regularly (mainly in documentation and error reporting), so regular updates of the repo are recommended.


### Installation

#### Pre-requisites

In order to work with this application you need the following installed in your system:

* Git client           : To clone this repository (http://git-scm.com/downloads).
* eHive API            : If you require to download and install the eHive system, please follow these instructions: (http://www.ensembl.org/info/docs/eHive/installation.html). Note that the guiHive is in sync with the latest (stable) eHive code.
   * Ensembl API       : eHive depends on the core Ensembl API. BioPerl or any other Ensembl related checkout are not needed
   * GraphViz          : eHive depends on dot (from GraphViz) to create the graphical representation of the pipelines. The Perl package GraphViz is also needed.
* Go tools             : The server of guiHive is written in the Go programming language. Since the current guiHive version doesn't include binaries for the server you will need to compile it.
* Misc Perl Modules    : Several Perl modules are needed by guiHive:
   * JSON
   * JSON::PP
   * URI::Escape
   * HTML::Template

There is a script in the guiHive root directory called "test_dep.pl" that tests all the dependencies. You can run it whithout arguments:
$ perl test_dep.pl
If you experience problems setting up guiHive you can also follow the tips printed at the end of that script.

#### Compilation

Once you have all the dependencies installed and up to date (specially the eHive code) follow these steps:

* Clone the guiHive repository (if you haven't done yet) and cd into it.

* cd into the "server" folder and build the web server
     $ cd server
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

