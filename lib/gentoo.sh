ems() {
	[[ -e "/usr/portage/metadata/timestamp.chk" ]] && rm -rf /usr/portage/metadata/timestamp.chk &>/dev/null
	CONFIG_PROTECT_MASK="/etc" emerge --quiet --sync &>/dev/null
}

mrg() {
    full_name="$@"
    # rm -rf /var/tmp/portage/*
    
    # read -r package < pkglist.eg
    
    # if [ -n "$(grep -w ${package} fetched.eg)" ]; then
        # package_name="/usr/portage/distfiles/$(basename ${package} | sed s:-[a-z]*::)"
        
        # if [ -e "${package_name}" ]; then
            # package_size="$(wc -c < ${package_name})"
            
            # if (( package_size < 20971520 )) && (( tmpfs_size > 0 )); then
                # if [ ! -e "tmpfs.eg" ]; then
                    # mount -t tmpfs -o defaults,noatime,nosuid,nodev,size=${tmpfs_size}M tmpfs /var/tmp/portage > /dev/null 2>&1
                    # tch "tmpfs.eg"
                # fi
            # else
                # if [ -e "tmpfs.eg" ]; then
                    # umount -l /var/tmp/portage > /dev/null 2>&1
                    # dlt "tmpfs.eg"
                # fi
            # fi
        # fi
    # fi
    
    # standart emerge
    CONFIG_PROTECT_MASK="/etc" emerge $@ 2> /dev/null
}

umrg() {
    # unmerge which handles each package seperately (if there are more than one packages to remove)
    cl; eb2 "* "; eg2 "emerge "; er "--unmerge ${@}"
    for p in $@
    do
        # sed part deletes package name from "compiled packages" and "packages to emerge" lists
        CONFIG_PROTECT_MASK="/etc" emerge --unmerge ${p} 2> /dev/null && { sed -i "\!.*/${p}.*!d" ${compiled}; sed -i "\!.*/${p}.*!d" pkglist.eg; }
    done
}

set_gcc() {
    gcc-config -l | awk '{print $2}' > gcc.eg
    gcc_latest="$(sort -r gcc.eg | sed q)"
    gcc-config ${gcc_latest} &>/dev/null || gcc-config ${gcc_latest} &>/dev/null
    rm -rf gcc.eg
}

refresh() {
    echo "-5" | CONFIG_PROTECT_MASK="/etc" etc-update &>/dev/null
    env-update &>/dev/null; source /etc/profile &>/dev/null
    vlist
    echo
}

rdr() {
    which revdep-rebuild &>/dev/null && { echo; eb2 "* "; eg "revdep-rebuild -iq"
    echo; revdep-rebuild -iq; }
}

e_check() {
    step=$(eb2 "* "; eg "Checking system...")
    inst "-uDN world"
    echo; eb2 "* "; eg "emerge  --depclean"; echo;
    mrg --depclean
    echo; eb2 "* "; eg "emerge @preserved-rebuild"; echo;
    inst "@preserved-rebuild"
    rdr
    rm -rf /etc/mtab
    ln -sf "/proc/self/mounts" "/etc/mtab"
}

