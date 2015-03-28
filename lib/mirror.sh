
#Get the current list of mirrors
get_mirrorlist(){
    wget https://api.gentoo.org/mirrors/distfiles.xml -O ./working/mirrors.xml
}



# Read the xml file and find content between the ><
read_dom () {
    local IFS=\>
    read -d \< entity content
    local ret=$?
    tag_name=${entity%% *}
    attributes=${entity#* }
    return $ret
}

# Read the returned value of read_dom and check for desired values
parse_dom () {
    if [[ $tag_name = "mirrorgroup" ]] ; then
        eval local $attributes
	if [[ $region = "North America" ]] ; then
	    region_hold="false"
	else
	    region_hold="true"
	fi
    fi

    if [[ $region_hold = "false" ]] ; then
        if [[ $tag_name = "uri" ]] ; then
            eval local $attributes
            ing=$((${#content}-1))
            if [[ ${content:$ing:1} != "/" ]] ; then
                content+="/"
            fi
	    case ${protocol} in
	    http)
		#Store in http.mirror temp file
		echo $content >> ./working/http.mirror
	    ;;
	    rsync)
		#Store in rsync.mirror temp file
		echo $content >> ./working/rsync.mirror
	    ;;
	    ftp)
		#Store in ftp.mirror temp file
		echo $content >> ./working/ftp.mirror
	    ;;
            esac
        fi
    fi

}


#Clean the mirror list for usage
clean_mirrorlist(){
    echo "#HTTP" > ./working/http.mirror
    echo "#FTP" > ./working/ftp.mirror
    echo "#RSYNC" > ./working/rsync.mirror

    while read_dom; do
        parse_dom
    done < ./working/mirrors.xml
}

#Test the mirrors for best options
test_mirrors(){
        if [ -e "connected.eg" ]; then
            stat_file="download_times.eg"
            test_file="CX2.zip"
            #~ test_file="amarachthemepack.zip"
            test_file_target="distfiles/${test_file}"
            
            rm -rf ${test_file}
            touch ${stat_file}
            
            eb2 "* "; eg "Testing Gentoo mirrors..."; sleep 0.5s
            
            #Make list from ./working/http.mirrors
            while read line           
            do           
                mirrorlist+="$line"           
            done < ./working/http.mirrors             
            
            
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
}

switch_mirror(){

        newmirrorlist="$(echo ${mirrorlist} | cut -d' ' -f2-) $(echo ${mirrorlist} | cut -d' ' -f1)"
        newmirror="$(echo ${mirrorlist} | cut -d' ' -f1)"
        
        sed -i '\!^export mirrorlist=!d' ${vl}
        sed -i '\!^export mirror=!d' ${vl}
        
        a2v "mirrorlist=\"${newmirrorlist}\""
        a2v "mirror=\"${newmirror}\""
}
