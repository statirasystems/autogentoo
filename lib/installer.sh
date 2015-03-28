

inst() {
    ecmd="${1}"
    make_list() {
        fl "pkglist.eg" "0" "d"
        
        while read line
        do
            case "${line}" in
            "[ebuild"*)
                echo "${line}" | tr -s '[:blank:]' ' ' | sed -e 's:\[[0-9].*\]::' -e 's:\[.*ebuild.*\] :=:' -e 's: .*::' >> ${trg_file}
            ;;
            esac
        done < data.eg
        
        while read p_line
        do
            case ${p_line} in
            =[A-Z]*/*|=[a-z]*/*)
                continue
            ;;
            *)
                sed -i "\!.*${p_line}.*!d" ${trg_file}
            ;;
            esac
        done < ${trg_file}
        
        fl "pkglist_dup.eg" "0" "d"
        cp pkglist.eg ${trg_file}
        
        case "${a}" in
        "-e system")
            emerge -pv --nodeps gentoo-sources | grep ebuild | grep gentoo-sources | tr -s '[:blank:]' ' ' | sed -e 's:\[[0-9].*\]::' -e 's:\[.*ebuild.*\] :=:' -e 's: .*::' >> ${trg_file}
            emerge -pv --nodeps genkernel | grep ebuild | grep genkernel | tr -s '[:blank:]' ' ' | sed -e 's:\[[0-9].*\]::' -e 's:\[.*ebuild.*\] :=:' -e 's: .*::' >> ${trg_file}
        ;;
        esac
        
        fl "fetched.eg" "0" "d"
        tch ${trg_file}
    }
    
    fetch() {
        pkill -f 'emerge -f --nodeps'
        while true
        do
            shut
            
            read -r pkg < pkglist_dup.eg
            if [ -z "${pkg}" ]; then
                break
            else
                case "${pkg}" in
                *"/"*)
                    next="no"
                    while [ "${next}" != "yes" ]
                    do
                        CONFIG_PROTECT_MASK="/etc" emerge -f --nodeps ${pkg} 2> /dev/null
                        
                        case $? in
                        0)
                            cf "${pkg}"; next="yes"
                        ;;
                        *)
                            pkill -f 'emerge -f --nodeps'
                            if [ -e "connected.eg" ]; then
                                pkill -f 'emerge --quiet --sync'
                                inst "sync"
                            else
                                until [ -e "connected.eg" ]
                                do
                                    sleep 1s
                                done
                            fi
                        ;;
                        esac
                    done
                    sleep 0.5s
                ;;
                esac
            
                sed -i "\!.*${pkg}.*!d" pkglist_dup.eg
            fi
        done
    }
    
    compile() {
        rcount="0"
        fl "pkglist.eg" "0" "0"
        while true
        do
            read -r package < ${trg_file}
            
            if [ -z "${package}" ]; then
                break
            else
                if [ -e "${trg_file}" ]; then
                    cl
                    source "$(pwd)/merge.eg"
                    
                    [[ -n "${step}" ]] && echo "${step}"
                    
                    echo
                    echo; ey2 "  Command: "; eg2 "  emerge "; er "${a}"
                    echo; eg2 "  Next packages "; ew2 "($(wc -l < ${trg_file}) packages total)"; eg ":"
                    
                    p_numb="1"
                    while read p_input
                    do
                        p_input="$(echo ${p_input} | cut -c 2-)"
                        case ${p_numb} in
                        1)
                            ey "    ${p_input}"
                        ;;
                        [2-5])
                            ew "    ${p_input}"
                        ;;
                        6)
                            break
                        ;;
                        esac
                        ((p_numb++))
                    done < ${trg_file}
                    
                    echo
                    
                    if [ -z "${usebinfrom}" ]; then
                        if [ -z "$(grep ${package} fetched.eg)" ]; then
                            ew2 "  Waiting for package download..."
                            while [ -z "$(grep ${package} fetched.eg)" ]
                            do
                                sleep 5s
                                shut
                            done
                            ew "  Package downloaded."
                        fi
                    else
                        echo "${package}" >> fetched.eg
                    fi
                    
                    echo
                fi
                
                shut
                
                case ${package} in
                *sys-apps/kmod-*)
                    umrg "module-init-tools"
                ;;
                *sys-apps/systemd-*)
                    if [ -z "${usebinfrom}" ]; then
                        sed -i '\!^sys-apps/dbus.*$!d' /etc/portage/package.use
                    fi
                    
                    umrg "sys-fs/udev"
                ;;
                esac
                
                if [ -e "sys.eg" ]; then
                    mrg -e --oneshot --nodeps ${package}
                else
                    if [ -n "$(grep $(echo ${package} | cut -c 2-) ${compiled})" ]; then
                        mrg -u --oneshot --nodeps ${package}
                    else
                        mrg --oneshot --nodeps ${package}
                    fi
                fi
                
                case $? in
                0)
                    sed -i "\!.*${package}.*!d" ${trg_file}
                    
                    if [ -z "$(grep $(echo ${package} | cut -c 2-) ${compiled})" ]; then
                        echo "${package}" | cut -c 2- >> ${compiled}
                    fi
                    
                    [[ -e "sys.eg" ]] && refresh
                    
                    case ${package} in
                    *sys-devel/gcc-[0-9]*)
                        set_gcc && refresh
                    ;;
                    esac
                    rcount="0"
                ;;
                *)
                    ((rcount++))
                    rm -rf /var/tmp/portage/*$(echo ${package} | cut -c 2-)* &>/dev/null
                    
                    case ${rcount} in
                    1)
                        refresh; timesync
                        
                        if [ -z "${usebinfrom}" ]; then
                            pkill -f 'emerge --quiet --sync'
                            inst "sync"; refresh
                        fi
                        
                         case ${package} in
						*sys-apps/systemd-*)
							emerge --deselect sys-fs/udev
						;;
						esac
                    ;;
                    2)
                        python-updater && refresh
                        perl-cleaner --reallyall && refresh
                    ;;
                    3)
                        tch abortmission.eg
                        echo
                        er "Installation failed due to compile error."
                        er "Package: $(echo ${package} | cut -c 2-)."
                        er "Easygentoo will exit now."; echo; exit 1
                    ;;
                    esac
                ;;
                esac
            fi
        done
        unset package
        
        # Making records for commands that doesn't get recorded to world file because of --oneshot parameter
        [[ "${a}" != "-e system" ]] && mrg -u ${a} 2>&1 > /dev/null
        
        step=""
    }
    
    case ${ecmd} in
    sync)
        [[ -e "/usr/portage/metadata/timestamp.chk" ]] && rm -rf /usr/portage/metadata/timestamp.chk &>/dev/null
        CONFIG_PROTECT_MASK="/etc" emerge --quiet --sync &>/dev/null
    ;;
    *)
        fl "merge.eg" "0" "d"
        cf "a=\"${ecmd}\""
        
        source "$(pwd)/merge.eg"
        if [ "${a}" == "-e system" ]; then
            { emerge -pvD ${a} 2>&1 | grep '^\['; } >data.eg 2>&1
        else
            { emerge -pv ${a} 2>&1 | grep '^\['; } >data.eg 2>&1
        fi
        
        if [ -n "$(grep -i '^\[ebuild' data.eg)" ]; then
            make_list
            [[ -z "${usebinfrom}" ]] && fetch &>/dev/null &
            compile
        fi
    ;;
    esac
}

report() {
    rp="report.txt"
    
    echo "Total installation time (uptime): $(uptime | tr ',' ' ' | awk '{print $3}')" >> ${rp}
    echo "Number of compiled packages: $(wc -l < ${compiled})" >> ${rp}
    echo "List of compiled packages: ${compiled}" >> ${rp}
    echo "Selected CPU architecture: ${arch}" >> ${rp}
    echo "Selected tarball: ${tarball}" >> ${rp}
    echo "Total CPU cores: ${core}" >> ${rp}
    echo "Total RAM: ${ram_size} KB" >> ${rp}
    
    if ((swap_file_size > 0)) || ((swap_size > 0)); then
        [[ -z "${msu}" ]] && msu="0"
        echo "Max Swap Usage During Install: ${msu} MB" >> ${rp}
    fi
    
    echo "User name: ${username}" >> ${rp}
    echo "User password: ${userpass}" >> ${rp}
    echo "Administrator (root) password: ${rootpass}" >> ${rp}
    echo "Domainname: ${domainname}" >> ${rp}
    echo "Hostname: ${hostname}" >> ${rp}
    
    case ${keymap} in
    br)
        echo "Keymap: br-abnt2" >> ${rp}
    ;;
    *)
        echo "Keymap: ${keymap}" >> ${rp}
    ;;
    esac
    
    if [ -n "${adapters_found}" ]; then
        echo "Network adapters: ${adapters_found}" >> ${rp}
    else
        echo "No network adapters were found." >> ${rp}
    fi
    echo "" >> ${rp}
    
    case ${blimit} in
    0)
        echo "No bandwidth limit is used during setup." >> ${rp}
    ;;
    *)
        echo "Bandwidth limit used during setup: ${blimit} KB/s" >> ${rp}
    ;;
    esac
    
    if [ -n "${userflags}" ]; then
        echo "User specified USE flags: ${userflags}" >> ${rp}
    fi
    
    if [ -n "${usebinfrom}" ]; then
        echo "Used binary packages from: ${usebinfrom}" >> ${rp}
    fi
    
    if [ "${createbin}" == "yes" ]; then
        echo "Binary packages were created during installation." >> ${rp}
    fi
    
    if [ -e "packageslinked.eg" ]; then
        echo "Binary packages are located at: /var/lib/packages" >> ${rp}
    else
        echo "Binary packages are located at: /usr/portage/packages" >> ${rp}
    fi
    
    if [ -e "distfileslinked.eg" ]; then
        echo "Distfiles are located at: /var/lib/distfiles" >> ${rp}
    else
        echo "Distfiles are located at: /usr/portage/distfiles" >> ${rp}
    fi
    
    case ${setup} in
    basic)
        echo "Xfce is not installed." >> ${rp}
    ;;
    normal)
        echo "Xfce is installed as a desktop environment." >> ${rp}
    ;;
    esac
    
    echo "" >> ${rp}
    echo "Mirrors:" >> ${rp}
    
    for m in ${mirrorlist}
    do
        echo "    ${m}" >> ${rp}
    done
    
    echo "" >> ${rp}
    echo "Partitions used:" >> ${rp}
    
    while read part label fs mp
    do
        if [ -n "${part}" ]; then
            echo "    Partition: ${part}, Label: ${label}" >> ${rp}
            echo "    File System: ${fs}, Mount Point: ${mp}" >> ${rp}
            echo "" >> ${rp}
        fi
    done < partition_list.eg
}

end() {
    fl "/etc/portage/make.conf" "0" "0"
    
    avoid_dup 'FEATURES="-ccache clean-logs -distcc fail-clean fixlafiles news parallel-fetch sandbox unknown-features-filter unknown-features-warn nodoc noinfo"'
    avoid_dup 'EMERGE_DEFAULT_OPTS="--autounmask=y --autounmask-write=y --with-bdeps=y --quiet-build"'
    
    sed -i -e '\!^FETCHCOMMAND=.*$!d' -e '\!^RESUMECOMMAND=.*$!d' ${trg_file}
    cl
    
    case ${keymap} in
    br)
        echo; eb2 "* "; eg2 "Removing all localization files excluding "; er2 "Portugese Brazilian"; eg "..."; sleep 2s; echo
    ;;
    trq|trf)
        echo; eb2 "* "; eg2 "Removing all localization files excluding "; er2 "Turkish"; eg "..."; sleep 2s; echo
    ;;
    us)
        echo; eb2 "* "; eg2 "Removing all localization files excluding "; er2 "English"; eg "..."; sleep 2s; echo
    ;;
    esac

    fl "/etc/locale.nopurge" "b" "d"
    
    cf "MANDELETE"
    cf "SHOWFREEDSPACE"
    cf "VERBOSE"
    cf ""
    
    case ${keymap} in
    br)
        cf "pt"
        cf "pt_BR"
        cf "pt_BR.UTF-8"
        cf "pt_BR ISO-8859-1"
    ;;
    trq|trf)
        cf "tr"
        cf "tr_TR"
        cf "tr_TR.UTF-8"
        cf "tr_TR ISO-8859-9"
    ;;
    us)
        cf "en"
        cf "en_US"
        cf "en_US.UTF-8"
        cf "en_US ISO-8859-1"
    ;;
    esac
    
    localepurge &>/dev/null
    
    echo; eb2 "* "; eg2 "Creating a small report at "; er2 "${tidy}"; eg "..."
    report
    
    er2 "* "; ey "Deleting temporary files..."; sleep 0.5s; echo
    
    [[ -e "${egswap}" ]] && { swapoff ${egswap} &>/dev/null; rm -rf ${egswap} &>/dev/null; }
    
    mkdir -p ${tidy} &>/dev/null
    mv *.tar.bz2 ${tidy} &>/dev/null
    mv ${profile} ${tidy} &>/dev/null
    mv ${compiled} ${tidy} &>/dev/null
    mv ${eg} ${tidy}/easygentoo &>/dev/null
    mv ${rp} ${tidy} &>/dev/null
    
    rm -rf /var/tmp/portage/* &>/dev/null
    
    cd / && rm -rf /${egdir} &>/dev/null

    chown -fPR ${username} /home/${username}/
    
    cl; eb2 "* "; ew "Setup has finished. Now your system is ready to use. Congratulations! :)"; echo; sleep 5s

    echo; ey2 "* "; er "Shutting down..."; echo; shutdown -h now
}

e_pp() {
    cl
    step=$(eb2 "* "; eg2 "Emerging "; er2 "Python"; eg2 " and "; er2 "Perl"; eg "...")
    inst "-u perl python"
}

e_system() {
    cl
    step=$(eb2 "* "; eg "Updating system...")
    inst "-e system"
    inst "-u libtool"
}

e_kernel() {
    cl
    
    if [ -z "${usebinfrom}" ]; then
        sed -i '\!^sys-apps/dbus.*$!d' /etc/portage/package.use
    fi
    
    umrg "sys-fs/udev"
    
    step=$(eb2 "* "; eg "Emerging kernel... ")
    inst "-u genkernel gentoo-sources lzop"
    step=$(eb2 "* "; eg "Emerging filesystem tools... ")
    inst "-u ${progs}"
    
    echo; eg2 "  Creating kernel config"; eg "..."; echo; sleep 0.5s
    
    download "https://raw.githubusercontent.com/shdcn/easygentoo/master/easygentoo.config"
    
    fl "easygentoo.config" "0" "0"
    
    case ${arch} in
    i686)
        avoid_dup_kernel "CONFIG_64BIT=n"
    ;;
    amd64)
        avoid_dup_kernel "CONFIG_64BIT=y"
    ;;
    esac
    
    case ${keymap} in
    br)
        avoid_dup_kernel "CONFIG_FAT_DEFAULT_CODEPAGE=860"
    ;;
    trq|trf)
        avoid_dup_kernel "CONFIG_FAT_DEFAULT_CODEPAGE=857"
    ;;
    us)
        avoid_dup_kernel "CONFIG_FAT_DEFAULT_CODEPAGE=437"
    ;;
    esac
    
    case ${keymap} in
    trq|trf)
        avoid_dup_kernel "CONFIG_FAT_DEFAULT_IOCHARSET=\"iso8859-9\""
        avoid_dup_kernel "CONFIG_NLS_DEFAULT=\"iso8859-9\""
    ;;
    br|us)
        avoid_dup_kernel "CONFIG_FAT_DEFAULT_IOCHARSET=\"iso8859-1\""
        avoid_dup_kernel "CONFIG_NLS_DEFAULT=\"iso8859-1\""
    ;;
    esac
    
    mkdir -p /etc/kernels &>/dev/null

    cp easygentoo.config /etc/kernels
    
    echo; eb2 "* "; eg2 "Compiling kernel... "; er "(genkernel)"; echo; sleep 0.5s

    genkernel --bootdir=/boot --disklabel --install --kernel-config=/etc/kernels/easygentoo.config --kernname=easygentoo --makeopts=-j${core} --no-mountboot --postclear --save-config all
    
    case $? in
    0)
        e="x"
    ;;
    *)
        genkernel --bootdir=/boot --disklabel --install --kernel-config=/etc/kernels/easygentoo.config --kernname=easygentoo --makeopts=-j${core} --no-mountboot --postclear --save-config all
    ;;
    esac
    
    dlt "/boot/grub/grub.cfg"
    cp grub.eg /boot/grub/grub.cfg
}

e_grub() {
    cl
    case "${grub}" in
    none)
        e="x"
    ;;
    [s:h]d[a-z] | [s:h]d[a-z][1-9] | [s:h]d[a-z][1-9][0-9] | [s:h]d[a-z][1-9][0-9][0-9])
        step=$(eb2 "* "; eg2 "Emerging "; er2 "grub"; eg "...")
        inst "-u grub"
        
        echo; eg2 "  Installing grub to "; er2 "${grub}"; eg "..."; echo; sleep 0.5s
        
        [[ -n "${boot_part}" ]] && cp /proc/mounts /etc/mtab || grep -v rootfs /proc/mounts > /etc/mtab
        
        # [[ -e "/boot/grub/device.map" ]] && sed -i "\!.*fd[0-9].*!d" /boot/grub/device.map
        
        grub2-install --no-floppy /dev/${grub}
        
        mkdir -p /boot/grub/fonts/ &>/dev/null
        cp /usr/share/grub/unicode.pf2 /boot/grub/fonts/
        
        case $(echo ${grub} | cut -c 3-) in
        [a-z])
            dn="$(echo ${grub} | cut -c 3- | tr 'a-z' '0-26')"
        ;;
        [a-z][0-9])
            dn="$(echo ${grub} | cut -c 3- | cut -c -1 | tr 'a-z' '0-26')"
        ;;
        [a-z][0-9][0-9])
            dn="$(echo ${grub} | cut -c 3- | cut -c -2 | tr 'a-z' '0-26')"
        ;;
        esac
        
        if [ -n "${boot_part}" ]; then
            pn="$(echo ${boot_part} | cut -c 4-)"
        else
            pn="$(echo ${root_part} | cut -c 4-)"
        fi
        
        echo; eg2 "  Creating "; er2 "grub.cfg"; eg "..."; sleep 0.5s

        krnl="$(ls /boot/kernel-easygentoo*)"
        [[ -e "${krnl}" ]] && krnl2="/$(basename ${krnl})" || krnl2="/kernel-not-available"

        init="$(ls /boot/initramfs-easygentoo*)"
        [[ -e "${init}" ]] && init2="/$(basename ${init})" || init2="/initramfs-not-available"
        
        if [ -n "${boot_part}" ]; then
            kernel_line="linux ${krnl2}"
            init_line="initrd ${init2}"
        else
            kernel_line="linux ${krnl}"
            init_line="initrd ${init}"
        fi
        
        [[ -n "${swap_part}" ]] && kernel_line="${kernel_line} real_resume=LABEL=${swap_label}"
        kernel_line="${kernel_line} root=/dev/ram0 real_root=LABEL=${root_label} real_init=/usr/lib/systemd/systemd quiet systemd.show_status=1"
        
        case ${root_fs} in
        jfs)
            [[ -z "${boot_part}" ]] && kernel_line="${kernel_line} ro"
        ;;
        esac
        
        fl "grub.eg" "0" "d"
        
        cf '#This file is created by Easy Gentoo.'
        cf ' '
        cf 'set locale_dir=${prefix}/locale'
        cf "set lang="${lng}""
        cf ' '
        cf 'insmod vbe'
        cf 'insmod font'
        cf ' '
        cf 'if loadfont ${prefix}/fonts/unicode.pf2'
        cf 'then'
        cf '    insmod gfxterm'
        cf '    set gfxmode=1920x1080,1600x1200,1600x900,1600x768,1440x1080,1400x1050,1366x768,1280x1024,1280x800,1280x720,1024x768,auto'
        cf '    set gfxpayload=keep,text'
        cf '    terminal_output gfxterm'
        cf 'fi'
        cf ' '
        cf 'if sleep --interruptible 0 ; then'
        cf '    set timeout=10'
        cf 'fi'
        cf ' '
        cf 'set default="0"'
        cf ' '
        cf "menuentry 'Gentoo GNU/Linux' --class gentoo --class gnu-linux --class gnu --class os {"
        cf "    insmod gzio"
        cf "    insmod part_msdos"
        cf "    insmod ext2"
        cf "    set root=(hd"${dn}","${pn}")"
        cf "    ${kernel_line}"
        cf "    ${init_line}"
        cf '}'
        cf ' '
            case ${keymap} in
            br)
                cf 'menuentry "Desligar computador" {'
                cf '    echo "Computador está sendo desligado..."'
                cf '    halt'
                cf '}'
                cf ' '
                cf 'menuentry "Reiniciar computador" {'
                cf '    echo "Reiniciando computador..."'
                cf '    reboot'
                cf '}'
            ;;
            trq|trf)
                cf 'menuentry "Bilgisayarı kapat" {'
                cf '    echo "Bilgisayar kapatılıyor..."'
                cf '    halt'
                cf '}'
                cf ' '
                cf 'menuentry "Bilgisayarı yeniden başlat" {'
                cf '    echo "Bilgisayar yeniden başlatılıyor..."'
                cf '    reboot'
                cf '}'
            ;;
            us)
                cf 'menuentry "Shutdown computer" {'
                cf '    echo "Shutting down computer..."'
                cf '    halt'
                cf '}'
                cf ' '
                cf 'menuentry "Restart computer" {'
                cf '    echo "Restarting computer..."'
                cf '    reboot'
                cf '}'
            ;;
            esac
        cf ' '
        
        dlt "/boot/grub/grub.cfg"
        cp grub.eg /boot/grub/grub.cfg
    ;;
    esac
}

e_must() {
    cl
    step=$(eb2 "* "; eg2 "Emerging "; er2 "dhcpcd"; eg2 " and "; er2 "gentoolkit"; eg "...")
    inst "-u dhcpcd gentoolkit";
}

locale_gen() {
    fl "/etc/locale.gen" "0" "0"
    
    cf "${lng}.UTF-8 UTF-8"
    
    case ${keymap} in
    trq|trf)
        cf "${lng} ISO-8859-9"
    ;;
    *)
        cf "${lng} ISO-8859-1"
    ;;
    esac
    
    locale-gen &>/dev/null
}


vlist() {
    source "$(pwd)/${vl}"
}

start() {
    export SHELL=$(which bash); setterm -blank 0 -cursor on; cl
    
    eg="$(basename $0)"; profile="profile"; vl="variables"
    mnt="/mnt/gentoo"; egdir="egtmp"; megdir="${mnt}/${egdir}"
    lt="latest-stage3.txt"; compiled="compiled.txt"
    
    case ${install_step} in
    chroot)
        inside
    ;;
    *)
        intro; prepare; base_system; move
    ;;
    esac
}

intro() {
    (download2 "https://raw.githubusercontent.com/shdcn/easygentoo/master/LICENSE")
    
    cl; echo; echo
    echo; eg "  Welcome to Easy Gentoo!"
    echo
    echo; eg "  Copyright (c) 2014 Şehidcan Erdim"
    echo; eg "  Easy Gentoo is free software distributed under the terms of the MIT license."
    echo; eg "  For license details, see LICENSE or visit http://opensource.org/licenses/MIT"
    echo
    echo; ey "  Please make sure that your profile is configured the way you exactly need it."
    ey "  The setup is automated and not even a single key press is needed till the end (if everything goes as planned ^^).";
    echo
    echo; ew2 "  Press any key to continue..."
    echo; read -s -n1 key
    echo; eg "  Good luck ;)"; sleep 2s; cl
}

prepare() {
    rm -rf *.eg ${vl} &>/dev/null
    
    [[ ! -e "${profile}" ]] && { cl; er "  Looks like you don't have a profile. Please create one and start Easy Gentoo again."; echo; exit 1; }

    mkdir -p ${mnt} &>/dev/null
    
    echo "$(tr -s '[:blank:]' ' ' < ${profile})" > ${profile}
    
    necessary="awk basename bash chmod chroot clear cp cut dhcpcd grep ifconfig killall lsblk md5sum mkdir mount mv ping rm sed setterm sha512sum sleep tar touch tr umount uname uniq wget"
    progs="pcmciautils procps"
    
    rm -rf unmount.eg
    echo "normal=$'\e[0m'" >> unmount.eg
    echo "red=$'\e[31;01m'" >> unmount.eg
    echo "blue=$'\e[34;01m'" >> unmount.eg
    echo "yellow=$'\e[33;01m'" >> unmount.eg

    rm -rf format.eg
    echo "normal=$'\e[0m'" >> format.eg
    echo "red=$'\e[31;01m'" >> format.eg
    echo "blue=$'\e[34;01m'" >> format.eg
    echo "yellow=$'\e[33;01m'" >> format.eg
    
    rm -rf mount.eg
    echo "normal=$'\e[0m'" >> mount.eg
    echo "red=$'\e[31;01m'" >> mount.eg
    echo "blue=$'\e[34;01m'" >> mount.eg
    echo "yellow=$'\e[33;01m'" >> mount.eg
    
    rm -rf fstab.eg
    
    for g in root boot swap home extra
    do
        grep "^${g} " ${profile} >> temp.eg
    done
    
    fs_flags=""
    while read name part label fs mp
    do
        case ${part} in
        [s:h]d[a-z][0-9] | [s:h]d[a-z][0-9][0-9] | [s:h]d[a-z][0-9][0-9][0-9])
            case ${name} in
            root|boot|home|swap)
                case ${name} in
                boot)
                    fs="ext2"; mp="/boot"; dp="1 2"
                ;;
                home)
                    mp="/home"; dp="0 0"
                ;;
                root)
                    mp="/"; dp="0 1"
                ;;
                swap)
                    fs="swap"; mp="none"; dp="0 0"
                ;;
                esac
                
                read null size <<< "`lsblk -b -o KNAME,SIZE /dev/${part} | grep [s:h]d[a-z][0-9]`"
                a2v "${name}_part=\"${part}\"  ${name}_label=\"${label}\"  ${name}_fs=\"${fs}\"  ${name}_mp=\"${mp}\"  ${name}_size=\"${size}\""
            ;;
            extra)
                dp="0 0"
                
                case ${fs} in
                btrfs|ext2|ext3|ext4|ntfs|reiserfs|xfs)
                    e="x"
                ;;
                *)
                    fs="ext4"
                ;;
                esac
            ;;
            esac
            
            echo "${part} ${label} ${fs} ${mp}" >> partition_list.eg
            
            case ${fs} in
            btrfs)
                fsprogs="btrfs-progs"
            ;;
            ext2|ext3|ext4)
                fsprogs="e2fsprogs e2fsprogs-libs"
            ;;
            # nfs)
                # fsprogs="nfs-utils"
            # ;;
            ntfs)
                fsprogs="ntfs3g"
            ;;
            reiserfs)
                fsprogs="libaal reiserfsprogs"
            ;;
            xfs)
                fsprogs="xfsprogs"
            ;;
            esac
            
            [[ -z "$(echo "${progs}" | grep -w "${fsprogs}")" ]] && progs="${fsprogs} ${progs}"
            [[ -z "$(echo "${fs_flags}" | grep -w "${fs}")" ]] && { [[ -n "${fs_flags}" ]] && fs_flags="${fs} ${fs_flags}" || fs_flags="${fs}"; }
            [[ -z "$(echo "${necessary}" | grep -w "mkfs.${fs}")" ]] && [[ "${fs}" != "swap" ]] && necessary="mkfs.${fs} ${necessary}"
            
            case ${fs} in
            swap)
                prm="sw,noatime,loop"
            ;;
            btrfs)
                prm="noatime,autodefrag,noacl,compress=lzo,space_cache"
            ;;
            ext2|ext3|ext4|reiserfs)
                prm="noatime"
            ;;
            ntfs)
                prm="locale=${lng}.utf8,users,nls=utf8,umask=000"
            ;;
            xfs)
                prm="noatime,logbufs=8,logbsize=32k,osyncisdsync"
            ;;
            esac
            
            case "${fs}" in
            ntfs)
                echo "LABEL=${label}   ${mp}   ntfs-3g   ${prm}   ${dp}" >> fstab.eg
            ;;
            *)
                echo "LABEL=${label}   ${mp}   ${fs}   ${prm}   ${dp}" >> fstab.eg
            ;;
            esac
        ;;
        *)
            echo; er "  Please check partition names (hda4, sdc2, etc.) in your profile. Something seems wrong."; echo; exit 1
        ;;
        esac
    done < temp.eg
    
    rm -rf temp.eg
    
    a2v "fs_flags=\"${fs_flags}\""

    echo "shm    /dev/shm    tmpfs    nodev,nosuid,noexec    0 0" >> fstab.eg
    
    echo "$(sort -k4 partition_list.eg)" > partition_list.eg
    
    while read part label fs mp
    do
        echo 'echo -n ${red}"      * "; echo -n ${blue}"unmounting "; echo -n ${yellow}"'${part}' ('${mp}')"; echo ${blue}"..."${normal}; sleep 1s' >> unmount.eg
        
        case ${fs} in
        swap)
            echo "swapoff /dev/${part} &>/dev/null" >> unmount.eg
        ;;
        *)
            echo "umount -l /dev/${part} &>/dev/null" >> unmount.eg
        ;;
        esac
        
        echo "sleep 1s" >> unmount.eg
        echo " " >> unmount.eg
    done <<< "$(sort -rk4 partition_list.eg)"
    
    while read part label fs mp
    do
        echo 'echo -n ${red}"      * "; echo -n ${blue}"formatting "; echo -n ${yellow}"'${part}' ('${mp}')"; echo -n ${blue}" as "; echo -n ${yellow}"'${fs}'"; echo ${blue}"..."${normal}; sleep 1s' >> format.eg
        
        case ${fs} in
        swap)
            echo "mkswap -L ${label} /dev/${part} > /dev/null 2>&1" >> format.eg
        ;;
        btrfs)
            echo "mkfs.${fs} -f -L ${label} -s 1024 /dev/${part} > /dev/null 2>&1" >> format.eg
        ;;
        ext2|ext3|ext4)
            case ${mp} in
            "/"|"/usr/portage*")
                echo "mkfs.${fs} -L ${label} -b 1024 -T news /dev/${part} > /dev/null 2>&1" >> format.eg
            ;;
            *)
                echo "mkfs.${fs} -L ${label} -b 1024 /dev/${part} > /dev/null 2>&1" >> format.eg
            ;;
            esac
            
            case ${fs} in
            ext3)
                echo "tune2fs -c 0 -i 1m -I 256 -O dir_index,has_journal -o journal_data_ordered -m 1 /dev/${part} > /dev/null 2>&1" >> format.eg
                echo "e2fsck -fpDC0 /dev/${part} > /dev/null 2>&1" >> format.eg
            ;;
            ext4)
                echo "tune2fs -c 0 -i 1m -O dir_index,has_journal -o journal_data_ordered -m 1 /dev/${part} > /dev/null 2>&1" >> format.eg
                echo "e2fsck -fpDC0 /dev/${part} > /dev/null 2>&1" >> format.eg
            ;;
            esac
        ;;
        ntfs)
            echo "mkfs.${fs} -F -L ${label} --no-indexing -f /dev/${part} > /dev/null 2>&1" >> format.eg
        ;;
        reiserfs)
            echo "mkfs.${fs} -q -l ${label} /dev/${part} > /dev/null 2>&1" >> format.eg
        ;;
        xfs)
            echo "mkfs.${fs} -f -L ${label} -l internal,lazy-count=1,size=64m -d agcount=2 -n size=8k -i size=1024 /dev/${part} > /dev/null 2>&1 || 
            mkfs.${fs} -f -L ${label} -l internal,lazy-count=1,size=32m -d agcount=2 -n size=8k -i size=1024 /dev/${part} > /dev/null 2>&1 || 
            mkfs.${fs} -f -L ${label} -l internal,lazy-count=1 -n size=8k -i size=1024 /dev/${part} > /dev/null 2>&1" >> format.eg
        ;;
        esac
        
        echo " " >> format.eg
        
        case ${fs} in
        swap)
            echo 'echo -n ${red}"      * "; echo -n ${blue}"activating "; echo -n ${yellow}"'${part}'"; echo -n ${blue}" as "; echo -n ${yellow}"swap"; echo ${blue}"..."${normal}; sleep 1s' >> mount.eg
            echo "swapon /dev/${part} > /dev/null 2>&1" >> mount.eg
        ;;
        *)
            echo 'echo -n ${red}"      * "; echo -n ${blue}"mounting "; echo -n ${yellow}"'${part}'"; echo -n ${blue}" to "; echo -n ${yellow}"'${mp}'"; echo ${blue}"..."${normal}; sleep 1s' >> mount.eg
            echo "mkdir -p ${mnt}${mp} &>/dev/null" >> mount.eg
            echo "mount -t ${fs} /dev/${part} ${mnt}${mp} -o ${prm} > /dev/null 2>&1 || mount /dev/${part} ${mnt}${mp} > /dev/null 2>&1" >> mount.eg
        ;;
        esac
        
        echo " " >> mount.eg
    done < partition_list.eg
    
    chmod +x unmount.eg; chmod +x format.eg; chmod +x mount.eg
    
    for s in autonet arch blimit createbin domainname grub hostname keymap netadap rootpass setup type usebinfrom userflags username userpass
    do
        if [ -z "$(grep ^${s} ${profile})" ]; then
            default_value "${s}"
        else
            case ${s} in
            userflags)
                value="$(grep "^${s} " ${profile} | cut -d' ' -f2- | tr -s '[:blank:]' ' ' | tr  -d '+')"
            ;;
            *)
                grep "^${s} " ${profile} > settings.eg
                value="$(awk '{print $2}' settings.eg)"
            ;;
            esac
            
            case ${s} in
            autonet|createbin)
                case ${value} in
                yes|no)
                    e="x"
                ;;
                *)
                    default_value "${s}"
                ;;
                esac
            ;;
            arch)
                case ${value} in
                32|32bit|"32 bit"|i686)
                    value="i686"
                ;;
                64|64bit|"64 bit"|amd64)
                    # [[ "$(grep flags /proc/cpuinfo | grep ' lm ')" ]] && value="amd64" || value="i686"
                    [[ "$(uname -m)" == "x86_64" || "$(uname -m)" == "amd64" ]] && value="amd64" || value="i686"
                ;;
                *)
                    default_value "${s}"
                ;;
                esac
            ;;
            blimit)
                case ${value} in
                [0-9] | [0-9][0-9] | [0-9][0-9][0-9])
                    e="x"
                ;;
                [0-9][0-9][0-9][0-9] | [0-9][0-9][0-9][0-9][0-9])
                    e="x"
                ;;
                *)
                    default_value "${s}"
                ;;
                esac
            ;;
            grub)
                case ${value} in
                [s:h]d[a-z] | [s:h]d[a-z][1-9] | [s:h]d[a-z][1-9][0-9] | [s:h]d[a-z][1-9][0-9][0-9])
                    e="x"
                ;;
                *)
                    default_value "${s}"
                ;;
                esac
            ;;
            keymap)
                case ${value} in
                br)
                    a2v "lng=\"pt_BR\""
                ;;
                trq|trf)
                    a2v "lng=\"tr_TR\""
                ;;
                en)
                    value="us"; a2v "lng=\"en_US\""
                ;;
                us)
                    a2v "lng=\"en_US\""
                ;;
                tr)
                    value="trq"; a2v "lng=\"tr_TR\""
                ;;
                *)
                    default_value "${s}"
                ;;
                esac
            ;;
            setup)
                case ${value} in
                basic|normal)
                    e="x"
                ;;
                *)
                    default_value "${s}"
                ;;
                esac
            ;;
            type)
                case ${value} in
                laptop|pc)
                    e="x"
                ;;
                *)
                    default_value "${s}"
                ;;
                esac
            ;;
            esac
        fi
        
        [[ -n "${value}" ]] && a2v "${s}=\"${value}\""
    done
    
    core=$(grep -c processor /proc/cpuinfo)
    a2v "core=\"${core}\""

    case ${arch} in
    i686)
        kw="x86"
    ;;
    amd64)
        kw="amd64"
    ;;
    esac
    
    a2v "kw=\"${kw}\""
    
    find_flags
    
    ram_size="$(grep -i memtotal < /proc/meminfo | sed -e 's:.* \([0-9].* kb\):\1:i' -e 's: .*::')"
    
    a2v "ram_size=\"${ram_size}\""
    
    if ((root_size < 6442450944)); then
        echo; er "root partition (${root_part}) is smaller (`echo $((root_size/1024/1024/1024)) | bc -l` GB) than the recommended partition size (6 GB)."
        echo; er "This may cause some problems during setup. It is safer to choose/create a bigger partition for root."
        echo; er "Press any key if you want to ignore this and continue..."; echo; read -s -n1 key
    fi
    
    a2v "progs=\"${progs}\""
    
    echo; eb2 "* "; eg "Checking the existence of necessary tools..."; echo; sleep 0.5s
    
    for b in ${necessary}
    do
        exist "${b}"
    done
    
    if [ -n "${netadap}" ]; then
		adapter_list="${netadap}"
    else
		adapter_list="$(ifconfig | grep flags | grep -v 'lo:' | cut -d ':' -f1 | tr '\n' ' ')"
		
		[[ -z "${adapter_list}" ]] && which netstat &>/dev/null && adapter_list="$(netstat -i | grep [0-9] | cut -d ' ' -f1 | grep -v 'lo')"
	fi
	
	[[ -n "${adapter_list}" ]] && a2v "adapters_found=\"${adapter_list}\"" || { 
	echo; er "Looks like there aren't any network adapters. Setup is unable to continue. Exiting now..."
	echo; echo; exit 1; }
    
    echo; eb2 "* "; eg "Preparing partitions... "
    echo; ey "      --unmount"; sleep 0.5s; ./unmount.eg
    echo; ey "      --format"; sleep 0.5s; ./format.eg
    echo; ey "      --mount"; sleep 0.5s; ./mount.eg
    
    mkdir -p ${megdir} &>/dev/null
    
    [[ "${root_fs}" != "btrfs" ]] && create_swap_file
    
    cp ${eg} ${megdir} &>/dev/null
    cp ${profile} ${megdir} &>/dev/null
    mv ${vl} ${megdir} &>/dev/null
    mv *.eg ${megdir} &>/dev/null
    cp *.tar.bz2 ${megdir} &>/dev/null
    
    cd ${megdir}
}

default_value() {
    case ${1} in
    autonet)
        value="yes"
    ;;
    arch)
        # [[ "$(grep flags /proc/cpuinfo | grep ' lm ')" ]] && value="amd64" || value="i686"
        value="$(uname -m)"
        
        case ${value} in
        x86_64)
            value="amd64"
        ;;
        esac
    ;;
    blimit)
        value="0"
    ;;
    domainname)
        value="easygentoo"
    ;;
    grub)
        value="$(echo ${root_part} | sed s:[0-9].*::)"
    ;;
    hostname)
        value="freshinstall"
    ;;
    keymap)
        value="us"; a2v "lng=\"en_US\""
    ;;
    netadap)
		value=""
    ;;
    root)
        echo; er "  /root partition is not specified in profile. Please change your profile and start again."; echo; exit 1
    ;;
    rootpass)
        value="toor"
    ;;
    setup)
        value="basic"
    ;;
    type)
        value="pc"
    ;;
    createbin)
        value="no"
    ;;
    usebinfrom|userflags)
        value=""
    ;;
    username)
        value="owner"
    ;;
    userpass)
        value="resu"
    ;;
    esac
}

base_system() {
    refresh
    sed -i '\!^export ping_target=!d' ${vl}
    a2v "ping_target=\"www.google.com\""
    pong
    net_guard &
    mirror_check
    timesync
    
    until [ -e "tball.eg" ]
    do
        get_tarball
        
        case ${check} in
        ok)
            echo "${tarball}" > tball.eg
        ;;
        x)
            echo; er "  Looks like the server has a corrupted version of the file or there is a technical problem."
            echo; er "  Trying to download from another mirror..."; echo
            
            mirror_check "switch"
        ;;
        esac
    done
    
    xtract &
    
    until [ -e "sshot.eg" ]
    do
        get_portage
        
        case ${check} in
        ok)
            echo "${p}" > sshot.eg
        ;;
        x)
            echo; er "  Looks like the server has a corrupted version of the file or there is a technical problem."
            echo; er "  Trying to download from another mirror..."; echo
            
            mirror_check "switch"
        ;;
        esac
    done
    
    sed -i '\!^export protect=!d' ${vl}
    a2v "protect=\"no\""
    
    [[ ! -e "move.eg" ]] && { echo; eb2 "* "; ey "Extracting downloaded files, this may take a while..."; echo; }
    
    while true
    do
        [[ -e "tball.done" ]] && { read t < tball.eg; eg2 "  ${t}"; ew " is successfully extracted."; break; } || sleep 1s
    done
    
    while true
    do
        [[ -e "sshot.done" ]] && { read p < sshot.eg; eg2 "  ${p}"; ew " is successfully extracted."; break; } || sleep 1s
    done

    until [ -e "move.eg" ]
    do
        sleep 1s
    done
    
    if [ -z "$(grep '/usr/portage/distfiles$' partition_list.eg)" ]; then
        mkdir -p ${mnt}/var/lib/distfiles &>/dev/null
        rm -rf ${mnt}/usr/portage/distfiles &>/dev/null
        ln -s ${mnt}/var/lib/distfiles/ ${mnt}/usr/portage/distfiles &>/dev/null
        tch "distfileslinked.eg"
    fi
    
    if [ -z "$(grep '/usr/portage/packages$' partition_list.eg)" ]; then
        mkdir -p ${mnt}/var/lib/packages &>/dev/null
        rm -rf ${mnt}/usr/portage/packages &>/dev/null
        ln -s ${mnt}/var/lib/packages ${mnt}/usr/portage/packages &>/dev/null
        tch "packageslinked.eg"
    fi
    
    if [ -n "${usebinfrom}" ]; then
        case ${usebinfrom} in
        */)
            cp -r ${usebinfrom}* /${mnt}/usr/portage/packages/ &>/dev/null
        ;;
        *)
            cp -r ${usebinfrom}/* /${mnt}/usr/portage/packages/ &>/dev/null
        ;;
        esac
    fi
}

xtract() {
    echo
    until [ -e "tball.eg" ]
    do
        sleep 1s
    done
    
    read t < tball.eg
    tar --numeric-owner -xjpf ${t} -C ${mnt} && touch tball.done
    
    until [ -e "sshot.eg" ]
    do
        sleep 1s
    done
    
    mkdir -p ${mnt}/usr
    
    read p < sshot.eg
    tar --numeric-owner -xjf ${p} -C ${mnt}/usr && touch sshot.done

    touch move.eg
}

get_tarball() {
    echo; eb2 "* "; eg "Getting latest tarball name..."; sleep 0.5s
    
    [[ -e "${lt}" ]] && rm -rf ${lt}
    download "latest"
    
    while read lt_line
    do
    	date="${lt_line:0:8}"
        if [ "${lt_line}" == *"${date}/stage3-${arch}-${date}.tar.bz2"* ]; then 
        	tarball="stage3-${arch}-${date}.tar.bz2" && break
        fi
    done < "${lt}"
    
    a2v "tarball=\"${tarball}\""
    
    en2 "  Latest tarball:"; ey "  ${tarball}"; sleep 0.5s
    
    if [ -e "${tarball}" ]; then
        echo; eb2 "* "; ew2 "stage3-${arch} tarball exists. "; eg "(previously downloaded)"
    else
        echo; eb2 "* "; er "Downloading stage3-${arch} tarball... "
        download "tarball"
    fi
    
    ey2 "  Checking tarball integrity... "
    
    t_sum="${tarball}.DIGESTS"
    [[ -e "${t_sum}" ]] && rm -rf ${t_sum}
    download "tsum"; echo "$(grep "${tarball}" "${t_sum}" | sed 1q)" > ${t_sum}
    csum "${t_sum}" "${tarball}"
}

get_portage() {
    p="portage-latest.tar.bz2"
    
    if [ -e "${p}" ]; then
        echo; eb2 "* "; ew2 "portage snapshot exists. "; eg "(previously downloaded)"
    else
        echo; eb2 "* "; er "Downloading portage snapshot... "
        download "snapshot"
    fi
    
    ey2 "  Checking portage snapshot integrity... "
    
    p_sum="${p}.md5sum"
    [[ -e "${p_sum}" ]] && rm -rf ${p_sum}
    download "psum"
    csum "${p_sum}" "${p}"
}

move() {
    cp -dpRL /dev/{console,kmem,mem,null,urandom,random,zero,ptmx,ram[0-6],tty[0-6]} ${mnt}/dev &>/dev/null
    [[ -e "${mnt}/etc/resolv.conf" ]] && cp ${mnt}/etc/resolv.conf ${mnt}/etc/resolv.conf.backup && rm -rf ${mnt}/etc/resolv.conf
    
    cp -L /etc/resolv.conf ${mnt}/etc/

    mkdir -p ${mnt}/etc/portage &>/dev/null
    
    for u in "dev/pts" "dev" "sys" "proc"
    do
        umount -l ${mnt}/$u &>/dev/null
        sleep 1s
    done
    
    for m in "proc" "sys" "dev" "dev/pts"
    do
        mount -R /$m ${mnt}/$m &>/dev/null
    done
    
    chroot ${mnt} $(which env) -i TERM=$TERM ./${egdir}/${eg} "chroot"
}

create_swap_file() {
    min_ram="2097152"
    [[ -n "${swap_size}" ]] && total_ram="$((ram_size + swap_size))" || total_ram="${ram_size}"
    
    ((total_ram < min_ram)) && swap_file_size="$((min_ram - total_ram))"
    
    min_root_size="$((6442450944 + swap_file_size))"
    
    if ((root_size >= min_root_size)) && ((swap_file_size >= 262144)); then
        egswap="/${egdir}/egswap"
        a2v "egswap=\"${egswap}\""
        
        swap_file_size_m=`echo $((swap_file_size/1024)) | bc -l`
        
        echo; eb2 "* "; eg2 "Creating a swap file"; er " (${swap_file_size_m} MB)"; sleep 0.5s
        
        dd if=/dev/zero of=${mnt}${egswap} bs=1024 count=${swap_file_size_m}K &>/dev/null
        
        chmod 600 ${mnt}${egswap}
        mkswap ${mnt}${egswap} &>/dev/null
        swapon ${mnt}${egswap} &>/dev/null
        a2v "swap_file_size=\"${swap_file_size}\""
    else
        a2v "swap_file_size=\"0\""
    fi
    
    # if (( ram_size < 262144000 )); then
        # tmpfs_size="0"
    # elif (( ram_size >= 262144000 )) && (( ram_size < 524288000 )); then
        # tmpfs_size=`echo $((ram_size*60/100/1024/1024)) | bc -l`
    # elif (( ram_size >= 524288000 )) && (( ram_size < 996147200 )); then
        # tmpfs_size=`echo $((ram_size*70/100/1024/1024)) | bc -l`
    # elif (( ram_size >= 996147200 )); then
        # tmpfs_size=`echo $((ram_size*80/100/1024/1024)) | bc -l`
    # fi
}

shut() {
    [[ -e "abortmission.eg" ]] && break
}

inside() {
    [[ -e "abortmission.eg" ]] && rm -rf abortmission.eg
    cd /${egdir}
    touch ${compiled}
    
    sed -i '\!^export protect=!d' ${vl}
    a2v "protect=\"yes\""
    
    refresh
    on_off &
    net_guard &
    
    if [ -n "${swap_part}" ]; then
        watch_swap_part &
    else
        (( swap_size > 0 )) && watch_swap_file &
    fi
    
    echo; eg "  !!--Chroot--!!"
    timesync
    #hostname "${hostname}"
    
    fl "/etc/etc-update.conf" "0" "0"
    
    avoid_dup 'rm_opts=""'
    avoid_dup 'cp_opts=""'

    refresh
    tidy="/home/${username}/easygentoo"
    
    case ${type} in
    pc)
        echo 0 > /proc/sys/vm/laptop_mode
        echo 600 > /proc/sys/vm/dirty_expire_centisecs
        echo 600 > /proc/sys/vm/dirty_writeback_centisecs
        echo 5 > /proc/sys/vm/dirty_background_ratio
        echo 20 > /proc/sys/vm/dirty_ratio
    ;;
    laptop)
        echo 1 > /proc/sys/vm/laptop_mode
    ;;
    esac
    
    echo 50 > /proc/sys/vm/vfs_cache_pressure
    echo 1 > /proc/sys/vm/swappiness
    
    temp_make_conf
    custom_cflags
    e_portage
    e_must
    locale_gen
    real_make_conf
    package_use
    e_pp
    e_system
    e_kernel
    e_grub
    e_needed
    sys_config
    desktop_env
    e_check
    end
}