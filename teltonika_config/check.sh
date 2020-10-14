#!/bin/ash

pidof  mosquitto >/dev/null
if [[ $? -ne 0 ]] ; then
        echo "Restarting Mosquitto:     $(date)" >> /var/log/mosquitto.txt
        /usr/sbin/mosquitto -d -c /etc/mosquitto/tb-bridge.conf
fi
