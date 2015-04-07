#!/bin/bash

#################################
# ----------------------------- #
#          Easy Gentoo          #
# ----------------------------- #
#################################

# Gentoo Linux installation script
# https://github.com/shdcn/easygentoo

# Copyright (c) 2014 Şehidcan Erdim
# Easy Gentoo is free software distributed under the terms of the MIT license.
# For license details, see LICENSE or visit http://opensource.org/licenses/MIT

normal=$'\e[0m'; red=$'\e[31;01m'; green=$'\e[32;01m'; yellow=$'\e[33;01m'
blue=$'\e[34;01m'; pink=$'\e[35;01m'; cyan=$'\e[36;01m'; white=$'\e[37;01m'

en() { echo "${normal}${*}${normal}";} ; er() { echo "${red}${*}${normal}";}
eg() { echo "${green}${*}${normal}";} ; ey() { echo "${yellow}${*}${normal}";}
eb() { echo "${blue}${*}${normal}";} ; ep() { echo "${pink}${*}${normal}";}
ec() { echo "${cyan}${*}${normal}";} ; ew() { echo "${white}${*}${normal}";}

en2() { echo -n "${normal}${*}${normal}";} ; er2() { echo -n "${red}${*}${normal}";}
eg2() { echo -n "${green}${*}${normal}";} ; ey2() { echo -n "${yellow}${*}${normal}";}
eb2() { echo -n "${blue}${*}${normal}";} ; ep2() { echo -n "${pink}${*}${normal}";}
ec2() { echo -n "${cyan}${*}${normal}";} ; ew2() { echo -n "${white}${*}${normal}";}

cl() { clear; echo;}

exist() {
    which ${1} &>/dev/null && { ey2 "  * "; eb2 "${1}"; en " exists"; sleep 0.1s; } || { er2 "  * "; eb2 "${1}"; er " doesn't exist"; echo; er "Some tools are missing - Please use a different install media/environment"
    echo; exit 1; }
}

find_flags() {
    cpu_inst="$(grep flags /proc/cpuinfo | uniq | tr -s '[:blank:]' ' ' | cut -d':' -f2)"
    flags_list="3dnow 3dnowext mmx mmxext sse sse2 sse3 sse4 sse4a sse4_1 sse4_2 sse5 ssse3"

    for v in ${flags_list}
    do
        echo "${cpu_inst}" | grep -o -w "${v}" >> flags.eg
    done

    echo "${cpu_inst}" | grep -o -w "pni" &>/dev/null && echo "sse3" >> flags.eg

    a2v "available_cpu_flags=\"$(tr '\n' ' ' < flags.eg | sed -e 's:^[ \t]*::' -e 's:[ \t]*$::')\""
}

fl() {
    trg_file="${1}"

    mkdir -p $(dirname ${trg_file}) &>/dev/null

    if [ -e "${trg_file}" ]; then
        case ${2} in
        b)
            cp "${trg_file}" "${trg_file}".backup
        ;;
        esac

        case ${3} in
        d)
            rm -rf "${trg_file}"
        ;;
        esac
    else
        touch "${trg_file}"
    fi
}

avoid_dup() {
    if [ -n "${@}" ] && [ -n "${trg_file}" ]; then
        allofit="${@}"
        nameonly="$(echo ${allofit} | cut -d'=' -f1)"
        if [ -n "$(grep "^${nameonly}" ${trg_file})" ];then
            sed -i s:"^${nameonly}=.*":"${allofit}": ${trg_file}
        else
            echo "${allofit}" >> ${trg_file}
        fi
    fi
}

avoid_dup_kernel() {
    if [ -n "${@}" ] && [ -n "${trg_file}" ]; then
        allofit="${@}"
        nameonly="$(echo ${allofit} | cut -d'=' -f1)"
        sed -i "\!^#.*${nameonly}.*!d" ${trg_file}
        sed -i "\!^${nameonly}=.*!d" ${trg_file}
        echo "${allofit}" >> ${trg_file}
    fi
}

cf() {
    [[ -n "${trg_file}" ]] && echo "$@" >> ${trg_file}
}

a2v() {
    echo "export $@" >> "${vl}"; vlist
}

csum() {
    sumfile="${1}"; file2check="${2}"

    case ${sumfile} in
    *.md5sum)
        md5sum -c ${sumfile}
    ;;
    *.DIGESTS)
        sha512sum -c ${sumfile}
    ;;
    esac

    case $? in
    0)
        check="ok"; sleep 0.5s
    ;;
    *)
        check="x"; rm -rf ${file2check}; echo; er "  File is corrupted or outdated."
    ;;
    esac
}

