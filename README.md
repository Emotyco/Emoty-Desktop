# Emoty-Desktop

[![Build Status](https://travis-ci.org/Emotyco/Emoty-Desktop.svg?branch=develop "Linux (Travis CI)")](https://travis-ci.org/Emotyco/Emoty-Desktop)
[![Build Status](https://img.shields.io/appveyor/ci/kdebiec/Emoty-Desktop.svg "Windows (AppVeyor)")](https://ci.appveyor.com/project/kdebiec/Emoty-Desktop)
[![Github Release](http://img.shields.io/github/release/Emotyco/Emoty-Desktop.svg "Github Latest Release")](https://github.com/Emotyco/Emoty-Desktop/releases/latest)

**Maintainer:** Konrad Dębiec (konradd@tutanota.com)

## Introduction
Emoty is intended to be a modern social network with emphasis on simplicity, freedom and safety. It is based on top of <a href="https://github.com/retroshare">RetroShare</a>.

## Contribution
Contributions are more than welcome!

If you have spotted an error or something just doesn't make sense then simply create issue, make a pull request or send direct message to maintainer.

For code contributors:
- As this project is part of <a href="https://github.com/retroshare">RetroShare</a>, we use the same <a href="https://github.com/RetroShare/documentation/wiki/Coding">code styling</a>,
- If possible start commit with "Added:", "Changed:" or "Fixed:".

## License
This program is licensed under <a href="http://www.gnu.org/licenses/gpl-3.0.en.html">GNU General Public License version 3 (GNU GPLv3)</a>.

## Compilation
### Step #1
Create folder structure:  

    "Emoty"
    |-- "Qml-Material"
    |-- "Emoty-Desktop"
    |-- "RS-Core"
    
### Step #2
To folder named "RS-Core" download using git or just directly repository https://github.com/RetroShare/RetroShare. Change few assignations in file "retroshare.pri", which at this stage should be in "Emoty/RS-Core/retroshare.pri", as follows:

    # To disable RetroShare-gui append the following
    # assignation to qmake command line "CONFIG+=no_retroshare_gui"
    CONFIG *= no_retroshare_gui
      
    # To disable RetroShare-nogui append the following
    # assignation to qmake command line "CONFIG+=no_retroshare_nogui"
    CONFIG *= no_retroshare_nogui
      
    # To disable RetroShare plugins append the following
    # assignation to qmake command line "CONFIG+=no_retroshare_plugins"
    CONFIG *= no_retroshare_plugins
      
    # To enable RetroShare-android-service append the following assignation to
    # qmake command line "CONFIG+=retroshare_android_service"
    CONFIG *= retroshare_android_service
      
    # To enable RetroShare-android-notify-service append the following
    # assignation to qmake command line "CONFIG+=retroshare_android_notify_service"
    CONFIG *= no_retroshare_android_notify_service
      
    # To enable RetroShare-QML-app append the following assignation to
    # qmake command line "CONFIG+=retroshare_qml_app"
    CONFIG *= no_retroshare_qml_app
      
    # To enable libresapi via local socket (unix domain socket or windows named
    # pipes) append the following assignation to qmake command line "CONFIG+=libresapilocalserver"
    CONFIG *= libresapilocalserver
    
    # To enable Qt dependencies in libresapi append the following
    # assignation to qmake command line "CONFIG+=qt_dependencies"
    CONFIG *= qt_dependencies
    
    # To disable libresapi via HTTP (based on libmicrohttpd) append the following
    # assignation to qmake command line "CONFIG+=no_libresapihttpserver"
    CONFIG *= no_libresapihttpserver
      
    # To disable SQLCipher support append the following assignation to qmake
    # command line "CONFIG+=no_sqlcipher"
    CONFIG *= sqlcipher

    # To enable autologin (this is higly discouraged as it may compromise your node
    # security in multiple ways) append the following assignation to qmake command
    # line "CONFIG+=rs_autologin"
    CONFIG *= no_rs_autologin
      
    # To disable GXS (General eXchange System) append the following
    # assignation to qmake command line "CONFIG+=no_rs_gxs"
    CONFIG *= rs_gxs
      
    # To enable RS Deprecated Warnings append the following assignation to qmake
    # command line "CONFIG+=rs_deprecatedwarning"
    CONFIG *= no_rs_deprecatedwarning
    
    # To enable CPP #warning append the following assignation to qmake command
    # line "CONFIG+=rs_cppwarning"
    CONFIG *= no_rs_cppwarning
      
    # To disable GXS mail append the following assignation to qmake command line
    # "CONFIG+=no_rs_gxs_trans"
    CONFIG *= rs_gxs_trans
      
    # To enable GXS based async chat append the following assignation to qmake
    # command line "CONFIG+=rs_async_chat"
    CONFIG *= no_rs_async_chat
      
Now follow it compilation steps.

### Step #3
To folder named "Qml-Material" download using git or just directly repository https://github.com/Emotyco/qml-material.

### Step #4
To folder named "Emoty-Desktop" download using git or just directly repository https://github.com/Emotyco/Emoty-Desktop. 

### Step #5
Download and install Qt >= 5.8 from https://www.qt.io/download-open-source.

### Step #6 
Compile Emoty-Desktop.
