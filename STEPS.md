#New
1. Get Script Location
2. Check for Configuration(s)
    a. if not ask if defaults are ok or if they want full selection
    b. if yes, check for how many, if in headless mode
        1. if not in headless mode, check for priorty feild.
            a. load according to priority feild then, if not present or the same then alphabetically
3. Get Installing OS distro and version
4.

#$! OLD

check for necessary filesystem utilities, according to filesystems selected for partitions in profile, that should be in the installation media and take a note to emerge them during install
check if necessary commands/utilities are available in the installation media
check internet connection
extract settings from profile
create two files, one for formatting and one for mounting partitions
create fstab template
check number of cpu cores
check if root partition is big enough
determine cpu specific USE flags
execute previously created format and mount files
check mirrors
sync date and time with pool.ntp.org
get latest tarball name
download latest tarball, do a sha512sum check, extract tarball in the background
download latest portage snapshot, do a md5sum check, extract snapshot in the background
check if background extract jobs are done
prepare for chroot (move all necessary files, mount /proc and /dev)
---chroot---
start background function which checks for connection status every 60 seconds
create a temporary swap file if there is not a swap partition and the RAM is smaller than 1800 MB
change some system settings like swappiness and vfs_cache_pressure temporarily
create a temporary /etc/portage/make.conf just to emerge portage and some utilities
create package specific CFLAGS for firefox, xulrunner, python and sqlite
select appropriate portage profile
emerge portage
emerge dhcpcd gentoolkit dmidecode lafilefixer
create /etc/locale.gen and execute locale-gen
update /etc/portage/make.conf to include all necessary settings
create /etc/portage/package.use
emerge -e system
emerge genkernel-next gentoo-sources
download custom kernel config from easygentoo repository
compile kernel using custom config and genkernel-next
emerge grub2
create /boot/grub/grub.cfg
install grub2 to MBR (or user selected target)
emerge acpid bash-completion dbus localepurge net-misc/ntp sudo
start services (acpid dbus udev)
systemctl enable acpid.service
systemctl enable dbus.service
systemctl enable udev.service
create/change configuration files (/etc/fstab /etc/hosts /etc/locale.conf /etc/locale.gen)
create/change configuration files (/etc/sysctl.conf /etc/timezone /etc/conf.d/domainname)
create/change configuration files (/etc/hostname /etc/conf.d/hwclock /etc/vconsole.conf)
create/change configuration files (/etc/conf.d/net /etc/modprobe.d/blacklist.conf)
emerge --config timezone-data
create /etc/env.d/02locale
change /etc/vconsole.conf
change root password
create user (default groups: audio cdrom cdrw disk plugdev portage usb users video wheel)
change user password
change /etc/sudoers
add default alias settings to /home/${username}/.bashrc
emerge xorg-server
emerge dejavu eselect-fontconfig fontconfig mesa-progs setxkbmap
create /home/${username}/.xinitrc
emerge xfce4-meta xfce4-notifyd
emerge app-editors/leafpad x11-terms/xfce4-terminal x11-themes/murrine-themes xarchiver xfce4-mixer xfce4-taskmanager
(if script is running on a laptop) emerge xfce4-battery-plugin xfce4-power-manager laptop-mode-tools
(if script is running on a laptop) systemctl enable laptop_mode.service
emerge thunar thunar-archive-plugin thunar-volman trayer
add user to plugdev group
change /etc/env.d/90xsession
create /home/${username}/.gtkrc-2.0
emerge lightdm
create /home/${username}/.dmrc
systemctl enable lightdm.service
change /etc/conf.d/xdm
eselect opengl set xorg-x11
create necessary files in /etc/X11/xorg.conf.d/ (including evdev.conf)
create /etc/X11/xorg.conf
create /home/${username}/.fonts.conf
eselect fontconfig enable ... (some settings for dejavu font)
emerge networkmanager nm-applet
systemctl enable NetworkManager.service
change NetworkManager permissions in /usr/share/polkit-1/actions/org.freedesktop.NetworkManager.policy
emerge alsa-utils
systemctl enable alsa-store.service
systemctl enable alsa-restore.socket
create /etc/asound.conf
create /etc/conf.d/alsasound
amixer set Master unmute
amixer set PCM unmute
alsactl -f /var/lib/alsa/asound.state store
emerge --unmerge lafilefixer localepurge ntp
emerge -uDN world
revdep-rebuild
localepurge
delete temporary swap file
create a report
delete all unnecessary/temporary files
move stage3 tarball, portage snapshot, profile and easygentoo to /home/${username}/
move compiled.txt to /home/${username}/
exit easygentoo and shutdown computer
