package main

import (
	"fmt"
	"net/http"
	"log"
	"os/exec"
	"encoding/json"
	"bytes"
)

func checkError (err error) {
	if err != nil {
		log.Fatal(err)
	}
}

func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hi there, I love %s!", r.URL.Path[1:])
}

func scriptHandler(w http.ResponseWriter, r *http.Request) {
	err := r.ParseForm()
	checkError(err)

	log.Println("METHOD: ", r.Method)
	log.Println("URL: ", r.URL)
	log.Println("FRAGMENT: ", r.URL.Fragment)
	log.Println("PATH: ", r.URL.Path)
	log.Println("BODY: ", r.Body)
	log.Println("URL2: ", r.Form)
	log.Println("FORM: ", r.Form.Get("url"))

	var outMsg bytes.Buffer
	var errMsg bytes.Buffer

	fname := ".." + r.URL.Path
	args, err := json.Marshal(r.Form)
	checkError(err)
	log.Printf("ARGS in Go side: %s", args)

	cmd := exec.Command(fname, string(args))
	cmd.Stdout = &outMsg
	cmd.Stderr = &errMsg

	if err := cmd.Start(); err != nil {
		log.Fatal(err)
	}
	if err := cmd.Wait(); err != nil {
		log.Fatal(err)
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
	http.HandleFunc("/scripts/", scriptHandler)
	err := http.ListenAndServe(":12345", nil)
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}
