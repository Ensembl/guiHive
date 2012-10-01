// Copyright 2012 Miguel Pignatelli. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// +build debug

package main

import "log"

func debug(format string, args ...interface{}) {
        log.Printf("DEBUG: "+format, args...)
}
