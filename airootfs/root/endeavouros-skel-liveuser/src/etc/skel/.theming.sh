#!/bin/bash

# Set theme to Breeze Dark EOS
lookandfeeltool -a com.endeavouros.breezedarkeos.desktop

# Set wallpaper to /usr/share/endeavouros/backgrounds/endeavouros-wallpaper.png
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
var allDesktops = desktops();
for (i=0;i<allDesktops.length;i++) {
    d = allDesktops[i];
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = Array("Wallpaper", "org.kde.image", "General");
    d.writeConfig("Image", "file:///usr/share/endeavouros/backgrounds/endeavouros-wallpaper.png")
}
'

