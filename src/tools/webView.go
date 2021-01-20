package main

import (
	"fmt"
	"net/url"
	"os"

	"github.com/inkeliz/gowebview"
)

func main() {
	var inputUrl string

	//Usage validation
	if len(os.Args) <= 1 {
		fmt.Println("[ERR] USAGE: GoWebView.exe http://example.com")
		os.Exit(1)
	}

	//Input url validation
	inputUrl = os.Args[1]
	_, errParse := url.ParseRequestURI(inputUrl)
	if errParse != nil {
		fmt.Println("[ERR] URL NOT VALID (Example: http://example.com)")
		os.Exit(1)
	}

	w, err := gowebview.New(&gowebview.Config{Title: "AutoWall"})
	if err != nil {
		panic(err)
	}
	defer w.Destroy()
	w.SetURL(inputUrl)
	w.Run()
}
