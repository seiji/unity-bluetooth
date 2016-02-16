#!/bin/sh
UNITYLIBS="/Applications/Unity/PlaybackEngines/AndroidPlayer/Variations/mono/Release/Classes/classes.jar"
DSTDIR="../../build/Packager/Assets/Plugins/Android"
export ANT_OPTS=-Dfile.encoding=UTF8

android update project -p .
mkdir -p libs
cp $UNITYLIBS libs
ant release
mkdir -p $DSTDIR
cp -a bin/classes.jar $DSTDIR/bluetoothservice.jar
ant clean
rm -rf libs res proguard-project.txt