sys_config() {
    echo; eb2 "* "; eg "Creating/Updating necessary configuration files..."; sleep 0.5s
    refresh
    echo
    
    liste="/etc/fstab /etc/hosts /etc/locale.conf /etc/locale.gen /etc/sysctl.conf /etc/timezone /etc/conf.d/domainname /etc/hostname /etc/conf.d/hwclock /etc/vconsole.conf /etc/conf.d/net /etc/modprobe.d/blacklist.conf"

    for d in ${liste}
    do
        er2 "      * "; eg "${d}"; sleep 0.5s
        
        case ${d} in
        /etc/conf.d/domainname|/etc/timezone|/etc/hostname)
            fl "${d}" "0" "d"
        ;;
        /etc/sysctl.conf)
            fl "${d}" "b" "d"
        ;;
        *)
            fl "${d}" "0" "0"
        ;;
        esac
        
        case ${d} in
        /etc/fstab)
            cp fstab.eg ${d}
        ;;
        /etc/hosts)
            sed -i s:"^127.0.0.1.*":"127.0.0.1    ${hostname}.${domainname} ${hostname} localhost": ${d}
            sed -i s:"^\:\:1.*":"\:\:1          ${hostname}.${domainname} ${hostname} localhost": ${d}
        ;;
        /etc/locale.conf)
            cf "LANG=\"${lng}.UTF-8\""
            cf "LC_COLLATE=\"C\""
        ;;
        /etc/locale.gen)
            locale_gen
        ;;
        /etc/timezone)
            case ${keymap} in
            br)
                echo "America/Sao_Paulo" > ${d}
            ;;
            trq|trf)
                echo "Europe/Istanbul" > ${d}
            ;;
            us)
                echo "UTC" > ${d}
            ;;
            esac
        ;;
        /etc/sysctl.conf)
            cf '## TCP SYN cookie protection'
            cf '## helps protect against SYN flood attacks'
            cf '## only kicks in when net.ipv4.tcp_max_syn_backlog is reached'
            cf 'net.ipv4.tcp_syncookies = 1'
            cf '## if not functioning as a router, there is no need to accept redirects or source routes'
            cf 'net.ipv4.conf.all.accept_redirects = 0'
            cf 'net.ipv4.conf.all.accept_source_route = 0'
            cf 'net.ipv4.conf.all.secure_redirects = 1'
            cf '## send redirects (not a router, disable it)'
            cf 'net.ipv4.conf.all.send_redirects = 0'
            cf '## Disable packet forwarding'
            cf 'net.ipv4.ip_forward = 0'
            cf '## protect against tcp time-wait assassination hazards'
            cf '## drop RST packets for sockets in the time-wait state'
            cf '## (not widely supported outside of linux, but conforms to RFC)'
            cf 'net.ipv4.tcp_rfc1337 = 1'
            cf '## source address verification (sanity checking)'
            cf '## helps protect against spoofing attacks'
            cf 'net.ipv4.conf.all.rp_filter = 1'
            cf 'net.ipv4.conf.default.rp_filter = 1'
            cf '## log martian packets'
            cf 'net.ipv4.conf.all.log_martians = 1'
            cf '## ignore echo broadcast requests to prevent being part of smurf attacks'
            cf 'net.ipv4.icmp_echo_ignore_broadcasts = 1'
            cf '## ignore bogus icmp errors'
            cf 'net.ipv4.icmp_ignore_bogus_error_responses = 1'
            cf ''
            cf 'vm.min_free_kbytes = 16384'
            
            case ${type} in
            pc)
                cf "vm.laptop_mode = 0"
                cf "vm.dirty_expire_centisecs = 600"
                cf "vm.dirty_writeback_centisecs = 600"
                cf "vm.dirty_background_ratio = 5"
                cf "vm.dirty_ratio = 20"
            ;;
            laptop)
                cf "vm.laptop_mode = 1"
            ;;
            esac
            
            cf "vm.vfs_cache_pressure = 50"
            cf "vm.swappiness = 1"
            
            sysctl -p &>/dev/null
        ;;
        /etc/conf.d/domainname)
            avoid_dup 'DNSDOMAIN="'${domainname}'"'
            avoid_dup 'NISDOMAIN="'${domainname}'"'
        ;;
        /etc/hostname)
            avoid_dup "${hostname}"
        ;;
        /etc/conf.d/hwclock)
            avoid_dup 'clock="UTC"'
            avoid_dup 'clock_systohc="YES"'
            avoid_dup 'clock_hctosys="YES"'
            avoid_dup 'clock_args=""'
        ;;
        /etc/vconsole.conf)        
            case ${keymap} in
            br)
                avoid_dup 'KEYMAP="br-abnt2"'
                avoid_dup 'FONT="lat9w-16"'
            ;;
            trq|trf)
                avoid_dup 'KEYMAP="'${keymap}'"'
                avoid_dup 'FONT="iso09.16"'
            ;;
            us)
                avoid_dup 'KEYMAP="'${keymap}'"'
                avoid_dup 'FONT="default8x16"'
            ;;
            esac
        ;;
        /etc/conf.d/net)
            avoid_dup 'dns_domain_lo="gentoo.powered"'
            
            for adapter in ${adapters_found}
            do
                avoid_dup 'auto_'${adapter}'="true"'
                avoid_dup 'config_'${adapter}'="dhcp"'
                avoid_dup 'dhcpcd_'${adapter}'="-t 10"'
                avoid_dup 'mtu_'${adapter}'="1492"'
                avoid_dup 'enable_ipv6_'${adapter}'="false"'
            done
        ;;
        /etc/modprobe.d/blacklist.conf)
            for d in amd76x_edac bcm43xx de4x5 dv1394 eepro100 eth1394 evbug \
            garmin_gps i2c_i801 ipv6 ite_cir net-pf-10 nouveau ohci1394 pcspkr \
            prism54 raw1394 sbp2 snd_aw2 snd_intel8x0m snd_pcsp usbkbd usblp \
            usbmouse video1394 wl  
            do
                cf "blacklist ${d}"
            done
            
            cf "# framebuffers"
            for e in aty128fb atyfb radeonfb cirrusfb cyber2000fb cyblafb gx1fb \
            hgafb i810fb intelfb kyrofb lxfb matroxfb_base neofb nvidiafb pm2fb \
            rivafb s1d13xxxfb savagefb sisfb sstfb tdfxfb tridentfb vesafb vfb \
            viafb vt8623fb
            do
                cf "blacklist ${e}"
            done
            
            cf "# modems"
            for f in snd-atiixp-modem snd-intel8x0m snd-via82xx-modem
            do
                cf "blacklist ${f}"
            done

            cf "# watchdog drivers"
            for g in acquirewdt advantechwdt alim1535_wdt alim7101_wdt booke_wdt \
            cpu5wdt eurotechwdt i6300esb i8xx_tco ib700wdt ibmasr indydog iTCO_wdt \
            it8712f_wdt it87_wdt ixp2000_wdt ixp4xx_wdt machzwd mixcomwd mpc8xx_wdt \
            mpcore_wdt mv64x60_wdt pc87413_wdt pcwd pcwd_pci pcwd_usb s3c2410_wdt \
            sa1100_wdt sbc60xxwdt sbc7240_wdt sb8360 sc1200wdt sc520_wdt sch311_wdt \
            scx200_wdt shwdt smsc37b787_wdt softdog twl4030_wdt w83627hf_wdt \
            w83697hf_wdt w83697ug_wdt w83877f_wdt w83977f_wdt wafer5823wdt wdt \
            wdt_pci wm8350_wdt
            do
                cf "blacklist ${g}"
            done
        ;;
        esac
    done
    
    echo; emerge --config sys-libs/timezone-data

    echo; eb2 "* "; eg "Configuring locale settings..."; sleep 0.5s
    
    [[ -e "/etc/env.d/02locale" ]] && { cp /etc/env.d/02locale /etc/env.d/02locale.backup; rm -rf /etc/env.d/02locale; }
    
    echo "LANG=\"${lng}.UTF-8\"" > /etc/env.d/02locale
    
    echo "LC_COLLATE=\"C\"" >> /etc/env.d/02locale
    
    echo; eb2 "* "; eg2 "Changing administrator "; er2 "(root)"; eg " password..."; sleep 0.5s

    echo "root:${rootpass}" | chpasswd

    echo; eb2 "* "; eg2 "Creating user "; er2 "${username}"; eg "..."; sleep 0.5s

    g_list="audio cdrom cdrw disk plugdev portage usb users video wheel"

    for g in ${g_list}; do
        c=$(grep "${g}" /etc/group | cut -d: -f1)
        
        case ${c} in
        ${g})
            [[ -z "${g_e}" ]] && g_e="${g}" || g_e="${g},${g_e}"
        ;;
        esac
    done

    useradd -m -G ${g_e} -s $(which bash) ${username}

    echo "${username}:${userpass}" | chpasswd
    
    if [ -e "/etc/sudoers" ]; then
        echo "%users   ALL=(root) ALL" >> /etc/sudoers
        echo "%users   ALL=(root) NOPASSWD: $(which shutdown)" >> /etc/sudoers
        echo "%users   ALL=(root) NOPASSWD: $(which reboot)" >> /etc/sudoers
        echo "%users   ALL=(root) NOPASSWD: $(which halt)" >> /etc/sudoers
        echo "%users   ALL=(root) NOPASSWD: $(which nano)" >> /etc/sudoers
        echo "%users   ALL=(root) NOPASSWD: $(which emerge)" >> /etc/sudoers
        echo "%users   ALL=(root) NOPASSWD: $(which revdep-rebuild)" >> /etc/sudoers
    fi
    
    [[ ! -e /home/${username}/.bash_profile ]] && cp /etc/skel/.bash_profile /home/${username}/
    
    echo export MOZ_DISABLE_PANGO=1 >> /home/${username}/.bash_profile

    fl "/home/${username}/.bashrc" "0" "0"

    cp /etc/skel/.bashrc ${trg_file}
    
    cf ""
    cf "export XDG_CONFIG_HOME=\"/home/${username}/.config\""
    cf "alias ls='ls --color=auto'"
    cf "alias grep='grep --color=auto'"
    cf "alias egrep='egrep --color=auto'"
    cf "alias fgrep='fgrep --color=auto'"
    cf "alias chown='chown --preserve-root'"
    cf "alias chmod='chmod --preserve-root'"
    cf "alias chgrp='chgrp --preserve-root'"
    cf "alias nn='sudo nano'"
    cf "alias mc='sudo nano /etc/portage/make.conf'"
    cf "alias pu='sudo nano /etc/portage/package.use'"
    cf "alias pm='sudo nano /etc/portage/package.mask'"
    cf "alias pk='sudo nano /etc/portage/package.keywords'"
    cf "alias rb='sudo shutdown -r now'"
    cf "alias sd='sudo shutdown -h now'"
        case ${setup} in
        normal)
            cf "alias lp='sudo leafpad'"
        ;;
        esac
    cf "alias em='sudo emerge'"
    cf "alias emp='sudo emerge -pv'"
    cf "alias ems='sudo emerge --quiet --sync'"
    cf "alias emun='sudo emerge --unmerge'"
    cf "alias emuw='sudo emerge -uDN world'"
    cf "alias emus='sudo emerge -uDN system'"
    cf "alias emdc='sudo emerge --depclean'"
    cf "alias rdr='sudo revdep-rebuild -iq'"
    
    cp ${trg_file} /root/
    
    cf ""
    cf 'PS1="\n\[\e[32;1m\][\[\e[37;1m\]\u\[\e[32;1m\]][\[\e[34;1m\]\w\[\e[32;1m\]]$ \[\e[0m\]"'
    cf ""
    
    echo "" >> /root/.bashrc
    echo 'PS1="\n\[\e[31;1m\][\u][\[\e[34;1m\]\w\[\e[31;1m\]]$ \[\e[0m\]"' >> /root/.bashrc
    echo "" >> /root/.bashrc
    
    [[ ! -e /root/.bash_profile ]] && cp /etc/skel/.bash_profile /root/
}

