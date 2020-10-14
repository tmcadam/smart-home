# smart-home

## Dependencies

### esptool.py

`sudo -H pip3 install -q esptool`

### nodemcu-uploader

`sudo pip3 install nodemcu-uploader`


## Bin and Img

Each device type has a custom version of the nodemcu runtime. The modules to include are defined in devices folder `user_config.h` and `user_modules.h`. This changes infrequently, only when a new module is required from the nodemcu source. This is generated and flashed using the build_nodemcu.sh script.

Each device type also has a img file with it's Lua source code. This changes frequently. This is generated using the build_src.sh script.

All files are stored in the relevant devices folder.

## Mosquitto Bridge Configuration

As the system uses ESP8266, they do not work well on TLS. The solution to this is to have a local broker running with a secure bridge to the platform. This can run on a RPi or router that supports MQTT bridges.

### Teltonika RUT955

#### Access
Enable remote SSH access then: `ssh root@192.168.2.100`
Or join the Teltonika local network and: `ssh root@192.168.1.1`
Use the Teltonika admin password for SSH

#### Debugging
This is will run the broker in current session and output to console

`/etc/init.d/mosquitto stop`
`mosquitto -c /etc/mosquitto/tb-bridge.conf`

It's also possible to subscribe to the broker to view traffic

#### Configuration

  - Copy into `/etc/mosquitto`
     - tb-bridge.conf
     - check.sh
     - passwords_hashed.txt
     - swb.ca
  - In the Teltonika UI add the following line to System->User Scripts
    - `mosquitto -d -c /etc/mosquitto/tb-bridge.conf`
  - Add the following Cron task to check the broker
    - `*/1 * * * * /bin/ash /etc/mosquitto/check.sh`



