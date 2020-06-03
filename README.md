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