e_needed() {
    cl
    step=$(eb2 "* "; eg "Emerging basic tools...")
    inst "-u acpid bash-completion sys-apps/dbus localepurge media-fonts/dejavu net-misc/ntp sudo systemd"
    
    timesync
    eselect bashcomp enable --global gentoo

    echo; eb2 "* "; eg2 "Starting services... "; er "(acpid dbus udev)"; echo; sleep 0.5s
    
    for srv in "acpid dbus udev"
    do
        systemctl enable ${srv}.service &>/dev/null
    done
    
    echo; eb2 "* "; eg "Adjusting basic tools to start at boot..."; sleep 0.5s

    for adapter in ${adapters_found}
    do
        net="net.${adapter}"

        [[ ! -e "/etc/init.d/${net}" ]] && ln -s /etc/init.d/net.lo /etc/init.d/${net}
    done
}

package_use() {
    echo; eb2 "* "; eg2 "Creating"; er " package.use..."; sleep 0.5s

    fl "/etc/portage/package.use" "b" "d"
    
    cf "app-admin/conky imlib mpd truetype weather-metar -wifi"
    cf "app-admin/gnome-system-tools nfs policykit"
    cf "app-admin/system-tools-backends policykit"
    cf "app-emulation/emul-linux-x86-java alsa X nsplugin"
    cf "app-office/abiword -collab openxml -plugins wordperfect"
    cf "app-office/gnumeric -perl -python"
    cf "app-text/acroread nsplugin"
    cf "dev-db/mysql embedded"
    cf "dev-java/sun-jre-bin nsplugin"
    cf "dev-java/swt firefox"
    cf "dev-lang/perl ithreads"
    cf "dev-lang/python threads"
    cf "dev-lang/spidermonkey threadsafe"
    cf "dev-libs/glib -fam"
    cf "dev-libs/libcdio cddb"
    cf "dev-libs/libxml2 python"
    cf "dev-libs/libxslt crypt python"
    cf "dev-libs/xmlrpc-c curl libwww"
    cf "dev-python/PyQt4 sql webkit kde multimedia"
    cf "dev-vcs/git curl webdav -gtk"
    cf "gnome-base/gdm remote -consolekit"
    cf "gnome-base/gnome-applets gstreamer networkmanager policykit"
    cf "gnome-base/gnome-session branding"
    cf "gnome-base/gvfs fuse gdu -gphoto2 -http"
    cf "gnome-base/librsvg nsplugin"
    cf "gnome-extra/libgsf thumbnail"
    cf "gnustep-base/gnustep-back-cairo -glitz"
    cf "kde-base/okular djvu ebook jpeg pdf tiff"
    cf "media-gfx/blender blender-game"
    cf "media-gfx/digikam gphoto2"
    cf "media-gfx/gimp alsa curl dbus gimpprint gtkhtml jpeg mmx mng png python sse svg tiff"
    cf "media-gfx/gthumb gphoto2"
    cf "media-gfx/imagemagick -perl"
    cf "media-gfx/sane-backends gphoto2"
    cf "media-gfx/xsane gimp"
    cf "media-libs/gd fontconfig jpeg png xpm"
    cf "media-libs/imlib2 nls zlib X"
    cf "media-libs/libcanberra gtk"
    cf "media-libs/libgphoto2 exif"
    cf "media-libs/libpng apng"
    cf "media-libs/libquicktime schroedinger"
    cf "media-libs/libvorbis aotuv"
    cf "media-libs/mesa g3dvl gallium llvm -motif pic vdpau xcb"
    cf "media-libs/xine-lib dts imagemagick mng modplug vcd vidix xcb xvmc"
    cf "media-libs/win32codecs real"
    cf "media-plugins/alsa-plugins -pulseaudio"
    cf "media-sound/lame -gtk"
    cf "media-sound/pulseaudio -avahi glib gnome"
    cf "media-video/avidemux -qt4 alsa aac dts encode fontconfig gtk lame truetype vorbis x264 xv xvid"
    cf "media-video/dvdrip vcd subtitles"
    cf "media-video/ffmpeg -altivec amr dirac encode faac faad schroedinger theora threads v4l v4l2 vaapi vorbis -X x264 xvid"
    cf "media-video/gxine xcb"
    cf "media-video/mjpegtools yv12"
    cf "media-video/ogmrip ogm srt"
    cf "media-video/totem nsplugin"
    cf "media-video/transcode a52 -altivec dvd iconv imagemagick lzo mjpeg mp3 mpeg nuv ogg postproc quicktime vorbis xvid"
    cf "net-dialup/ppp atm ipv6"
    cf "net-dns/avahi autoipd mdnsresponder-compat"
    cf "net-dns/pdns-recursor lua"
    cf "net-nds/openldap gnutls"
    cf "net-fs/samba automount"
    cf "net-im/pidgin -gstreamer -perl -python"
    cf "net-irc/irssi -perl"
    cf "net-libs/libproxy -gnome -xulrunner"
    cf "net-libs/opal sip"
    cf "net-libs/ptlib wav"
    cf "net-misc/curl -ares gnutls libssh2 ldn"
    cf "net-misc/dhcp minimal"
    cf "net-misc/networkmanager dhcpcd resolvconf wext -connection-sharing -modemmanager"
    cf "net-misc/ntp caps opentpd -ipv6"
    cf "net-misc/nxserver-freenx nxclient"
    cf "net-misc/wicd -pm-utils"
    cf "net-print/cups acl gnutls pam -perl ppds -python samba ssl"
    cf "net-print/gutenprint gimp ppds"
    cf "net-print/hplip minimal ppds scanner"
    cf "net-wireless/wpa_supplicant eap-sim ps3 -fasteap madwifi wimax wps"
        if [ -z "${usebinfrom}" ]; then
            cf "sys-apps/dbus -systemd"
        fi
    cf "sys-apps/help2man -nls"
    cf "sys-apps/iproute2 -minimal"
    cf "sys-apps/pciutils -zlib"
    cf "sys-apps/pmount crypt"
    cf "sys-apps/shadow -pam"
    cf "sys-auth/pambase -consolekit systemd"
    cf "sys-block/parted device-mapper"
    cf "sys-block/gparted dmraid fat hfs jfs mdadm ntfs reiser4 reiserfs xfs"
    cf "sys-devel/gcc -gtk -objc"
    cf "sys-devel/libperl ithreads"
    cf "sys-fs/ntfs3g acl ntfsprogs -external-fuse -suid"
    cf "sys-fs/udev extras"
    cf "sys-kernel/genkernel bash-completion"
    cf "sys-libs/glibc glibc-omitfp nptl nptlonly userlocales"
    cf "www-client/firefox -bindist custom-optimization -java"
    cf "x11-apps/xinit minimal"
    cf "x11-base/xorg-server -kdrive -minimal xorg"
    cf "x11-drivers/nvidia-drivers gtk"
    cf "x11-libs/cairo cleartype -glitz xcb"
    cf "x11-libs/libX11 xcb"
    cf "x11-libs/qt-core optimized-qmake"
    cf "x11-terms/xterm toolbar"
    cf "xfce-base/thunar -pcre xfce_plugins_trash"
    cf "xfce-base/xfdesktop thunar"
}

