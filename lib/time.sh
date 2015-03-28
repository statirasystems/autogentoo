#############################################################################
#   Library:                Time   
#   Application:            AutoGentoo
#   By:                     William Moore
#   Lib Version:            0.1
#   Copyright:              2015
#   License:                GPLv3   http://opensource.org/licenses/GPL-3.0
#############################################################################

settime(){

}

timesync() {
    which ntpdate &>/dev/null && { echo; eb2 "* "; eg "ntpdate -b -u pool.ntp.org"; echo; ntpdate -b -u pool.ntp.org; } || { which sntp &>/dev/null && sntp -t10 pool.ntp.org &>/dev/null; }
}