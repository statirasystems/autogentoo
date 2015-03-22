## Easy Gentoo - Example Profile ##

## Note: if you want to use a default value, then you don't have to specify it

## keymap        name (br, trq, trf or us...) - default: us
keymap           us

## boot          partition    label
boot             sda2         Boot

## swap          partition    label
swap             sda3         Swap

## home          partition    label    filesystem
#home             hda7         Home     xfs

## root          partition    label    filesystem
root             sda4         Root     ext4

## extra         partition    label    filesystem     mount point
#extra            hda5         Temp     reiserfs       /var/tmp
#extra            hda6         Portage  xfs            /usr/portage

## windows       Windows installed partition (will be added to grub menu)
#windows          sdb1

## arch          desired architecture (i686 or amd64) - default: detected by $(uname -m)
arch             amd64

## grub          where to install grub (hdc, sdb, sda3...) (none=disabled) - default: root partition
## grub          none
grub             sda

## type          computer type (laptop or pc) - default: pc
type             pc

## setup         enable/disable audio/video codec USE flags (disabled for basic, enabled for normal) - default: basic
setup            normal

## domainname    domainname to use - default: easygentoo
domainname       gentoo.local

## hostname      hostname to use - default: freshinstall
hostname         gentoo-pc

## rootpass      root password - default: toor
rootpass         toor

## username      your username - default: owner
username         bmoore

## userpass      your user password - default: resu
userpass         password

## autonet       connection handling (reconnect with found network adapters if needed) - default: yes
autonet          yes

## blimit        bandwidth limit for installation (KB/s) (will not be active after setup finishes) - default: 0
blimit           0
