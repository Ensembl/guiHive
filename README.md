## guiHive -- Graphic user interface for the eHive production system

This repository contains the guiHive code, a graphic user interface to easily interact with your eHive pipeline.
See https://github.com/Ensembl/ensembl-hive for more information about the eHive system.

### Status

This code is being maintained by the Ensembl team. Improvements, new
features and bug fixes are being added regularly, so if you use it, please
remember to check for updates regularly (or "watch" the github repo to get
notification of updates). It is also recommended that you join the
hive-users mailing list (see https://github.com/Ensembl/ensembl-hive for
more information on how to do this) since news and updates will be
announced there.

guiHive consists of:

* A web interface that can be run in any modern web browser (see the "Browser compatibility" section below).
* A web server that connects the web interface with the hive code that interacts with your hive database.
* A Perl layer that gathers information from your pipeline (using the eHive API) and returns it to the web server and interface.

### Architecture

The application is served by a lightweight HTTP server written in GO. It
merely acts as a middle-man that calls Perl scripts on the server side upon
incoming HTTP requests and streams back their output. The Perl scripts use
eHive's Perl API to access and manipulate the database. They write their
output as JSON or HTML.

On the client side there is a single page that sends AJAX requests to the
server to populate the various tabs and panels.

Obviously, the main server must have network access to the database server
in order to manage these pipelines.

### Deployment with Docker

The fastest way to try guiHive on your own system is to use the Docker
image [ensemblorg/guihive](https://hub.docker.com/r/ensemblorg/guihive). It
ships all the dependencies and is ready to be used.

```
docker pull ensemblorg/guihive
docker run --name guihive_server -p 8081:8080 -d ensemblorg/guihive
```

This will start the guiHive server in a Docker container and make it
available on port 8081 of the host machine.

As stated above, the container must be configured to have network access to
the databases you want to interact with. This is native under Linux, but
requires additional setup on other OSes.

### Manual installation

#### Pre-requisites

guiHive depends on the following components that need to be installed in your system:

* Git client           : To clone this repository (http://git-scm.com/downloads).
* eHive API            : guiHive depends on the eHive API. You can download the latest code from github (https://github.com/Ensembl/ensembl-hive).
   * Ensembl API       : eHive depends on the core Ensembl API. BioPerl or any other Ensembl related checkouts are not needed.
   * GraphViz          : eHive depends on dot (from GraphViz) to create the graphical representation of the pipelines. The Perl package GraphViz is also needed.
* Go tools             : The server of guiHive is written in the Go programming language. Since the current guiHive version doesn't include binaries for the server you will need to compile it.
                         guiHive is incompatible with later versions of Go, and is currently known to compile with Go version 1.8.3
                         Please refer to the Go website (http://golang.org) for installation instructions.
* Misc Perl Modules    : Several Perl modules are needed by guiHive.
                         Please refer to our cpanfile (https://github.com/Ensembl/guiHive/blob/server/cpanfile).

There is a script in the guiHive root directory called `test_dep.pl` that tests all the dependencies. To run it:
``
$ perl test_dep.pl
``
If you experience problems setting up guiHive you can also follow the tips printed at the end of that script.

#### Compilation

Once you have all the dependencies installed and up to date follow these steps:

* Clone the guiHive repository (if you haven't done yet) and cd into it.
```
$ git clone https://github.com/Ensembl/guiHive
```

* cd into the "server" folder and build the web server
```
$ cd guiHive/server
$ go build
```

* This will create the "server" executable in the current directory

#### Running

* Execute the server:
```
$ ./server
```

* Open your preferred browser (check the browser compatibility below first!) and go to the following URL:
   http://127.0.0.1:8080
(Note: The 8080 port is the default one used by guiHive, you can change it when invoking the server executable using the -port option)

You should now be able to connect to your database and start monitoring your pipeline.

#### Debugging

* If you'd like to investigate a server error, it helps to kill the server and recompile it in debug mode:

```
$ go build -tags debug
```

* Then simply start it again. There will be much more debug output which may help to capture the error:
```
$ ./server
```


### Browser compatibility

guiHive and all the 3rd party libraries used in guiHive are supposed to work in reasonably recent versions of the mainstream web browsers. IE>=9 should also work but I haven't tested. If you experience any problem, please send your comments to hive-users@ebi.ac.uk

AFAIK everything works fine in Firefox (v7.0.1, v8.0.1, v12.0, v18.0.1), Chrome (v24.0.1312.56), Safari (v5.1.7) and Opera (v12.12).

### Feedback

Feedback is more than welcome.
Please send your bug reports to the hive mailing list (hive-users@ebi.ac.uk).