tch() {
    f2t="${1}"
    [[ ! -e "${f2t}" ]] && touch "${f2t}"
    unset f2t
}

dlt() {
    f2d="${1}"
    [[ -e "${f2d}" ]] && rm -rf "${f2d}"
    unset f2d
}

on_off() {
    while true
    do
        [[ "$(ps a -o cmd | grep "${eg}" | grep -v grep)" ]] && sleep 30s || { tch abortmission.eg; break; }
    done
}

pong() {
    if [ "$(ping -nc1 -i1 -W3 -B ${ping_target})" ]; then
        tch "connected.eg"
    else
        sleep 1s
        if [ "$(ping -nc3 -i1 -W3 -B ${ping_target})" ]; then
            tch "connected.eg"
        else
            dlt "connected.eg"
        fi
    fi
}

net_guard() {
    while true
    do
        [[ -e "abortmission.eg" ]] && break
        [[ "${protect}" == "no" ]] && break
        pong
        if [ ! -e "connected.eg" ]; then
            if [ "${autonet}" == "yes" ]; then
                killall ping dhcpcd ifconfig ip &>/dev/null
                killall ping dhcpcd ifconfig ip &>/dev/null
                killall ping dhcpcd ifconfig ip &>/dev/null

                for adapter in ${adapters_found}
                do
                    which ip &>/dev/null && { ip link set ${adapter} down &>/dev/null; sleep 2s; ip link set ${adapter} up &>/dev/null; sleep 2s; } || {
                    ifconfig ${adapter} down &>/dev/null; sleep 2s; ifconfig ${adapter} up &>/dev/null; sleep 2s; }
                    dlt "/var/run/dhcpcd-${adapter}.pid"
                    sleep 5s; dhcpcd ${adapter} &>/dev/null; sleep 10s

                    pong

                    if [ -e "connected.eg" ]; then
                        breakw
                    fi
                done

                pong

                if [ ! -e "connected.eg" ]; then
                    echo; er "Looks like your internet connection is down. Please check your modem/router."
                    er "Easy Gentoo will try again every 30 seconds."; echo

                    sleep 30s
                fi
            else
                echo; er "Looks like your internet connection is down. Please fix it using another console (Alt + Function Keys)."
                er "Easy Gentoo will check your connection status every 10 seconds until the problem is gone."; echo

                while true
                do
                    pong

                    if [ -e "connected.eg" ]; then
                        break
                    else
                        sleep 10s
                    fi
                done
            fi
        else
            sleep 60s
        fi
    done
}

