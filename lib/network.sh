#############################################################################
#   Library:                Network  
#   Application:            AutoGentoo
#   By:                     William Moore
#   Lib Version:            0.1
#   Copyright:              2015
#   License:                GPLv3   http://opensource.org/licenses/GPL-3.0
#############################################################################
# All functions and variables for networking


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