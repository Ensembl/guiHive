/* Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
/* Copyright [2016] EMBL-European Bioinformatics Institute

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/


package main

import (
	"strings"
	"bytes"
	"regexp"
	"strconv"
	"sort"
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
	projectDirName = "github.com/Ensembl/guiHive"
)

var (
	port string
	isVersion = regexp.MustCompile(`^[0-9]+$`)
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

// Sortable os.fileInfos by name (-> num)
type sortableFiles []os.FileInfo
func (s sortableFiles) Len () int {
	return len(s)
}
func (s sortableFiles) Less (i, j int) bool {
	iVer, err := strconv.Atoi(s[i].Name())
	checkError(fmt.Sprintf("Dir name %s can't be converted to int", s[i].Name()), err)
	jVer, err := strconv.Atoi(s[j].Name())
	checkError(fmt.Sprintf("Dir name %s can't be converted to int", s[j].Name()), err)
	return iVer < jVer;
}
func (s sortableFiles) Swap (i, j int) {
	s[i], s[j] = s[j], s[i]
}

// Return the version number defined in the URL, or the latest available eHive version
func parseVersion(r *http.Request) string {
	parts := strings.SplitN(r.URL.Path, "/", 4)
	version := parts[2]
	if (isVersion.MatchString(version)) {
		return version
	} else {
		path := os.Getenv("GUIHIVE_PROJECTDIR") + "/versions/"
		dir, err := os.Open(path)
		checkError("Can't open dir " + path, err)
		files, err := dir.Readdir(-1)
		checkError("Can't read dir " + path, err)
		sort.Sort(sortableFiles(files))
		version = files[len(files)-1].Name()
		debug("Will use the latest version %s", version)
		return version
	}
	return ""
}

func unknown(w http.ResponseWriter, r *http.Request) {
	version := parseVersion(r)
	fmt.Fprintln(w, r.URL)
	fmt.Fprintf(w, "version %s is currently not supported by guiHive\n", version)
}

func scriptHandler(w http.ResponseWriter, r *http.Request) {
	err := r.ParseForm()
	defer r.Body.Close()
	checkError("Can't parse Form: ", err)

	debug("METHOD: %s", r.Method)
	debug("URL: %s", r.URL)

	var outMsg bytes.Buffer
	var errMsg bytes.Buffer

	fname := os.Getenv("GUIHIVE_PROJECTDIR") + r.URL.Path
	args, err := json.Marshal(r.Form)
	checkError("Can't Marshal JSON:", err)

	debug("EXECUTING SCRIPT: %s", fname)
	debug("ARGS: %s", args)
	version := parseVersion(r);
	debug("VERSION: %s", version)

	versionRootDir := os.Getenv("GUIHIVE_PROJECTDIR") + "/versions/" + version + "/";
	ehiveRootDir := os.Getenv("GUIHIVE_PROJECTDIR") + "/ensembl-hive/" + version + "/";
	ehiveRootLib := ehiveRootDir + "/modules"
	guihiveRootLib := versionRootDir + "/scripts/lib"
	newPerl5Lib  := addPerl5Lib(ehiveRootLib + ":" + guihiveRootLib)

	debug("EHIVE_ROOT_DIR: %s", ehiveRootDir)
	debug("NEW_PERL5LIB: %s", newPerl5Lib)
	cmd := exec.Command(fname, string(args))
	cmd.Env = make([]string,0)
	cmd.Env = append(cmd.Env, "PERL5LIB=" + newPerl5Lib)
	cmd.Env = append(cmd.Env, "EHIVE_ROOT_DIR=" + ehiveRootDir)
	cmd.Env = append(cmd.Env, "GUIHIVE_BASEDIR=" + versionRootDir)
	cmd.Env = append(cmd.Env, "PATH=" + os.Getenv("PATH"))

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
	//GUIHIVE_PROJECTDIR
	if err := os.Setenv("GUIHIVE_PROJECTDIR", projectDirectory+"/"); err != nil {
		return err
	}
	debug("PROJECT_DIRECTORY: %s\n", os.Getenv("GUIHIVE_PROJECTDIR"))

	return nil
}

func addPerl5Lib (newDir string) string {
	perl5lib := os.Getenv("PERL5LIB")
	if perl5lib == "" {
		perl5lib = newDir
	} else {
		perl5lib = newDir + ":" + perl5lib
	}
	return perl5lib
}

func main() {

	//  Fix environmental variables
	errV := setEnvVar()
	checkError("Problem setting environmental variables: ", errV)

	relPath := os.Getenv("GUIHIVE_PROJECTDIR")

	http.Handle("/", http.FileServer(http.Dir(relPath)))
	http.HandleFunc("/versions/", unknown)
	http.Handle("/styles/", http.FileServer(http.Dir(relPath)))
	http.Handle("/javascript/", http.FileServer(http.Dir(relPath)))
	http.Handle("/images/", http.FileServer(http.Dir(relPath)))
	http.HandleFunc("/scripts/", scriptHandler)

	versionRootDir := relPath + "/versions/"
	dir, terr := os.Open(versionRootDir)
	checkError("Can't open dir " + versionRootDir, terr)
	files, terr := dir.Readdir(-1)
	for _, verdir := range files {
		isvalid := true;
		if ((verdir.Mode() & os.ModeSymlink) != 0) {
			targetF, _ := os.Readlink(versionRootDir + verdir.Name())
			debug("Found a symlink from guiHive %s to version %s", verdir.Name(), targetF)
		} else if (verdir.IsDir()) {
			debug("Found guiHive version %s", verdir.Name())
		} else {
			isvalid = false
		}
		if (isvalid) {
			ehive_dir := os.Getenv("GUIHIVE_PROJECTDIR") + "/ensembl-hive/" + verdir.Name()
			_, err := os.Stat(ehive_dir)
			checkError(ehive_dir + " does not exist: ", err)
			debug("Found eHive version %s", verdir.Name())
			http.Handle(fmt.Sprintf("/versions/%s/", verdir.Name()), http.FileServer(http.Dir(relPath)))
			http.Handle(fmt.Sprintf("/versions/%s/javascript/", verdir.Name()), http.FileServer(http.Dir(relPath)))
			http.HandleFunc(fmt.Sprintf("/versions/%s/scripts/", verdir.Name()), scriptHandler)
		}
	}

	debug("Listening to port: %s", port)
	err := http.ListenAndServe(":"+port, nil)
	checkError("ListenAndServe ", err)
}
