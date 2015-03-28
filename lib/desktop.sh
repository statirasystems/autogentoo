e_nm() {
    cl
    step=$(eb2 "* "; eg2 "Emerging "; er2 "NetworkManager"; eg "...")
    inst "-u networkmanager nm-applet"

    systemctl enable NetworkManager.service &>/dev/null
    systemctl disable dhcpcd.service &>/dev/null
    
    fl "/usr/share/polkit-1/actions/org.freedesktop.NetworkManager.policy" "b" "0"
    sed -i s/"<allow_active>.*<\/allow_active>"/"<allow_active>yes<\/allow_active>"/ ${trg_file}
}

e_lightdm() {
    cl
    step=$(eb2 "* "; eg2 "Emerging "; er2 "Lightdm"; eg " login manager...")
    inst "-u lightdm"
    
    fl "/usr/share/xsessions/xfce.desktop" "0" "0"
    
    if [ ! -e "/usr/share/xsessions/xfce.desktop" ]; then
        cf '[Desktop Entry]'
        cf 'Version=1.0'
        cf 'Name=Xfce Session'
        cf 'Exec=startxfce4'
        cf 'Icon='
        cf 'Type=Application'
    fi
    
    chown -fP ${username} ${trg_file}
    
    fl "/home/${username}/.dmrc" "0" "d"
    
    cf "[Desktop]"
    cf "Session=xfce"
    
    fl "/var/lib/AccountsService/users/${username}" "0" "0"
    
    avoid_dup "XSession=xfce"
    
    chown -fP ${username} ${trg_file}
    
    fl "/usr/share/xsessions/Xsession.desktop" "0" "d"
    
    systemctl enable lightdm.service &>/dev/null
    
    fl "/etc/conf.d/xdm" "0" "0"
    
    avoid_dup 'DISPLAYMANAGER="lightdm"'
    avoid_dup 'NEEDS_HALD="no"'
    
    chown -fP ${username} ${trg_file}
}

e_xfce() {
    cl
    step=$(eb2 "* "; eg2 "Emerging "; er2 "Xfce"; eg " desktop environment...")
    inst "-u xfce4-meta xfce4-notifyd"
    step=$(eb2 "* "; eg "Emerging other Xfce packages...")
    inst "-u app-editors/leafpad x11-terms/xfce4-terminal x11-themes/murrine-themes xfce4-mixer xfce4-taskmanager"
    
    case "${type}" in
    laptop)
        step=$(eb2 "* "; eg "Emerging packages needed for laptops...")
        inst "-u xfce4-battery-plugin xfce4-power-manager laptop-mode-tools"
        systemctl enable laptop_mode.service &>/dev/null
    ;;
    esac
    
    step=$(eb2 "* "; eg2 "Emerging "; er2 "Thunar"; eg "...")
    inst "-u thunar thunar-archive-plugin thunar-volman trayer"
    
    mkdir -p /home/${username}/.config/xfce4/panel &>/dev/null
    
    cp /etc/xdg/xfce4/panel/default.xml /home/${username}/.config/xfce4/panel/
    
    usermod -a -G plugdev ${username}
    
    session="Xfce4"
    
    fl "/etc/env.d/90xsession" "0" "d"
    
    avoid_dup 'XSESSION="'${session}'"'
    
    fl "/home/${username}/.gtkrc-2.0" "b" "d"
    
    cf "include \"/usr/share/themes/MurrinaBlu/gtk-2.0/gtkrc\""
    cf ''
    cf 'style "user-font" {'
    cf '    font_name = "DejaVu Sans 9"'
    cf '}'
    cf ''
    cf 'style "xfdesktop-icon-view" {'
    cf '    XfdesktopIconView::label-alpha = 10'
    cf '    base[NORMAL] = "#000000"'
    cf '    base[SELECTED] = "#71B9FF"'
    cf '    base[ACTIVE] = "#71FFAD"'
    cf '    fg[NORMAL] = "#ffffff"'
    cf '    fg[SELECTED] = "#71B9FF"'
    cf '    fg[ACTIVE] = "#71FFAD"'
    cf '}'
    cf ''
    cf 'widget_class "*XfdesktopIconView*" style "xfdesktop-icon-view"'
    cf ''
    cf 'widget_class "*" style "user-font"'
    cf 'gtk-font-name = "DejaVu Sans 9"'
    cf 'gtk-theme-name = "MurrinaBlu"'
}

