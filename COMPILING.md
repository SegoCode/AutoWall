
# Compiling from source

First off, thanks for your interest in Autowall!💕 Have you already read the [contribution guide](https://github.com/SegoCode/AutoWall/blob/master/CONTRIBUTING.md)? 


## Tools needed

MPV binary (Portable) available [here](https://mpv.io/installation/).

Weebp binary (Portable) available [here](https://github.com/Francesco149/weebp/releases).

Autoit compiler [Aut2Exe](https://www.autoitscript.com/autoit3/docs/intro/compiler.htm) available [here](https://www.autoitscript.com/cgi-bin/getfile.pl?autoit3/autoit-v3.zip).

For compile extra features also called ``tools`` in https://github.com/SegoCode/AutoWall/tree/master/src/tools you have to [download and install golang](https://go.dev/doc/install) but they are not necessary to run autowall.


## Building 

First of all download the repository ```git clone https://github.com/SegoCode/AutoWall```

Now with the [mpv](https://mpv.io/installation/) and [weebp](https://github.com/Francesco149/weebp/releases) binary unzip to respectives folders ```AutoWall/src/weebp``` and ```AutoWall/src/mpv```

## Compiling

Using [Aut2Exe](https://www.autoitscript.com/autoit3/docs/intro/compiler.htm) compile to x64 ``Autowall.au3`` and keep binary in the actual ``.au3`` folder, also you can select the icon avaliable [here](https://github.com/SegoCode/AutoWall/tree/master/media).

__At this point you can use AutoWall running Autowall.exe__ , but some extra functions will not be available, for that remains you will have to compile all ``tools`` files in ``AutoWall/src/tools``.

## Compiling extra tools
*Keep in mind, Autowall its only a script to coordinate mpv and weebp, it has no dependence with ``AutoWall/src/tools`` , and all the extra files the only thing that do Autowall is running a binary called ``*.exe`` at some point,  Also this means that you can create your own tools using the correct file name and extension*.

First move to the folder ``cd src/tools``.

Run golang compiler ``go build updater.go``.

Install golang dependences ``go install github.com/inkeliz/gowebview ``.

Run golang compiler ``go build webView.go``.

Using [Aut2Exe](https://www.autoitscript.com/autoit3/docs/intro/compiler.htm) compile to x64 ``autoPause.au3``

__And now you will have three ``.exe`` in ``/tools``, Autowall is ready to use!__

## AutoPause.au3
> #### SegoCode at https://github.com/SegoCode/AutoWall/issues/19#issuecomment-955776642
> Also for you and any dev reading this, the autoPause.exe is a "out of the box" deamon monitoring state of windows and send actions to mpv throw the pipe ```cycle pause >\\.\pipe\mpvsocket```, You can just delete the autoPause.exe and autowall still works perfectly without "play - pause" feature. Also this means that you can create your own window detector with any rule working with the pipe ```cycle pause >\\.\pipe\mpvsocket``` , the only thing that do Autowall is running a binary called ```autoPause.exe```


