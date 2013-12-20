
// +build debug

package main

import "log"

func debug(format string, args ...interface{}) {
	log.Printf("DEBUG: "+format, args...)
}