mirror_check() {
    case ${1} in
    switch)
        newmirrorlist="$(echo ${mirrorlist} | cut -d' ' -f2-) $(echo ${mirrorlist} | cut -d' ' -f1)"
        newmirror="$(echo ${mirrorlist} | cut -d' ' -f1)"

        sed -i '\!^export mirrorlist=!d' ${vl}
        sed -i '\!^export mirror=!d' ${vl}

        a2v "mirrorlist=\"${newmirrorlist}\""
        a2v "mirror=\"${newmirror}\""
    ;;
    *)
        if [ -e "connected.eg" ]; then
            stat_file="download_times.eg"
            test_file="CX2.zip"
            #~ test_file="amarachthemepack.zip"
            test_file_target="distfiles/${test_file}"

            rm -rf ${test_file}
            touch ${stat_file}

            eb2 "* "; eg "Testing Gentoo mirrors..."; sleep 0.5s

            #mirrorlist="http://gentoo.mirrors.tera-byte.com/ http://ftp.ucsb.edu/pub/mirrors/linux/gentoo/ http://mirrors.rit.edu/gentoo/"
            #mirrorlist="${mirrorlist} http://gentoo.localhost.net.ar/ http://www.las.ic.unicamp.br/pub/gentoo/ http://gd.tuwien.ac.at/opsys/linux/gentoo/"
            #mirrorlist="${mirrorlist} http://mirrors.telepoint.bg/gentoo/ http://gentoo.mirror.web4u.cz/ http://gentoo.wheel.sk/"
            #mirrorlist="${mirrorlist} http://ftp-stud.hs-esslingen.de/pub/Mirrors/gentoo/ http://mirrors.xservers.ro/gentoo/"
            #mirrorlist="${mirrorlist} http://gentoo-euetib.upc.es/mirror/gentoo/ http://ftp.df.lth.se/pub/gentoo/ http://gentoo.kiev.ua/ftp/"
            #mirrorlist="${mirrorlist} http://mirrors.stuhome.net/gentoo/ ftp://mirrors.linuxant.fr/distfiles.gentoo.org"
            #mirrorlist="${mirrorlist} http://gentoo.bloodhost.ru/ http://ftp.kaist.ac.kr/gentoo/ http://mirror.isoc.org.il/pub/gentoo/"
            #mirrorlist="${mirrorlist} http://files.gentoo.gr/ http://gentoo.prz.rzeszow.pl/ http://ftp.dei.uc.pt/pub/linux/gentoo/"
            #US Lists
            mirrorlist="http://mirror.usu.edu/mirrors/gentoo/ http://seal.cs.uni.edu/ http://gentoo.cites.uiuc.edu/pub/gentoo/"
            mirrorlist="${mirrorlist} http://mirror.lug.udel.edu/pub/gentoo/ http://ftp.ucsb.edu/pub/mirrors/linux/gentoo/"
            mirrorlist="${mirrorlist} http://gentoo.mirrors.tds.net/gentoo/ http://gentoo.llarian.net/ http://mirror.iawnet.sandia.gov/gentoo/"
            mirrorlist="${mirrorlist} http://mirrors.rit.edu/gentoo/ http://gentoo.mirrors.pair.com/ http://gentoo.osuosl.org/ http://gentoo.netnitco.net/"
            mirrorlist="${mirrorlist} http://lug.mtu.edu/gentoo/ http://gentoo.mirrors.hoobly.com/ http://www.gtlib.gatech.edu/pub/gentoo/"
            mirrorlist="${mirrorlist} http://gentoo.mirrors.easynews.com/linux/gentoo/"

            mno="1"
            for mrr in ${mirrorlist}
            do
                (( mno < 10 )) && { er2 "      ${mno}- "; eb "${mrr}"; } || { er2 "     ${mno}- "; eb "${mrr}"; }

                read info1 info2 <<< "$( { time -p download2 ${mrr}${test_file_target}; } 2>&1 | grep real )"
                [[ -e "download.done" ]] && echo "${info2} ${mrr}" >> ${stat_file}

                rm -rf ${test_file}

                ((mno++))
            done
            unset mno

            echo; ey "  Choosing 5 fastest mirrors..."; sleep 0.5s

            while read info3 info4
            do
                if [ -n "${info4}" ]; then
                    if [ -z "${fastest_mirrors}" ]; then
                        fastest_mirrors="${info4}"
                        first_mirror="${info4}"
                    else
                        fastest_mirrors="${fastest_mirrors} ${info4}"
                    fi
                fi
            done <<< "$(sort -n ${stat_file} | sed 5q)"

            sed -i '\!^export mirrorlist=!d' ${vl}
            sed -i '\!^export mirror=!d' ${vl}
            sed -i '\!^export ping_target=!d' ${vl}

            a2v "mirrorlist=\"${fastest_mirrors}\""
            a2v "mirror=\"${first_mirror}\""
            # Trimming mirror name. Ex. http://gentoo.kiev.ua/ftp -->> gentoo.kiev.ua
            a2v "ping_target=\"$(echo ${mirror} | sed -e 's/.*\:\/\///' -e 's/\/.*$//')\""
        fi
    ;;
    esac

    case ${arch} in
    i686)
        tarballurl="${mirror}releases/x86/autobuilds"
    ;;
    amd64)
        tarballurl="${mirror}releases/amd64/autobuilds"
    ;;
    esac

    snapshoturl="${mirror}snapshots"
}

watch_swap_part() {
    # checks swap space every 5 seconds and keeps a record of peak usage to report later
    msu="0"
    while true
    do
        [[ -e "abortmission.eg" ]] && break
        read name type size used priority <<< "$(swapon -s | grep ${swap_part})"
        (( used > msu )) && { sed -i '\!^export msu=!d' ${vl}; a2v "msu=\"${used}\""; }
        sleep 5s
    done
}

watch_swap_file() {
    # checks swap space every 5 seconds and keeps a record of peak usage to report later
    msu="0"
    while true
    do
        [[ -e "abortmission.eg" ]] && break
        read name type size used priority <<< "$(swapon -s | grep /dev/[s:h]d[a-z][0-9]*)"
        (( used > msu )) && { sed -i '\!^export msu=!d' ${vl}; a2v "msu=\"${used}\""; }
        sleep 5s
    done
}

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

