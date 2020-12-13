#!/bin/bash

mkdir balance.iconset
cp Icon_16.png balance.iconset/icon_16x16.png
cp Icon_32.png balance.iconset/icon_16x16@2x.png
cp Icon_32.png balance.iconset/icon_32x32.png
cp Icon_64.png balance.iconset/icon_32x32@2x.png
cp Icon_64.png balance.iconset/icon_64x64.png
cp Icon_128.png balance.iconset/icon_64x64@2x.png
cp Icon_128.png balance.iconset/icon_128x128.png
cp Icon_256.png balance.iconset/icon_128x128@2x.png
cp Icon_256.png balance.iconset/icon_256x256.png
cp Icon_512.png balance.iconset/icon_256x256@2x.png
cp Icon_512.png balance.iconset/icon_512x512.png
cp Icon_1024.png balance.iconset/icon_512x512@2x.png
cp Icon_1024.png balance.iconset/icon_1024x1024.png
cp Icon_2048.png balance.iconset/icon_1024@2x.png
cp Icon_2048.png balance.iconset/icon_2048.png
cp Icon_4096.png balance.iconset/icon_2048@2x.png
cp Icon_4096.png balance.iconset/icon_4096.png
iconutil --convert icns --output Exported/balance.icns balance.iconset
rm balance.iconset/*
rmdir balance.iconset
