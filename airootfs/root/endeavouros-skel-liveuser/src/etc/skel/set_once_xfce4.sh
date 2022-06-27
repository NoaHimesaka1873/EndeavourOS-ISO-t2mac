#!/bin/sh
sudo rm /etc/mkinitcpio.d/linux.preset
dbus-launch dconf load / < ~/xed.dconf
rm ~/xed.dconf ~/.config/autostart/set_once_xfce4.desktop ~/set_once_xfce4.sh 