download() {
    # file download function
    download_status=""
    request="${1}"

    while true
    do
        shut

        case ${request} in
        latest)
            lnk="${tarballurl}/${lt}"; arg=""
        ;;
        psum)
            lnk="${snapshoturl}/${p_sum}"; arg=""
        ;;
        snapshot)
            lnk="${snapshoturl}/${p}"; arg="1"
        ;;
        tarball)
            lnk="${tarballurl}/${date}/${tarball}"; arg="1"
        ;;
        tsum)
            lnk="${tarballurl}/${date}/${t_sum}"; arg=""
        ;;
        *)
            lnk="${request}"; arg=""
        ;;
        esac

        # determines base filename to use as a "save as" parameter in wget
        bname="$(basename $(echo ${lnk} | sed -e 's:^.*\:\/\/::' -e 's: .*::'))"

        if [ -n "${arg}" ]; then
            if [ "${blimit}" -gt "0" ]; then
                wget --limit-rate=${blimit}k --timeout=15 --tries=2 --waitretry=5 ${lnk} -O ${bname}
            else
                wget --timeout=15 --tries=2 --waitretry=5 ${lnk} -O ${bname}
            fi
        else
            if [ "${blimit}" -gt "0" ]; then
                wget --limit-rate=${blimit}k --timeout=15 --tries=2 --waitretry=5 ${lnk} -O ${bname} &>/dev/null
            else
                wget --timeout=15 --tries=2 --waitretry=5 ${lnk} -O ${bname} &>/dev/null
            fi
        fi

        case $? in
        0)
            download_status="OK"; break
        ;;
        *)
            echo; er "  We are having trouble downloading from current mirror."
            echo; er "  Switching to another mirror..."; echo; sleep 1s
            mirror_check "switch"
        ;;
        esac

        sleep 5s
    done

    [[ -e "abortmission.eg" ]] && { echo; er "There are no available mirrors or setup was cancelled."; er "Exiting..."; echo; exit 1; }
}

download2() {
    # simpler file download function
    unset lnk
    lnk="${1}"
    bname="$(basename $(echo ${lnk} | sed -e 's:^.*\:\/\/::' -e 's: .*::'))"

    [[ -e download.done ]] && rm -rf download.done

    wget --timeout=3 --tries=3 --waitretry=3 ${lnk} -O ${bname} &>/dev/null && touch download.done
}

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

set_gcc() {
    gcc-config -l | awk '{print $2}' > gcc.eg
    gcc_latest="$(sort -r gcc.eg | sed q)"
    gcc-config ${gcc_latest} &>/dev/null || gcc-config ${gcc_latest} &>/dev/null
    rm -rf gcc.eg
}

timesync() {
    which ntpdate &>/dev/null && { echo; eb2 "* "; eg "ntpdate -b -u pool.ntp.org"; echo; ntpdate -b -u pool.ntp.org; } || { which sntp &>/dev/null && sntp -t10 pool.ntp.org &>/dev/null; }
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

e_nm() {
    cl
    step=$(eb2 "* "; eg2 "Emerging "; er2 "NetworkManager"; eg "...")
    inst "-u networkmanager nm-applet"

    systemctl enable NetworkManager.service &>/dev/null
    systemctl disable dhcpcd.service &>/dev/null

    fl "/usr/share/polkit-1/actions/org.freedesktop.NetworkManager.policy" "b" "0"
    sed -i s/"<allow_active>.*<\/allow_active>"/"<allow_active>yes<\/allow_active>"/ ${trg_file}
}

e_alsa() {
    cl
    step=$(eb2 "* "; eg2 "Emerging "; er2 "alsa-utils"; eg "...")
    inst "-u alsa-utils"
    systemctl enable alsa-store.service
    systemctl enable alsa-restore.socket

    sound_card_guess="$(aplay -l | grep card | awk '{print $3}' | grep -iv dummy | grep -iv pcsp | uniq | sed q)"

    if [ -n "${sound_card_guess}" ]; then
        echo "pcm.!default { type hw card ${sound_card_guess} }" > /etc/asound.conf
        echo "ctl.!default { type hw card ${sound_card_guess} }" >> /etc/asound.conf
    fi

    fl "/etc/conf.d/alsasound" "0" "0"
    avoid_dup 'RESTORE_ON_START="yes"'
    avoid_dup 'SAVE_ON_STOP="yes"'
    avoid_dup 'LOAD_ON_START="yes"'

    amixer set Master unmute
    amixer set PCM unmute

    alsactl -f /var/lib/alsa/asound.state store
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

install_step="${1}"

start

exit 0
