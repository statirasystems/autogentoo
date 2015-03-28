

#Checks for files required for install
exist() {
    which ${1} &>/dev/null && { ey2 "  * "; eb2 "${1}"; en " exists"; sleep 0.1s; } || { er2 "  * "; eb2 "${1}"; er " doesn't exist"; echo; er "Some tools are missing - Please use a different install media/environment"
    echo; exit 1; }
}

#File Loader and creater
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

#Duplicate file checker
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
