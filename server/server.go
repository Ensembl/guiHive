// Copyright 2012 Miguel Pignatelli. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"go/build"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path"
	"path/filepath"
)

const (
	projectDirName = "github.com/emepyc/guiHive"
)

var (
	port string
)

func init() {
	flag.StringVar(&port, "port", "8080", "Port to listen (defaults to 8080)")
	flag.Parse()
}

func checkError(s string, err error, ss ...string) {
	if err != nil {
		log.Fatal(s, err, ss)
	}
}

func scriptHandler(w http.ResponseWriter, r *http.Request) {
	err := r.ParseForm()
	defer r.Body.Close()
	checkError("Can't parse Form: ", err)

	debug("METHOD: %s", r.Method)
	debug("URL: %s", r.URL)
	debug("PATH: %s", r.URL.Path)

	var outMsg bytes.Buffer
	var errMsg bytes.Buffer

	fname := os.Getenv("GUIHIVE_BASEDIR") + r.URL.Path
	args, err := json.Marshal(r.Form)
	checkError("Can't Marshal JSON:", err)

	debug("EXECUTING SCRIPT: %s", fname)
	debug("ARGS: %s", string(args))
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
	fmt.Fprintln(w, string(outMsg.Bytes()))

}

func pathExists(name string) bool {
	_, err := os.Stat(name)
	if os.IsNotExist(err) {
		return false
	}
	return err == nil
}

func guessProjectDir() (string, error) {
	// First, we try to find the project dir in the working directory
	serverPath := os.Args[0]
	serverDir := filepath.Dir(serverPath)
	pathToIndex := serverDir + "/../index.html"
	absPathToIndex, err := filepath.Abs(pathToIndex)
	if err != nil {
		debug("ABSPATHTOINDEX: %s\n", absPathToIndex)
		return "", err
	}
	if pathExists(absPathToIndex) {
		return path.Clean(absPathToIndex + "/.."), nil
	}
	for _, srcdir := range build.Default.SrcDirs() {
		dirName := path.Join(srcdir, projectDirName)
		fmt.Println("DIRNAME: ", dirName)
		if pathExists(dirName) {
			return dirName, nil
		}
	}
	return "", errors.New("Project directory not found")
}

func setEnvVar() error {
	projectDirectory, err := guessProjectDir()
	if err != nil {
		return err
	}
	debug("PROJECT_DIRECTORY: %s\n", projectDirectory)

	// PER5LIB
	perl5lib := os.Getenv("PERL5LIB")
	pathToLibs := path.Clean(projectDirectory + "/scripts/lib")
	if perl5lib == "" {
		perl5lib = pathToLibs
	} else {
		perl5lib = perl5lib + ":" + pathToLibs
	}
	err = os.Setenv("PERL5LIB", perl5lib)
	if err != nil {
		return err
	}
	debug("PERL5LIB: %s\n", os.Getenv("PERL5LIB"))

	//GUIHIVE_BASEDIR
	if err := os.Setenv("GUIHIVE_BASEDIR", projectDirectory+"/"); err != nil {
		return err
	}
	debug("GUIHIVE_BASEDIR: %s", os.Getenv("GUIHIVE_BASEDIR"))

	// ENSEMBL_CVS_ROOT_DIR
	ensembl_cvs_root_dir := os.Getenv("ENSEMBL_CVS_ROOT_DIR")
	if ensembl_cvs_root_dir == "" {
		return errors.New("ENSEMBL_CVS_ROOT_DIR has to be set to the ensembl")
	}
	debug("ENSEMBL_CVS_ROOT_DIR: %s", ensembl_cvs_root_dir)

	return nil
}

func main() {

	//  Fix environmental variables
	errV := setEnvVar()
	checkError("Problem setting environmental variables: ", errV)

	relPath := os.Getenv("GUIHIVE_BASEDIR")
	http.Handle("/", http.FileServer(http.Dir(relPath)))
	http.Handle("/styles/", http.FileServer(http.Dir(relPath)))
	http.Handle("/javascript/", http.FileServer(http.Dir(relPath)))
	http.Handle("/images/", http.FileServer(http.Dir(relPath)))
	http.HandleFunc("/scripts/", scriptHandler)
	debug("Listening to port: %s", port)
	err := http.ListenAndServe(":"+port, nil)
	checkError("ListenAndServe ", err)
}
