package main

import (
	"fmt"
	"net/http"
	"log"
	"os/exec"
	"encoding/json"
	"bytes"
)

func checkError (s string, err error, ss ...string) {
	if err != nil {
		log.Fatalf("%s: %s [%s]\n",s, err, ss)
	}
}

func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hi there, I love %s!", r.URL.Path[1:])
}

func scriptHandler(w http.ResponseWriter, r *http.Request) {
	err := r.ParseForm()
	checkError("Can't parse Form", err)

	log.Println("METHOD: ", r.Method)
	log.Println("URL: ", r.URL)
	log.Println("FRAGMENT: ", r.URL.Fragment)
	log.Println("PATH: ", r.URL.Path)
	log.Println("BODY: ", r.Body)
	log.Println("URL2: ", r.Form)

	var outMsg bytes.Buffer
	var errMsg bytes.Buffer

	fname := ".." + r.URL.Path
	args, err := json.Marshal(r.Form)
	checkError("Can't Marshal JSON:", err)
	log.Printf("ARGS in Go side: %s", args)

	log.Println("EXECUTING SCRIPT: ", fname)
	cmd := exec.Command(fname, string(args))
	cmd.Stdout = &outMsg
	cmd.Stderr = &errMsg

	if err := cmd.Start(); err != nil {
		log.Fatal("Error Starting Command: ", err)
	}
	if err := cmd.Wait(); err != nil {
		log.Fatal("Error Executing Command: ", err)
	}
	
	log.Printf("OUTMSG: %s", outMsg.Bytes())
	log.Printf("ERRMSG: %s", errMsg.Bytes())
	fmt.Fprintf(w, string(outMsg.Bytes()))
	
}

func main() {
	relPath := ".."
	http.HandleFunc("/",         handler)
	http.Handle("/static/",      http.FileServer(http.Dir(relPath)))
	http.Handle("/styles/",      http.FileServer(http.Dir(relPath)))
	http.Handle("/javascript/",  http.FileServer(http.Dir(relPath)))
	http.Handle("/images/",      http.FileServer(http.Dir(relPath)))
	http.HandleFunc("/scripts/", scriptHandler)
	err := http.ListenAndServe(":12345", nil)
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}
