

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

