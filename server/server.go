package main

import (
	"fmt"
	"net/http"
//	"net/url"
	"log"
	"os"
	"os/exec"
	"encoding/json"
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

	fname := ".." + r.URL.Path
	args, err := json.Marshal(r.Form)
	log.Printf("ARGS in Go side: %s", args)
	checkError(err)
	fh, err := os.Open(fname)
	checkError(err)
	defer fh.Close()

	cmd := exec.Command(fname, string(args))
	resp, err := cmd.Output()
	checkError(err)
	log.Printf("RESP: %s", resp)
	fmt.Fprintf(w, string(resp))
	
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