prepare_useflags() {
    echo; eg2 "  Arranging"; er2 " USE flags"; eg "..."; sleep 0.5s
    
    USEFLAGS="${available_cpu_flags} ${fs_flags}"
    
    if [ -n "${userflags}" ]; then
        for f in ${userflags}
        do
            case ${f} in
            "-*")
                f2="$(echo ${f} | cut -c 2-)"
                [[ "$(echo ${USEFLAGS} | grep ${f2})" ]] || { [[ -z "${newuserflags}" ]] && newuserflags="${f}" || newuserflags="${f} ${newuserflags}"; }
            ;;
            *)
                f2="\-${f}"
                [[ "$(echo ${USEFLAGS} | grep ${f2})" ]] || { [[ -z "${newuserflags}" ]] && newuserflags="${f}" || newuserflags="${f} ${newuserflags}"; }
            ;;
            esac
        done
        
        sed -i '\!^export userflags=!d' ${vl}
        
        a2v "userflags=\"${newuserflags}\""
        
        USEFLAGS="${USEFLAGS} ${userflags}"
    fi
    
    USEFLAGS="${USEFLAGS} acl acpi alsa audiofile bash-completion bzip2 cdr crypt css dbus dri dvd dvdr fam gdbm gnutls gudev ipv6 kmod lzma lzo minimal ncurses network nls nptl pam policykit readline sdl sqlite sqlite3 ssl symlink systemd tcpd truetype udev udisks unicode upower usb vdpau zlib"
    USEFLAGS="${USEFLAGS} -fortran -mudflap -openmp"
    USEFLAGS="${USEFLAGS} -aim -apm -arts -avahi -beagle -berkdb -bidi -bindist -branding -consolekit -cpudetection -debug -dhclient -doc -dso -eds -esd -evo -git -gnome -gphoto2 -gpm -gstreamer -hal -hunspell -icq -imap -introspection -irc -jabber -jack -java -joystick -kde -kdeprefix -kerberos -ldap -mjpeg -mono -mp3rtp -msn -musicbrainz -mysql -nautilus -nss -openexr -orc -oscar -oss -perl -profile -pulseaudio -qt3support -qt4 -rar -rss -slp -spell -static -static-libs -v4l -v4l2 -wmf -xine -xinerama -xscreensaver -yahoo -zemberek"
    USEFLAGS="${USEFLAGS} -cups -foomaticdb -scanner"
    
    case ${type} in
    laptop)
        USEFLAGS="${USEFLAGS} bluetooth hddtemp ieee1394 irda laptop lm_sensors pcmcia wifi"
    ;;
    pc)
        USEFLAGS="${USEFLAGS} -bluetooth -hddtemp -ieee1394 -irda -laptop -lm_sensors -pcmcia -wifi"
    ;;
    esac
    
    case ${setup} in
    normal)
        USEFLAGS="${USEFLAGS} a52 aac avi dts dv encode ffmpeg flac gsm lame mad matroska mp3 mp4 mpeg musepack ogg openal quicktime real speex theora vorbis win32codecs x264 xvid cdda cddb dvb ipod vcd vpx cairo dga gif gtk opengl svg tiff X xpm startup-notification thunar xfce"
    ;;
    basic)
        USEFLAGS="${USEFLAGS} -a52 -aac -avi -dts -dv -encode -ffmpeg -flac -gsm -lame -mad -matroska -mp3 -mp4 -mpeg -musepack -ogg -openal -quicktime -real -speex -theora -vorbis -win32codecs -x264 -xvid -cdda -cddb -dvb -ipod -vcd -vpx -cairo -dga -gif -gtk -opengl -svg -tiff -X -xpm -gnome -kde -nautilus -qt3support -qt4 -startup-notification -thunar -xfce"
    ;;
    esac

    case ${arch} in
    amd64)
        USEFLAGS="${USEFLAGS} multilib"
    ;;
    esac

    echo "${USEFLAGS}" | tr ' ' '\n' > tempflags.eg
    
    cp tempflags.eg useflags.eg
    
    while read flag
    do
        sed -i "s:\<${flag}\>::g" useflags.eg
        
        case ${flag} in
        "-*")
            flag2="$(echo ${flag} | cut -c 2-)"
            sed -i "s:\<${flag2}\>::g" useflags.eg
        ;;
        *)
            flag2="\-${flag}"
            sed -i "s:\<${flag2}\>::g" useflags.eg
        ;;
        esac
        
        echo "${flag}" >> useflags.eg
    done < tempflags.eg
    
    rm -rf tempflags.eg
    echo "$(sort useflags.eg | uniq | tr '\n' ' ')" > tempflags.eg
    xargs -n10 < tempflags.eg > useflags.eg
    # awk '{for(i=10;i<NF;i+=10){$i=$i RS};gsub(RS FS,RS,$0)}1' tempflags.eg > useflags.eg
    rm -rf tempflags.eg
    # read -r USEFLAGS < useflags.eg
}

