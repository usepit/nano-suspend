#!/bin/bash

# Creator:
#   U$ePit
#   GitHub: https://github.com/usepit
#   Creation date:  17-11-2021

#Setting up as a service
#sudo su
#nano /etc/systemd/system/nanosuspend.service
#Paste in this content:

#[Unit]
#Description=Suspend script
#After=pulseaudio
#[Service]
#Type=simple
#ExecStart=/path/to/nanosuspend.sh
#Restart=on-failure
#[Install]
#WantedBy=multi-user.target

#Ctrl-O, save, and update systemd with:

#chmod +x /path/to/nanosuspend.sh
#systemctl daemon-reload
#systemctl enable nanosuspend.service
#systemctl start nanosuspend.service

# Time between each check
sleepValue=5;

# Idle seconds before suspending
startAt=120;

# Please open all the programs you normally have open, make sure no sounds are being played, and run this command:
#   pacmd list-sinks | grep -c 'state: RUNNING'
# This will be your baseline of running sound processes.

noSoundValue=0

# Declarations
idleSoundTimer=0;
suspendState=0;

while :; do

    # Current audio processes
    idleSound=$(sudo -u '#1000' XDG_RUNTIME_DIR=/run/user/1000 pactl list | grep -c 'State: RUNNING');

    # Idle screen in ms
    tempidleScreen=$(sudo -u '#1000' XDG_RUNTIME_DIR=/run/user/1000 DISPLAY=:0 xprintidle);
    # Idle screen in s
    idleScreen=$((tempidleScreen / 1000));

    # Detect when no audio is being played
    if [ "$idleSound" -eq "$noSoundValue" ]; then
        idleSoundTimer=$(($idleSoundTimer + $sleepValue));
    else
        idleSoundTimer=0;
    fi

    #Detect waking from suspend to reset suspendState and internet
    if [ "$idleScreen" -lt "$sleepValue" ]; then
        suspendState=0;
        systemctl enable NetworkManager.service
    fi

    #Suspend if idle
    if [[ "$idleSoundTimer" -gt "$startAt" && "$idleScreen" -gt "$startAt" && $suspendState -eq 0 ]]; then
        idleSoundTimer=0;
        suspendState=1;
        systemctl disable NetworkManager.service
        echo freeze > /sys/power/state
    fi;

    sleep $((sleepValue));

done
