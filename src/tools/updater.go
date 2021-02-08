package main

import (
	"github.com/tcnksm/go-latest"
	"gopkg.in/toast.v1"
)

func main() {
	githubTag := &latest.GithubTag{
		Owner:      "SegoCode",
		Repository: "AutoWall",
	}
	res, _ := latest.Check(githubTag, "1.5.0")
	if res.Outdated {
		notification := toast.Notification{
			AppID:               "AutoWall",
			Title:               "AutoWall",
			Message:             "A new version is available. Click here to download.",
			ActivationArguments: "https://github.com/SegoCode/AutoWall/releases",
		}
		notification.Push()

	}
}