e_x() {
    cl
    step=$(eb2 "* "; eg2 "Checking system"; eg "...")
    inst "-uN system"
    
    step=$(eb2 "* "; eg2 "Emerging "; er2 "Xorg server"; eg "...")
    inst "-u xorg-server"
    
    step=$(eb2 "* "; eg2 "Emerging necessary tools")
    inst "-u eselect-fontconfig fontconfig mesa-progs setxkbmap"
    
    fl "/home/${username}/.xprofile" "b" "0"

    case ${keymap} in
    br)
        cf "setxkbmap -model evdev -layout br"
    ;;
    trq)
        cf "setxkbmap -model evdev -layout tr"
    ;;
    trf)
        cf "setxkbmap -model evdev -layout tr -variant f"
    ;;
    us)
        cf "setxkbmap -model evdev -layout us"
    ;;
    esac
    
    cf "export GDK_USE_XFT=1"
    cf "export QT_XFT=true"
    cf ""
    cf "#This line is necessary if you don't use a login manager to start Xfce"
    cf "#exec $(which ck-launch-session) $(which dbus-launch) --exit-with-session xfce4-session"
    
    active=$(eselect opengl list | grep "xorg-x11" | grep "*")

    if [ -z "${active}" ]; then
        eselect opengl set xorg-x11
    fi
    
    refresh
    
    echo; eb2 "* "; eg2 "Making adjustments for "; er "evdev "; echo
    
    fl "/etc/X11/xorg.conf.d/05-evdev.conf" "b" "d"

    cf 'Section "InputClass"'
    cf '    Identifier "mouse-all"'
    cf '    MatchIsPointer "on"'
    cf '    MatchDevicePath "/dev/input/event*"'
    cf '    Driver "evdev"'
    cf 'EndSection'
    cf ''
    cf 'Section "InputClass"'
    cf '    Identifier "keyboard-all"'
    cf '    MatchIsKeyboard "on"'
    cf '    MatchDevicePath "/dev/input/event*"'
    cf '    Driver "evdev"'
        case ${keymap} in
        br)
            cf '    Option "XkbLayout" "br"'
        ;;
        trq|trf)
            cf '    Option "XkbLayout" "tr"'
            case ${keymap} in
            trf)
                cf '    Option "XkbVariant" "f"'
            ;;
            esac
        ;;
        us)
            cf '    Option "XkbLayout" "us"'
        ;;
        esac
    cf 'EndSection'
    cf ''
    cf 'Section "InputClass"'
    cf '    Identifier "touchpad-all"'
    cf '    MatchIsTouchpad "on"'
    cf '    MatchDevicePath "/dev/input/event*"'
    cf '    Driver "evdev"'
    cf 'EndSection'
    cf ''
    cf 'Section "InputClass"'
    cf '    Identifier "tablet-all"'
    cf '    MatchIsTablet "on"'
    cf '    MatchDevicePath "/dev/input/event*"'
    cf '    Driver "evdev"'
    cf 'EndSection'
    cf ''
    cf 'Section "InputClass"'
    cf '    Identifier "touchscreen-all"'
    cf '    MatchIsTouchscreen "on"'
    cf '    MatchDevicePath "/dev/input/event*"'
    cf '    Driver "evdev"'
    cf 'EndSection'

    fl "/etc/X11/xorg.conf.d/10-synaptics.conf" "b" "d"

    cf 'Section "InputClass"'
    cf '  Identifier "touchpad catchall"'
    cf '  MatchIsTouchpad "on"'
    cf '  MatchDevicePath "/dev/input/event*"'
    cf '  Driver "synaptics"'
    cf 'EndSection'
    cf ''
    cf 'Section "InputClass"'
    cf '  Identifier "Dell Inspiron embedded buttons quirks"'
    cf '  MatchTag "inspiron_1011|inspiron_1012"'
    cf '  MatchDevicePath "/dev/input/event*"'
    cf '  Driver "synaptics"'
    cf '  Option "JumpyCursorThreshold" "90"'
    cf '  Option "AreaBottomEdge" "4100"'
    cf 'EndSection'
    cf ''
    cf 'Section "InputClass"'
    cf '  Identifier "Dell Inspiron quirks"'
    cf '  MatchTag "inspiron_1120"'
    cf '  MatchDevicePath "/dev/input/event*"'
    cf '  Driver "synaptics"'
    cf '  Option "JumpyCursorThreshold" "250"'
    cf 'EndSection'
    cf ''
    cf 'Section "InputClass"'
    cf '  Identifier "HP Mininote quirks"'
    cf '  MatchTag "mininote_1000"'
    cf '  MatchDevicePath "/dev/input/event*"'
    cf '  Driver "synaptics"'
    cf '  Option "JumpyCursorThreshold" "20"'
    cf 'EndSection'

    fl "/etc/X11/xorg.conf.d/10-vmmouse.conf" "b" "d"

    cf 'Section "InputClass"'
    cf '  Identifier "vmmouse catchall"'
    cf '  MatchTag "vmmouse"'
    cf '  MatchDevicePath "/dev/input/event*"'
    cf '  Driver "vmmouse"'
    cf 'EndSection'

    fl "/etc/X11/xorg.conf.d/10-wacom.conf" "b" "d"

    cf 'Section "InputClass"'
    cf '  Identifier "Wacom Class"'
    cf '  MatchProduct "Wacom|WACOM"'
    cf '  MatchDevicePath "/dev/input/event*"'
    cf '  Driver "wacom"'
    cf 'EndSection'
    cf ''
    cf 'Section "InputClass"'
    cf '  Identifier "Wacom serial class"'
    cf '  MatchProduct "Serial Wacom Tablet"'
    cf '  Driver "wacom"'
    cf '  Option "ForceDevice" "ISDV4"'
    cf 'EndSection'
    cf ''
    cf 'Section "InputClass"'
    cf '  Identifier "Wacom serial class identifiers"'
    cf '  MatchProduct "WACf|FUJ02e5|FUJ02e7"'
    cf '  Driver "wacom"'
    cf 'EndSection'
    cf ''
    cf '# N-Trig Duosense Electromagnetic Digitizer'
    cf 'Section "InputClass"'
    cf '  Identifier "Wacom N-Trig class"'
    cf '  MatchProduct "HID 1b96:0001|N-Trig Pen"'
    cf '  MatchDevicePath "/dev/input/event*"'
    cf '  Driver "wacom"'
    cf '  Option "Button2" "3"'
    cf 'EndSection'
    
    fl "/etc/X11/xorg.conf.d/20-magictrackpad.conf" "b" "d"
    
    cf 'Section "InputClass"'
    cf '  Identifier "Magic Trackpad"'
    cf '  MatchUSBID "05ac:030e"'
    cf '  Driver "evdev"'
    cf 'EndSection'

    fl "xorg.eg" "0" "0"
    
    cf 'Section "Files"'
    
    ls /usr/share/fonts >> fonts.eg
    
    while read fontdir
    do
        case ${fontdir} in
        75dpi|100dpi|misc)
            cf '  FontPath "/usr/share/fonts/'${fontdir}':unscaled"'
        ;;
        *)
            cf '  FontPath "/usr/share/fonts/'${fontdir}'"'
        ;;
        esac
    done < fonts.eg
    
    cf 'EndSection'
    cf ''
    cf 'Section "ServerFlags"'
    cf '    Option  "DontZap" "off"'
    cf 'EndSection'
    cf ''
    cf 'Section "Device"'
    cf '    Identifier "video-card"'
    cf '    Driver  "vesa"'
    cf '    Option  "Monitor-default" "monitor"'
    cf 'EndSection'
    cf ''
    cf 'Section "Monitor"'
    cf '    Identifier  "monitor"'
    cf '    VertRefresh  50-70'
    cf '    HorizSync  30-80'
    cf '    Option  "Enable" "true"'
    cf '    Option  "TargetRefresh" "60"'
    cf '    Option  "RenderAccel" "True"'
        case ${type} in
        laptop)
            cf '    Option  "DPMS" "true"'
        ;;
        esac
    cf 'EndSection'
    cf ''
    cf 'Section "Screen"'
    cf '    Identifier  "general"'
    cf '    Device   "video-card"'
    cf '    Monitor  "monitor"'
    cf 'EndSection'
    cf ''
    cf 'Section "ServerLayout"'
    cf '    Identifier  "general-layout"'
    cf '    Screen  "general"'
    cf '    Option  "BackingStore" "True"'
    cf 'EndSection'
    cf ''
    cf 'Section "Module"'
    cf '    Load  "dbe"'
    cf '    Load  "dri"'
    cf '    Load  "dri2"'
    cf '    Load  "evdev"'
    cf '    Load  "extmod"'
    cf '    SubSection  "extmod"'
    cf '      Option    "omit xfree86-dga"'
    cf '    EndSubSection'
    cf '    Load  "freetype"'
    cf '    Load  "glx"'
    cf 'EndSection'
    cf ''
    cf 'Section "Extensions"'
    cf '    Option  "Composite"  "Enable"'
    cf 'EndSection'
    
    fl "/etc/X11/xorg.conf" "b" "d"
    
    cp xorg.eg ${trg_file}
    
    fl "/home/${username}/.fonts.conf" "b" "d"

    cf '<?xml version="1.0" encoding="UTF-8"?>'
    cf '<!DOCTYPE fontconfig SYSTEM "fonts.dtd">'
    cf '<fontconfig>'
    cf '    <alias>'
    cf '        <family>serif</family>'
    cf '        <prefer>'
    cf '            <family>DejaVu Serif</family>'
    cf '            <family>Bitstream Vera Serif</family>'
    cf '        </prefer>'
    cf '    </alias>'
    cf ''
    cf '    <alias>'
    cf '        <family>sans-serif</family>'
    cf '        <prefer>'
    cf '            <family>DejaVu Sans</family>'
    cf '            <family>Bitstream Vera Sans</family>'
    cf '            <family>Verdana</family>'
    cf '            <family>Arial</family>'
    cf '        </prefer>'
    cf '    </alias>'
    cf ''
    cf '    <alias>'
    cf '        <family>monospace</family>'
    cf '        <prefer>'
    cf '            <family>DejaVu Sans Mono</family>'
    cf '            <family>Bitstream Vera Sans Mono</family>'
    cf '        </prefer>'
    cf '    </alias>'
    cf ''
    cf '    <match target="font">'
    cf '        <edit name="rgba" mode="assign">'
    cf '            <const>none</const>'
    cf '        </edit>'
    cf '        <edit name="autohint" mode="assign">'
    cf '            <bool>true</bool>'
    cf '        </edit>'
    cf '        <edit name="antialias" mode="assign">'
    cf '            <bool>true</bool>'
    cf '        </edit>'
    cf '        <edit name="hinting" mode="assign">'
    cf '            <bool>true</bool>'
    cf '        </edit>'
    cf '        <edit name="hintstyle" mode="assign">'
    cf '            <const>hintfull</const>'
    cf '        </edit>'
    cf '    </match>'
    cf ''
    cf '    <!-- Disable autohint for bold fonts -->'
    cf '    <match target="font">'
    cf '           <test name="weight" compare="more">'
    cf '            <const>medium</const>'
    cf '        </test>'
    cf '        </test>'
    cf '           <edit name="autohint" mode="assign">'
    cf '            <bool>false</bool>'
    cf '        </edit>'
    cf '    </match>'
    cf ''
    cf '    <!-- Reject bitmap fonts in favour of Truetype, Postscript, etc. -->'
    cf '    <selectfont>'
    cf '        <rejectfont>'
    cf '            <pattern>'
    cf '                <patelt name="scalable">'
    cf '                    <bool>false</bool>'
    cf '                </patelt>'
    cf '            </pattern>'
    cf '        </rejectfont>'
    cf '    </selectfont>'
    cf ''
    cf '</fontconfig>'

    for cfg in "10-autohint.conf" "10-sub-pixel-rgb.conf" "20-unhint-small-dejavu-sans-mono.conf"
    do
        no=$(eselect fontconfig list | grep "${cfg}" | tr '[]' ' ' | awk '{print $1}')
        eselect fontconfig enable "${no}" &>/dev/null
    done
    
    for cfg in "20-unhint-small-dejavu-sans.conf" "20-unhint-small-dejavu-serif.conf" "25-unhint-nonlatin.conf"
    do
        no=$(eselect fontconfig list | grep "${cfg}" | tr '[]' ' ' | awk '{print $1}')
        eselect fontconfig enable "${no}" &>/dev/null
    done
     
    for cfg in "57-dejavu-sans-mono.conf" "57-dejavu-sans.conf" "57-dejavu-serif.conf"
    do
        no=$(eselect fontconfig list | grep "${cfg}" | tr '[]' ' ' | awk '{print $1}')
        eselect fontconfig enable "${no}" &>/dev/null
    done
}

desktop_env() {
    case ${setup} in
    normal)
        e_x; e_xfce; e_lightdm; e_nm
        # e_alsa
    ;;
    basic)
        systemctl enable dhcpcd.service &>/dev/null
    ;;
    esac
    
    systemctl enable polkit.service &>/dev/null
    systemctl disable wicd.service &>/dev/null
    systemctl disable cups.service &>/dev/null
    
    case ${type} in
    laptop)
        systemctl enable bluetooth.service &>/dev/null
        systemctl enable wpa_supplicant.service &>/dev/null
    ;;
    pc)
        systemctl disable bluetooth.service &>/dev/null
        systemctl disable wpa_supplicant.service &>/dev/null
    ;;
    esac
    
    umrg "localepurge ntp"
}