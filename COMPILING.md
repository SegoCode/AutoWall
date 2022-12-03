
# Compiling from source

Welcome to the Autowall compilation guide! In this guide, you will find the instructions and requirements for building Autowall from source code.

First off, thank you for your interest in contributing to the Autowall project. I hope this guide will be helpful and make the compilation process as smooth as possible. Have you already read the [contribution guide](https://github.com/SegoCode/AutoWall/blob/master/CONTRIBUTING.md)? 

## Software needed

To compile Autowall, you will need to download and install a few tools:
- MPV binary (Portable), available [here](https://mpv.io/installation/).
- Weebp binary (Portable), available [here](https://github.com/Francesco149/weebp/releases).
- Autoit compiler [Aut2Exe](https://www.autoitscript.com/autoit3/docs/intro/compiler.htm), available [here](https://www.autoitscript.com/cgi-bin/getfile.pl?autoit3/autoit-v3.zip).

To compile the optional extra features in the [``AutoWall/src/tools/``](https://github.com/SegoCode/AutoWall/tree/master/src/tools) directory, you will also need to [download and install golang](https://go.dev/doc/install) but are not necessary to run AutoWall.

## Building 

To compile Autowall, you will need to download the repository and place the necessary binaries in the correct directories.

First, download the Autowall repository using git:

 ```bash
 git clone https://github.com/SegoCode/AutoWall
 ```

Now, with the [mpv](https://mpv.io/installation/) and [weebp](https://github.com/Francesco149/weebp/releases) binary unzip to respectives folders ```AutoWall/src/weebp``` and ```AutoWall/src/mpv```. Once these files are in place, you can proceed with the compilation process.

## Compiling

To compile Autowall, you will need to use the [Aut2Exe](https://www.autoitscript.com/autoit3/docs/intro/compiler.htm) compiler to build the ``Autowall.au3`` file.

To do this, open [Aut2Exe](https://www.autoitscript.com/autoit3/docs/intro/compiler.htm) and select the ``Autowall.au3`` file. Then, select the x64 option and compile. This will create the ``Autowall.exe`` file, keep binary in the actual ``Autowall.au3`` root folder. You can also choose an icon for the binary  avaliable [here](https://github.com/SegoCode/AutoWall/tree/master/media). 

After compiling the ``Autowall.au3`` file, you can run Autowall by double-clicking the ``Autowall.exe`` file. This will launch the program and you can begin using it.

However, some of the extra features may not be available. To enable these, you will need to compile the files in the [``AutoWall/src/tools/``](https://github.com/SegoCode/AutoWall/tree/master/src/tools) directory. These files are optional and are not necessary for Autowall to function, but they provide additional functionality that some users may find useful.

To compile these files, follow the instructions in the "Compiling extra tools" section of the guide. This will produce additional .exe files that Autowall can use to enable these features. Once these files have been compiled, you will have a fully functional version of Autowall with all of the extra features enabled.

## Compiling extra tools
*It is important to note that Autowall is simply a script that coordinates the behavior of MPV and Weebp. It has no dependencies on the files in the AutoWall/src/tools directory, and the extra features provided by these files are simply additional .exe binaries that are run at certain points. This means that you can create your own tools using any language or framework, as long as the resulting binary has the correct file name and extension.*

*In other words, the AutoWall/src/tools directory is optional and is not required for Autowall to function properly. You can choose to use the provided tools, create your own, or omit them entirely. Autowall will simply run the appropriate .exe file at the right time, regardless of its origin or implementation.*

To compile the extra tools in the [``AutoWall/src/tools/``](https://github.com/SegoCode/AutoWall/tree/master/src/tools) directory, follow these steps:

Navigate to the ``src/tools`` directory:
```bash
cd src/tools
```

Compile the ``updater.go`` file using the golang compiler. This will create an updater.exe file:
```bash
go build updater.go
```

Install the necessary golang dependencies. These are required for the ``webView.go`` file to be compiled properly:
```bash
go install github.com/inkeliz/gowebview 
```

Compile the ``webView.go`` file. This will create a webView.exe file:
```
go build webView.go
```

Use [Aut2Exe](https://www.autoitscript.com/autoit3/docs/intro/compiler.htm) to compile the ``autoPause.au3`` file to x64. This will create an ``autoPause.exe`` file.

After completing these steps, you should have three .exe files in the tools directory: updater.exe, webView.exe, and autoPause.exe. Autowall is now ready to use with the extra features enabled.


### AutoPause.au3
The AutoPause feature in Autowall is a background process that monitors the state of windows on a computer. It uses a pipe cycle to communicate with a media player called mpv, which is responsible for playing live wallpaper. AutoPause daemon and mpv use a pipe to exchange messages and control the playback of the live wallpaper. When a full window is detected, the AutoPause daemon sends a pause message through the pipe, which is received by mpv and causes it to pause the wallpaper. When the window is closed, the AutoPause daemon sends a play message through the pipe, which is received by mpv and causes it to resume playback of the wallpaper.

One advantage of this design is that the AutoPause daemon is a separate binary file, which means it can be replaced with a custom implementation without affecting the overall functioning of Autowall. Any can create their own window detectors by working with the pipe cycle and implementing their own rules for detecting and pausing full windows. This allows for customization and flexibility in how the live wallpaper behaves.

### updater.go
A simple updater for the AutoWall software. It makes a GET request to the GitHub API to retrieve information about the latest release of the software. It then reads the local version of the software from a file called ``version.dat`` and compares it to the latest release. If the local version is older, it displays a message box to the user asking if they want to download the latest version using the rundll32 command to open the download page in the user's web browser.

The ``version.dat`` file is important because it contains the version number of the currently installed version of the software. The updater uses this information to determine whether an update is available. It is important that the user does not modify this file, as doing so could cause the updater to malfunction. Modifying the file could also prevent the user from receiving important updates to the software.


### webView.go
A simple web viewer that allows AutoWall to display a web in a built-in web browser that can be set as a live wallpaper. As before in AutoPause.au3 any can create their own web viewer, as long as the binary has the same name, if this is not the case, you will have to modify the AutoWall code.
