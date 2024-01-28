
# Compiling from source

Welcome to the Autowall compilation guide! In this guide, you will find the instructions and requirements for building Autowall from source code.

First off, we appreciate for your interest in contributing to the Autowall project. I hope this guide will be helpful and make the compilation process as smooth as possible.

## Required Software for Building AutoWall

To successfully compile AutoWall, you need to download and install the following tools:
- **MPV (Portable Version):** Essential for media playback. Download from [MPV Installation](https://mpv.io/installation/).
- **Weebp (Portable Version):** Required for managing wallpapers. Available at [Weebp Releases](https://github.com/Francesco149/weebp/releases).
- **Autoit Builder (Aut2Exe):** A tool for building AutoIt scripts. Get it from [Aut2Exe](https://www.autoitscript.com/autoit3/docs/intro/buildr.htm).

## Building

This section outlines the detailed steps for compiling AutoWall. To begin, ensure you have downloaded all the necessary software as mentioned in the prerequisites.

The first step in the building process is to clone the Autowall repository from GitHub. Use the following command in your terminal or command prompt to clone the repository:

```bash
git clone https://github.com/SegoCode/AutoWall
```

After cloning, you need to set up the essential binaries for mpv and weebp. These binaries are crucial for Autowall's functionality.

1. **MPV Binary Setup:**
   - Download the portable version of MPV from [MPV Installation](https://mpv.io/installation/).
   - Unzip the downloaded file.
   - Place the unzipped MPV binaries in the `AutoWall/src/mpv` directory.

2. **Weebp Binary Setup:**
   - Acquire the portable version of Weebp from [Weebp Releases](https://github.com/Francesco149/weebp/releases).
   - Unzip this file as well.
   - Move the Weebp binaries to the `AutoWall/src/weebp` directory.

With the repository cloned and the necessary binaries in place, you are now ready to compile the project. Navigate to the root directory of the cloned repository and run the build script or follow the specific compilation instructions for Autowall.

Remember, correctly placing the MPV and Weebp binaries is crucial for a successful build. Ensure they are in their respective directories before starting the compilation process.

## Compiling

To build Autowall, it's necessary to have to use the [Aut2Exe](https://www.autoitscript.com/autoit3/docs/intro/buildr.htm) buildr to build the ``Autowall.au3`` file.

To do this, open [Aut2Exe](https://www.autoitscript.com/autoit3/docs/intro/buildr.htm) and select the ``Autowall.au3`` file. Then, select the x64 option and build. This will create the ``Autowall.exe`` file, keep binary in the actual ``Autowall.au3`` root folder. You can also choose an icon for the binary  avaliable [here](https://github.com/SegoCode/AutoWall/tree/master/media). 

After compiling the ``Autowall.au3`` file, you can run Autowall by double-clicking the ``Autowall.exe`` file. This will launch the program and you can begin using it.

However, some of the extra features may not be available. To enable these, it's necessary to have to build the files in the [``AutoWall/src/tools/``](https://github.com/SegoCode/AutoWall/tree/master/src/tools) directory. These files are optional and are not necessary for Autowall to function, but they provide additional functionality that some users may find useful.

To build these files, follow the instructions in the "Compiling extra tools" section of the guide. This will produce additional .exe files that Autowall can use to enable these features. Once these files have been buildd, you will have a fully functional version of Autowall with all of the extra features enabled.

## Compiling extra tools
*It is important to note that Autowall is simply a script that coordinates the behavior of MPV and Weebp. It has no dependencies on the files in the AutoWall/src/tools directory, and the extra features provided by these files are simply additional .exe binaries that are run at certain points. This means that you can create your own tools using any language or framework, as long as the resulting binary has the correct file name and extension.*

*In other words, the AutoWall/src/tools directory is optional and is not required for Autowall to function properly. You can choose to use the provided tools, create your own, or omit them entirely. Autowall will simply run the appropriate .exe file at the right time, regardless of its origin or implementation.*

To build the extra tools in the  directory, follow these steps:

To build the extra tools located in the [``AutoWall/src/tools/``](https://github.com/SegoCode/AutoWall/tree/master/src/tools) directory, you should follow these steps:

1. Build `updater.au3` using [Aut2Exe](https://www.autoitscript.com/autoit3/docs/intro/buildr.htm) targeting x64 architecture. This will generate `updater.exe`.

2. Build `autoPause.au3` with [Aut2Exe](https://www.autoitscript.com/autoit3/docs/intro/buildr.htm), also targeting x64. This creates `autoPause.exe`.

3. For `mouseSender.au3`, use [Aut2Exe](https://www.autoitscript.com/autoit3/docs/intro/buildr.htm) to build for x64, resulting in `mouseSender.exe`.

4. Download the latest release of [webview](https://github.com/SegoCode/LiteWebview) and place the binary in the designated folder as "webview.exe".


After completing these steps, you should have four .exe files in the tools directory: webview.exe, updater.exe, webView.exe, and autoPause.exe. Autowall is now ready to use with the extra features enabled.

### AutoPause.au3
The AutoPause feature in Autowall is a background process that monitors the state of windows on a computer. It uses a pipe cycle to communicate with a media player called mpv, which is responsible for playing live wallpaper. AutoPause daemon and mpv use a pipe to exchange messages and control the playback of the live wallpaper. When a full window is detected, the AutoPause daemon sends a pause message through the pipe, which is received by mpv and causes it to pause the wallpaper. When the window is closed, the AutoPause daemon sends a play message through the pipe, which is received by mpv and causes it to resume playback of the wallpaper.

One advantage of this design is that the AutoPause daemon is a separate binary file, which means it can be replaced with a custom implementation without affecting the overall functioning of Autowall. Any can create their own window detectors by working with the pipe cycle and implementing their own rules for detecting and pausing full windows. This allows for customization and flexibility in how the live wallpaper behaves.

### updater.au3
A simple updater for the AutoWall software. It makes a GET request to the GitHub API to retrieve information about the latest release of the software. It then reads the local version of the software from a file called ``version.dat`` and compares it to the latest release. If the local version is older, it displays a message box to the user asking if they want to download the latest version, open the download page in the user's web browser.

The ``version.dat`` file is important because it contains the version number of the currently installed version of the software. The updater uses this information to determine whether an update is available. It is important that the user does not modify this file, as doing so could cause the updater to malfunction. Modifying the file could also prevent the user from receiving important updates to the software.


### mouseSender.au3
MouseSender.au3 is designed to enhance the user interaction with the live wallpaper. It enables the transmission of mouse events to the wallpaper by identifying the wallpaper's window ID (HWND). This feature enhances the interactivity of the live wallpaper, allowing for dynamic responses and animations based on mouse movements and actions. Users can enjoy a more immersive and engaging desktop experience through this real-time interaction with the live wallpaper.