// Copyright 2012 Miguel Pignatelli. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package main

import (
	"fmt"
	"net/http"
	"log"
	"os"
	"os/exec"
	"encoding/json"
	"bytes"
	"flag"
)

var (
	port string
)



func init () {
	flag.StringVar(&port, "port", "12345", "Port to listen (defaults to 12345)")
	flag.Parse()
}

func checkError (s string, err error, ss ...string) {
	if err != nil {
		log.Printf("%s: %s [%s]\n",s, err, ss)
	}
}

func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hi there, I love %s!", r.URL.Path[1:])
}

func scriptHandler(w http.ResponseWriter, r *http.Request) {
	err := r.ParseForm()
	checkError("Can't parse Form", err)

	debug("METHOD: %s", r.Method)
	debug("URL: %s", r.URL)
	debug("FRAGMENT: %s", r.URL.Fragment)
	debug("PATH: %s", r.URL.Path)
	debug("BODY: %s", r.Body)
	debug("URL2: %s", r.Form)

	var outMsg bytes.Buffer
	var errMsg bytes.Buffer

	fname := ".." + r.URL.Path
	args, err := json.Marshal(r.Form)
	checkError("Can't Marshal JSON:", err)
	debug("ARGS in Go side: %s", args)

	debug("EXECUTING SCRIPT: %s", fname)
	cmd := exec.Command(fname, string(args))
	cmd.Stdout = &outMsg
	cmd.Stderr = &errMsg

	if err := cmd.Start(); err != nil {
		log.Println("Error Starting Command: ", err)
	}
	if err := cmd.Wait(); err != nil {
		log.Println("Error Executing Command: ", err)
	}
	
	debug("OUTMSG: %s", outMsg.Bytes())
	debug("ERRMSG: %s", errMsg.Bytes())
	fmt.Fprintf(w, string(outMsg.Bytes()))
	
}

func setEnvVar() error {
	workingDirectory, err := os.Getwd()
	if err != nil {
		return err
	}
	debug("WORKING_DIRECTORY: %s\n", workingDirectory)

	// PER5LIB
	perl5lib := os.Getenv("PERL5LIB")
	if perl5lib == "" {
		perl5lib = fmt.Sprintf("%s../scripts/lib", workingDirectory)
	} else {
		perl5lib = fmt.Sprintf("%s:%s/../scripts/lib", perl5lib, workingDirectory)
	}
	debug("PERL5LIB: %s\n", perl5lib)
	err = os.Setenv("PERL5LIB", perl5lib)
	if err != nil {
		return err
	}

	//GUIHIVE_BASEDIR
	if err := os.Setenv("GUIHIVE_BASEDIR", fmt.Sprintf("%s/../", workingDirectory)); err != nil {
		return err
	}
	// TODO: Unset && clean on exit??
	debug("GUIHIVE_BASEDIR: %s", os.Getenv("GUIHIVE_BASEDIR"))

	return nil
}

func main() {

	//  Fix environmental variables
	errV := setEnvVar()
	checkError("Problem setting environmental variables: ", errV);

	relPath := ".."
	http.HandleFunc("/",         handler)
	http.Handle("/static/",      http.FileServer(http.Dir(relPath)))
	http.Handle("/styles/",      http.FileServer(http.Dir(relPath)))
	http.Handle("/javascript/",  http.FileServer(http.Dir(relPath)))
	http.Handle("/images/",      http.FileServer(http.Dir(relPath)))
	http.HandleFunc("/scripts/", scriptHandler)
	debug("Listening to port: %s", port)
	err := http.ListenAndServe(":"+port, nil)
	checkError("ListenAndServe ", err)
}
