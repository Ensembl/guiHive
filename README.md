## guiHive -- Graphic user interface for the eHive production system

This repository contains the guiHive code, a graphic user interface to easily interact with your eHive pipeline.
See https://github.com/Ensembl/ensembl-hive for more information about the eHive system.

### Status

This code is being actively developed. Improvements, new features and bug fixes are being added regularly, so if you use it, please remember to check for updates regularly (or "watch" the github repo to get notification of updates). It is also recommended that you join the hive-users mailing list (see https://github.com/Ensembl/ensembl-hive for more information on how to do this) since news and updates will be announced there.

guiHive consists of:

* A web interface that can be run in any modern web browser (see the "Browser compatibility" section below).
* A web server that connects the web interface with the hive code that interacts with your hive database.
* A Perl layer that gathers information from your pipeline (using the eHive API) and returns it to the web server and interface.

### Installation

#### Pre-requisites

guiHive depends on the following components that need to be installed in your system:

* Git client           : To clone this repository (http://git-scm.com/downloads).
* eHive API            : guiHive depends on the eHive API. You can download the latest code from github (https://github.com/Ensembl/ensembl-hive).
   * Ensembl API       : eHive depends on the core Ensembl API. BioPerl or any other Ensembl related checkouts are not needed.
   * GraphViz          : eHive depends on dot (from GraphViz) to create the graphical representation of the pipelines. The Perl package GraphViz is also needed.
* Go tools             : The server of guiHive is written in the Go programming language. Since the current guiHive version doesn't include binaries for the server you will need to compile it.
                         Please refer to the Go website (http://golang.org) for installation instructions.
* Misc Perl Modules    : Several Perl modules are needed by guiHive:
   * JSON
   * JSON::PP
   * URI::Escape
   * HTML::Template

There is a script in the guiHive root directory called "test_dep.pl" that tests all the dependencies. To run it:
$ perl test_dep.pl
If you experience problems setting up guiHive you can also follow the tips printed at the end of that script.

#### Compilation

Once you have all the dependencies installed and up to date follow these steps:

* Clone the guiHive repository (if you haven't done yet) and cd into it.
  $ git clone https://github.com/Ensembl/guiHive

* cd into the "server" folder and build the web server
     $ cd guiHive/server
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

guiHive and all the 3rd party libraries used in guiHive are supposed to work in reasonably recent versions of the mainstream web browsers. IE>=9 should also work but I haven't tested. If you experience any problem, please send your comments to hive-users@ebi.ac.uk

AFAIK everything works fine in Firefox (v7.0.1, v8.0.1, v12.0, v18.0.1), Chrome (v24.0.1312.56), Safari (v5.1.7) and Opera (v12.12).

### Feedback

Feedback is more than welcome.
Please send your bug reports to the hive mailing list (hive-users@ebi.ac.uk).