real_make_conf() {
    echo; eb2 "* "; eg2 "Updating"; er2 " make.conf"; eg "..."; sleep 0.5s
    
    prepare_useflags

    fl "/etc/portage/make.conf" "0" "d"
    
    if [ "${ram_size}" -le "300000" ]; then
        TEMPCFLAGS="-march=native -Os --param ggc-min-expand=0 --param ggc-min-heapsize=16384"
    else
        TEMPCFLAGS="-march=native -O2 -pipe"
    fi
    
    case ${arch} in
    i686)
        TEMPCFLAGS="${TEMPCFLAGS} -fomit-frame-pointer"
        TEMPCHOST="i686-pc-linux-gnu"
    ;;
    amd64)
        TEMPCHOST="x86_64-pc-linux-gnu"
    ;;
    esac
    
    cf "CFLAGS=\"${TEMPCFLAGS}\""
    cf 'CXXFLAGS="${CFLAGS}"'
    cf "CHOST=\"${TEMPCHOST}\""
    cf 'MAKEOPTS="-j'${core}'"'
    cf ''
    cf 'ACCEPT_LICENSE="*"'
    cf 'ACCEPT_KEYWORDS="'${kw}'"'
    cf 'LDFLAGS="-Wl,-O1 -Wl,--as-needed -Wl,--sort-common -Wl,--hash-style=gnu"'
    cf ''
    cf '# It is recommended to leave WANT_MP disabled because of the problems it may trigger.'
    cf '# WANT_MP="true"'
    cf ''
    
    # cf 'USE="'$(while read uline; do echo "${uline} \\"; done < useflags.eg)'"'
    
    cf 'USE="'
        while read uline
        do
            cf "${uline}"
        done < useflags.eg
    cf '"'
    cf ''
    cf 'VIDEO_CARDS="dummy fbdev vesa"'
    
    case ${type} in
    pc)
        cf 'INPUT_DEVICES="evdev"'
    ;;
    laptop)
        cf 'INPUT_DEVICES="evdev synaptics"'
    ;;
    esac
    
    case ${keymap} in
    br)
        cf 'LINGUAS="pt_BR"'
    ;;
    trq|trf)
        cf 'LINGUAS="tr"'
    ;;
    us)
        cf 'LINGUAS="en"'
    ;;
    esac
    
    cf 'AUTOCLEAN="yes"'
    cf ''
    
    if [ "${createbin}" == "yes" ]; then
        cf 'FEATURES="buildpkg -ccache clean-logs -distcc fail-clean fixlafiles -news -parallel-fetch sandbox unknown-features-filter unknown-features-warn nodoc noinfo"'
    else
        cf 'FEATURES="-ccache clean-logs -distcc fail-clean fixlafiles -news -parallel-fetch sandbox unknown-features-filter unknown-features-warn nodoc noinfo"'
    fi
    
    cf 'GENTOO_MIRRORS="'${mirrorlist}'"'
    cf 'RSYNC="rsync://rsync2.us.gentoo.org rsync://rsync3.us.gentoo.org rsync://rsync25.us.gentoo.org"'
        if [ "${blimit}" -gt "0" ]; then
            cf 'FETCHCOMMAND="${FETCHCOMMAND} --limit-rate='${blimit}'k"'
            cf 'RESUMECOMMAND="${RESUMECOMMAND} --limit-rate='${blimit}'k"'
        fi
        if [ -n "${usebinfrom}" ]; then
            cf 'EMERGE_DEFAULT_OPTS="--usepkg --autounmask=y --autounmask-write=y --with-bdeps=y --quiet-build"'
        else
            cf 'EMERGE_DEFAULT_OPTS="--autounmask=y --autounmask-write=y --with-bdeps=y --quiet-build"'
        fi
    
    cf ''
    cf 'CONFIG_PROTECT="/etc /etc/fstab /etc/hosts /etc/locale.conf /etc/locale.gen '
    cf '    /home/'${username}'/.dmrc /etc/localtime /etc/sudoers /etc/sysctl.conf '
    cf '    /etc/X11/xorg.conf.d /etc/portage/package.use /etc/conf.d/domainname '
    cf '    /etc/hostname /etc/conf.d/hwclock /etc/vconsole.conf /etc/conf.d/net '
    cf '    /etc/modprobe.d/blacklist.conf /var/lib/AccountsService/users/'${username}' '
    cf '    /etc/portage/env /etc/X11/gdm /usr/share/config/kdm"'
    cf ''
    cf 'PORTDIR="/usr/portage"'
    cf 'DISTDIR="${PORTDIR}/distfiles"'
    cf 'PKGDIR="${PORTDIR}/packages"'
    cf 'PORTAGE_TMPDIR="/var/tmp"'
    cf 'PORTAGE_COMPRESS="bzip2"'
    cf 'PORTAGE_COMPRESS_FLAGS="-9"'
    cf 'PORTAGE_NICENESS="15"'
    cf 'PORTAGE_RSYNC_INITIAL_TIMEOUT="10"'
    cf 'PORTAGE_RSYNC_RETRIES="5"'
    cf ''
    cf 'PYTHON_TARGETS="python2_7 python3_3"'
        case ${setup} in
        normal)
            case ${type} in
            laptop)
                cf 'XFCE_PLUGINS="brightness menu trash"'
            ;;
            pc)
                cf 'XFCE_PLUGINS="menu trash"'
            ;;
            esac
        ;;
        esac
    cf 'GRUB_PLATFORMS="pc"'
    cf ''
    
    dlt "/etc/make.conf"
}

