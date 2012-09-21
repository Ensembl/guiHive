package main

import (
	"fmt"
	"net/http"
	"log"
	"github.com/ziutek/mymysql/mysql"
	_ "github.com/ziutek/mymysql/native" // Native engine
)



func handler(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintf(w, "Hi there, I love %s!", r.URL.Path[1:])
}


func connectMySQLServer() mysql.Conn {
	db := mysql.New("tcp", "", "localhost:2912", "ensadmin", "ensembl", "mp12_compara_nctrees_69a")
	err := db.Connect()
	if err != nil {
		panic(err)
	}
	return db
}

func main() {
	relPath := ".."
	http.HandleFunc("/",        handler)
	http.Handle("/static/",     http.FileServer(http.Dir(relPath)))
	http.Handle("/styles/",     http.FileServer(http.Dir(relPath)))
	http.Handle("/javascript/", http.FileServer(http.Dir(relPath)))
//	http.HandleFunc("/scripts/",serveScripts)
//	err := http.ListenAndServe(":12345", http.FileServer(http.Dir("/home/mp/gocode/src/guiHive/static/")))
	err := http.ListenAndServe(":12345", nil)
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}
