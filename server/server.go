package main

import (
	"fmt"
	"net/http"
//	"net/url"
	"log"
)



func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hi there, I love %s!", r.URL.Path[1:])
}

func scriptHandler(w http.ResponseWriter, r *http.Request) {
	err := r.ParseForm()
	if err != nil {
		log.Fatal(err)
	}
	log.Println("METHOD: ", r.Method)
	log.Println("URL: ", r.URL)
	log.Println("BODY: ", r.Body)
	log.Println("URL: ", r.Form)
	log.Println("FORM: ", r.Form.Get("url"))
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
