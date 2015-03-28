#############################################################################
#   Library:                Gentoo Network  
#   Application:            AutoGentoo
#   By:                     William Moore
#   Lib Version:            0.1
#   Copyright:              2015
#   License:                GPLv3   http://opensource.org/licenses/GPL-3.0
#############################################################################

loadlanguagefile(){
    case ${envlanguage} in
    en-US)
        . "$dir/locale/en_us.autogentoo.content.locale"
    ;;
#    )
#    ;;
    esac
}