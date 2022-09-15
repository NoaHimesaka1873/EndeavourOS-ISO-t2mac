#!/usr/bin/env bash

# Made by Fernando "maroto"
# Run anything in the filesystem right before being "mksquashed"
# ISO-NEXT specific cleanup removals and additions (08-2021 + 10-2021) @killajoe and @manuel
# refining and changes november 2021 @killajoe and @manuel

script_path=$(readlink -f "${0%/*}")
work_dir="work"

# Adapted from AIS. An excellent bit of code!
# all pathes must be in quotation marks "path/to/file/or/folder" for now.

arch_chroot() {
    arch-chroot "${script_path}/${work_dir}/x86_64/airootfs" /bin/bash -c "${1}"
}

do_merge() {

arch_chroot "$(cat << EOF

echo "##############################"
echo "# start chrooted commandlist #"
echo "##############################"

cd "/root"

# Init & Populate keys
pacman-key --init
pacman-key --populate archlinux endeavouros

# Install liveuser skel (in case of conflicts use overwrite)
pacman -U --noconfirm --overwrite "/etc/skel/.bash_profile","/etc/skel/.bashrc" -- "/root/endeavouros-skel-liveuser/"*".pkg.tar.zst"

# Prepare livesession settings and user
sed -i 's/#\(en_US\.UTF-8\)/\1/' "/etc/locale.gen"
locale-gen
ln -sf "/usr/share/zoneinfo/UTC" "/etc/localtime"

# Set root permission and shell
usermod -s /usr/bin/bash root

# Create liveuser
useradd -m -p "" -g 'liveuser' -G 'sys,rfkill,wheel,uucp,nopasswdlogin,adm,tty' -s /bin/bash liveuser

# Remove liveuser skel to then install user skel
pacman -Rns --noconfirm -- "endeavouros-skel-liveuser"
rm -rf "/root/endeavouros-skel-liveuser"

# Root qt style for Calamares
mkdir "/root/.config"
cp -Rf "/home/liveuser/.config/"{"Kvantum","qt5ct"} "/root/.config/"

# Add builddate to motd:
cat "/usr/lib/endeavouros-release" >> "/etc/motd"
echo "------------------" >> "/etc/motd"

# Enable systemd services
systemctl enable NetworkManager.service systemd-timesyncd.service bluetooth.service firewalld.service
systemctl enable vboxservice.service vmtoolsd.service vmware-vmblock-fuse.service
systemctl set-default multi-user.target

# Revert from arch-iso preset to default preset
cp -rf "/usr/share/mkinitcpio/hook.preset" "/etc/mkinitcpio.d/linux.preset"
sed -i 's?%PKGBASE%?linux?' "/etc/mkinitcpio.d/linux.preset"

# Patching EndeavourOS specific grub config
patch -u "/etc/default/grub" -i "/root/grub.patch"
rm "/root/grub.patch"

# Patching mkinitcpio.conf
patch -u "mkinitcpio.conf" -i "/root/mkinitcpio.patch"
cp "mkinitcpio.conf" "/etc/"
rm "mkinitcpio.conf" "/root/mkinitcpio.patch"

# Remove unneeded grub stuff from /boot
rm -R "/boot/syslinux"
rm -R "/boot/memtest86+"
rm "/boot/initramfs-linux-t2.img"
#rm "/boot/intel-ucode.img"
rm "/boot/vmlinuz-linux-t2"

# Install locally builded packages on ISO (place packages under airootfs/root/packages)
pacman -U --noconfirm -- "/root/packages/"*".pkg.tar.zst"
rm -rf "/root/packages/"

# Set wallpaper for live-session and original for installed system
mv "endeavouros-wallpaper.png" "/etc/calamares/files/endeavouros-wallpaper.png"
mv "/root/livewall.png" "/usr/share/endeavouros/backgrounds/endeavouros-wallpaper.png"
chmod 644 "/usr/share/endeavouros/backgrounds/"*".png"
rm -rf "/usr/share/backgrounds/xfce/xfce-verticals.png"
ln -s "/usr/share/endeavouros/backgrounds/endeavouros-wallpaper.png" "/usr/share/backgrounds/xfce/xfce-verticals.png"


# TEMPORARY CUSTOM FIXES

# Fix for getting bash configs installed
cp -af "/home/liveuser/"{".bashrc",".bash_profile"} "/etc/skel/"

# Move blacklisting nouveau out of ISO (copy back to target for offline installs)
mv "/usr/lib/modprobe.d/nvidia-utils.conf" "/etc/calamares/files/nv-modprobe"
mv "/usr/lib/modules-load.d/nvidia-utils.conf" "/etc/calamares/files/nv-modules-load"

# Get extra drivers!:
mkdir -p "/opt/extra-drivers/mba91"
sudo pacman -Sw --noconfirm --cachedir "/opt/extra-drivers" apple-t2-audio-config apple-t2-audio-config-alt 
wget -P /opt/extra-drivers/mba91 "https://gist.githubusercontent.com/bigbadmonster17/8b670ae29e0b7be2b73887f3f37a057b/raw/b2fc3ca90e727cb7d213dd6362cc4671f7515f65/91-pulseaudio-custom.rules"
wget -P /opt/extra-drivers/mba91 "https://gist.githubusercontent.com/bigbadmonster17/8b670ae29e0b7be2b73887f3f37a057b/raw/b2fc3ca90e727cb7d213dd6362cc4671f7515f65/apple-t2.conf"
wget -P /opt/extra-drivers/mba91 "https://gist.githubusercontent.com/bigbadmonster17/8b670ae29e0b7be2b73887f3f37a057b/raw/b2fc3ca90e727cb7d213dd6362cc4671f7515f65/AppleT2.conf"

# Clean pacman log
rm "/var/log/pacman.log"

# remove /etc/mkinitcpio.d/linux.preset for sure
sudo rm /etc/mkinitcpio.d/linux.preset

echo "############################"
echo "# end chrooted commandlist #"
echo "############################"

EOF
)"
}

#################################
########## STARTS HERE ##########
#################################

do_merge