custom_cflags() {
    mkdir -p /etc/portage/env/dev-lang &>/dev/null
    mkdir -p /etc/portage/env/dev-db &>/dev/null
    mkdir -p /etc/portage/env/www-client &>/dev/null
    mkdir -p /etc/portage/env/net-libs &>/dev/null
    
    fl "/etc/portage/env/O3-cflags" "0" "d"
    
    if [ "${ram_size}" -le "300000" ]; then
        TEMPCFLAGS="-march=native -O3 --param ggc-min-expand=0 --param ggc-min-heapsize=16384"
    else
        TEMPCFLAGS="-march=native -O3 -pipe"
    fi
    
    case ${arch} in
    i686)
        TEMPCFLAGS="${TEMPCFLAGS} -fomit-frame-pointer"
    ;;
    esac
    
    cf "CFLAGS=\"${TEMPCFLAGS}\""
    cf 'CXXFLAGS="${CFLAGS}"'
    
    ln -sf /etc/portage/env/O3-cflags /etc/portage/env/dev-lang/python &>/dev/null
    ln -sf /etc/portage/env/O3-cflags /etc/portage/env/dev-db/sqlite &>/dev/null
    
    fl "/etc/portage/env/firefox-cflags" "0" "d"
    
    if [ "${ram_size}" -le "300000" ]; then
        TEMPCFLAGS="-march=native -Os --param ggc-min-expand=0 --param ggc-min-heapsize=16384"
    else
        TEMPCFLAGS="-march=native -Os -pipe"
    fi
    
    case ${arch} in
    i686)
        TEMPCFLAGS="${TEMPCFLAGS} -fomit-frame-pointer"
    ;;
    esac
    
    cf "CFLAGS=\"${TEMPCFLAGS}\""
    cf 'CXXFLAGS="${CFLAGS}"'
    cf 'LDFLAGS="${LDFLAGS} -Bdirect -Wl,-z,now"'
    
    ln -sf /etc/portage/env/firefox-cflags /etc/portage/env/www-client/firefox &>/dev/null
    
    fl "/etc/portage/env/xulrunner-cflags" "0" "d"
    
    if [ "${ram_size}" -le "300000" ]; then
        TEMPCFLAGS="-march=native -O2 --param ggc-min-expand=0 --param ggc-min-heapsize=16384"
    else
        TEMPCFLAGS="-march=native -O2 -pipe"
    fi
    
    case ${arch} in
    i686)
        TEMPCFLAGS="${TEMPCFLAGS} -fomit-frame-pointer"
    ;;
    esac
    
    cf "CFLAGS=\"${TEMPCFLAGS}\""
    cf 'CXXFLAGS="${CFLAGS}"'
    cf 'LDFLAGS="${LDFLAGS} -Bdirect -Wl,-z,now"'
    
    ln -sf /etc/portage/env/xulrunner-cflags /etc/portage/env/net-libs/xulrunner &>/dev/null
}

