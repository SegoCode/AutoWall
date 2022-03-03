package main

import (
	"encoding/json"
	"io/ioutil"
	"net/http"
	"os"
	"os/exec"
	"syscall"
	"unsafe"
)

// MessageBox of Win32 API.
func MessageBox(hwnd uintptr, caption, title string, flags uint) int {
	ret, _, _ := syscall.NewLazyDLL("user32.dll").NewProc("MessageBoxW").Call(
		uintptr(hwnd),
		uintptr(unsafe.Pointer(syscall.StringToUTF16Ptr(caption))),
		uintptr(unsafe.Pointer(syscall.StringToUTF16Ptr(title))),
		uintptr(flags))

	return int(ret)
}

func main() {

	//Make a get request
	resp, err := http.Get("https://api.github.com/repos/SegoCode/AutoWall/releases/latest")
	if err != nil {
		os.Exit(1)
	}

	//Read the response body on the line below.
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		os.Exit(1)
	}

	// Unmarshal the json string into jsonMap map variable.
	var jsonMap map[string]interface{}
	json.Unmarshal([]byte(string(body)), &jsonMap)

	//Get actual version
	verfile, err := ioutil.ReadFile("tools\\version.dat")
	if err != nil {
		os.Exit(1)
	}

	//Check version
	if string(verfile) != jsonMap["tag_name"] {
		respD := MessageBox(0, "You are running an old version of AutoWall, the actual version is "+jsonMap["tag_name"].(string)+"\nChanges in the latest version:\n\n"+jsonMap["body"].(string)+"\n\n Do you want download last version?", "AutoWall Updater, new version is available", 4)
		if respD == 6 {
			exec.Command("rundll32", "url.dll,FileProtocolHandler", jsonMap["html_url"].(string)).Start()
		}

	}
}
