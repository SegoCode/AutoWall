package main

import (
	"github.com/tcnksm/go-latest"
	"gopkg.in/toast.v1"
	"io/ioutil"
	"log"
)

func main() {
	githubTag := &latest.GithubTag{
		Owner:      "SegoCode",
		Repository: "AutoWall",
	}
	
	verfile, _ := ioutil.ReadFile("version.dat")
	res, _ := latest.Check(githubTag, string(verfile))

	if res.Outdated {
		log.Print("New version is available. Actual: " + string(verfile) + " Found: " + res.Current)
		notification := toast.Notification{
			AppID:               "AutoWall",
			Title:               "AutoWall",
			Message:             "A new version is available. Click here to download.",
			ActivationArguments: "https://github.com/SegoCode/AutoWall/releases",
		}
		notification.Push()

	}
}
