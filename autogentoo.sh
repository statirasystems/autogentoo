#!/bin/bash

#############################################################################
#   Application:            AutoGentoo
#   By:                     William Moore
#   Company:                Statira Systems
#   Version:                0.1
#   Edit Count:             13
#   Created:                00. 30. 14. 22. 03. 2015. (SSMMHHDDMMYYYY)
#   Copyright:              2015
#   License:                GPLv3   http://opensource.org/licenses/GPL-3.0
#
#   File:                   autogentoo
#   Usage:
#   Description:
#
#   Options:
#   Requirements:
#
#############################################################################

#   Load and attach config, lib, and locale files
    dir="${BASH_SOURCE%/*}"
    if [[ ! -d "$dir" ]]; then dir="$PWD"; fi

#Include section

    # Lib files
    . "$dir/lib/security"
    . "$dir/lib/time"
    . "$dir/lib/gentoo_network"
    . "$dir/lib/locale"
    . "$dir/lib/mirror
    . "$dir/lib/colorscheme"
    
#Load Locale/Language Files
    envlanguage="printenv | grep 'LANG' | cut -c6-10"
    

#Mirrors
get_mirrorlist
clean_mirrorlist
test_mirrors

#Switching mirror due to problems 
#switch_mirror

# Main run command from original
install_step="${1}"
start
exit 0