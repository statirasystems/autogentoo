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