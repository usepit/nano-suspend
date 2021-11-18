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
#[Service]
#Type=simple
#ExecStart=/path/to/nanosuspend.sh
#Restart=on-failure
#[Install]
#WantedBy=multi-user.target

#Ctrl-O, save, and run in the terminal:

#chmod +x /path/to/nanosuspend.sh
#systemctl daemon-reload
#systemctl enable nanosuspend.service
#systemctl start nanosuspend.service

# Time between each check
sleepValue=9;

# Idle seconds before suspending
startAt=120;

# Open all the programs you normally have open, make sure no sound is being played, run this command:
#   pacmd list-sinks | grep -c 'state: RUNNING'
# and enter the value in the noSoundValue variable below.

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
        networkActive=$(systemctl status network-manager | grep -c dead);
        if [ networkActive -eq 0 ]; then
            systemctl enable network-manager;
        fi
    fi

    #Suspend if idle
    if [[ "$idleSoundTimer" -gt "$startAt" && "$idleScreen" -gt "$startAt" && $suspendState -eq 0 ]]; then
        idleSoundTimer=0;
        suspendState=1;
        systemctl disable network-manager
        echo freeze > /sys/power/state
    fi;

    sleep $((sleepValue));

done
