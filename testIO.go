package main

import(
	"bytes"
	"os/exec"
	"log"
)

func main() {
	scriptname := "scripts/test.pl"
	var outMsg bytes.Buffer
	var errMsg bytes.Buffer
	cmd := exec.Command(scriptname, "args here")
	cmd.Stdout = &outMsg
	cmd.Stderr = &errMsg
	if err := cmd.Start(); err != nil {
		log.Fatal(err)
	}
	if err := cmd.Wait(); err != nil {
		log.Fatal(err)
	}
	log.Printf("ERR: %s\n", errMsg.Bytes())
	log.Printf("OUT: %s\n", outMsg.Bytes())
}