e_portage() {
    cl
    
    if [ -z "${usebinfrom}" ]; then
        eb2 "* "; eg "emerge --quiet --sync (this may take a while)"
        
        pkill -f 'emerge --quiet --sync'
        ems
    fi
    
    rm -rf /etc/make.profile

    case ${setup} in
    basic)
        case ${kw} in
        amd64)
            eselect profile set default/linux/amd64/13.0
        ;;
        x86)
            eselect profile set default/linux/x86/13.0
        ;;
        esac
    ;;
    normal)
        case ${kw} in
        amd64)
            eselect profile set default/linux/amd64/13.0/desktop
        ;;
        x86)
            eselect profile set default/linux/x86/13.0/desktop
        ;;
        esac
    ;;
    esac
    
    echo
    step=$(eb2 "* "; eg2 "Updating "; er2 "portage"; eg "... ")
    inst "-u portage"
}

temp_make_conf() {
    echo; eb2 "* "; eg2 "Creating"; er2 " make.conf"; eg "..."; sleep 0.5s

    fl "/etc/portage/make.conf" "0" "d"
    
    if [ "${ram_size}" -le "300000" ]; then
        TEMPCFLAGS="-march=native -Os --param ggc-min-expand=0 --param ggc-min-heapsize=16384"
    else
        TEMPCFLAGS="-march=native -O2 -pipe"
    fi
    
    case ${arch} in
    i686)
        TEMPCFLAGS="${TEMPCFLAGS} -fomit-frame-pointer"
        TEMPCHOST="i686-pc-linux-gnu"
    ;;
    amd64)
        TEMPCHOST="x86_64-pc-linux-gnu"
    ;;
    esac
    
    cf "CFLAGS=\"${TEMPCFLAGS}\""
    cf 'CXXFLAGS="${CFLAGS}"'
    cf "CHOST=\"${TEMPCHOST}\""
    cf 'LDFLAGS="-Wl,-O1 -Wl,--as-needed -Wl,--sort-common -Wl,--hash-style=gnu"'
    cf 'ACCEPT_KEYWORDS="'${kw}'"'
    cf 'ACCEPT_LICENSE="*"'
    cf 'MAKEOPTS="-j2"'
        case ${keymap} in
        br)
            cf 'LINGUAS="pt_BR"'
        ;;
        trq|trf)
            cf 'LINGUAS="tr"'
        ;;
        us)
            cf 'LINGUAS="en"'
        ;;
        esac
    cf 'AUTOCLEAN="no"'
    
    if [ "${createbin}" == "yes" ]; then
        cf 'FEATURES="buildpkg -ccache clean-logs -distcc fail-clean fixlafiles -news -parallel-fetch sandbox unknown-features-filter unknown-features-warn nodoc noinfo"'
    else
        cf 'FEATURES="-ccache clean-logs -distcc fail-clean fixlafiles -news -parallel-fetch sandbox unknown-features-filter unknown-features-warn nodoc noinfo"'
    fi
    
    cf 'USE="'${available_cpu_flags}'"'
    cf ''
    cf '# It is recommended to leave WANT_MP disabled because of the problems it may trigger.'
    cf '# WANT_MP="true"'
    cf ''
    cf 'PORTAGE_RSYNC_INITIAL_TIMEOUT="10"'
    cf 'PORTAGE_RSYNC_RETRIES="5"'
    cf 'GENTOO_MIRRORS="'${mirrorlist}'"'
    cf 'RSYNC="rsync://rsync2.us.gentoo.org rsync://rsync3.us.gentoo.org rsync://rsync25.us.gentoo.org"'
        if [ "${blimit}" -gt "0" ]; then
            cf 'FETCHCOMMAND="${FETCHCOMMAND} --limit-rate='${blimit}'k"'
            cf 'RESUMECOMMAND="${RESUMECOMMAND} --limit-rate='${blimit}'k"'
        fi
        if [ -n "${usebinfrom}" ]; then
            cf 'EMERGE_DEFAULT_OPTS="--usepkg --autounmask=y --autounmask-write=y --with-bdeps=y --quiet-build"'
        else
            cf 'EMERGE_DEFAULT_OPTS="--autounmask=y --autounmask-write=y --with-bdeps=y --quiet-build"'
        fi
    cf ''
}