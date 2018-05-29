# install esp tools
pip install -q esptool
pip install -q nodemcu-uploader
PORT="/dev/ttyUSB0"

device=$1
while getopts ":f" o; do
    case "${o}" in
        f)
            device=$2
            echo "Updating firmware..."
            case $device in
              "wemos-switch")
                FF="20m"; FM="dio"; FS="1MB"
                FW="fw_flash/nodemcu-master-13-modules-2018-05-20-22-04-10-float.bin"
                ;;
              "wemos-switch-button")
                FF="20m"; FM="dio"; FS="1MB"
                FW="fw_flash/nodemcu-master-13-modules-2018-05-20-22-04-10-float.bin"
                ;;
              "wemos-temp-humidity")
                FF="20m"; FM="dio"; FS="1MB"
                FW="fw_flash/nodemcu-master-13-modules-2018-05-20-22-04-10-float.bin"
                ;;
               "sonoff-s20")
                read -p "Restart Sonoff S20 in boot mode and press Enter..."
                FF="40m"; FM="dout"; FS="1MB"
                FW="fw_flash/nodemcu-master-13-modules-2018-05-20-22-04-10-float.bin"
                ;;
            esac
            eval "esptool.py --chip esp8266 --port ${PORT} write_flash -ff ${FF} -fs ${FS} -fm ${FM} 0x0000 ${FW}"
    esac
done

case $device in
    "wemos-switch")
        echo "Installing switch code"
        nodemcu-uploader -p $PORT upload \
            wemos/init.lua:init.lua \
            wemos/credentials.lua:credentials.lua \
            wemos/relay-mqtt.lua:application.lua \
            -r
    ;;
    "wemos-switch-button")
        echo "Installing switch code"
        sudo python3 reset-usb.py search "HL-340"; sleep 3s
        nodemcu-uploader -p $PORT node restart; sleep 3s
        nodemcu-uploader -p $PORT upload \
            wemos/init.lua:init.lua \
            wemos/credentials.lua:credentials.lua \
            wemos/relay-button-mqtt.lua:application.lua \
            -r
    ;;
    "wemos-temp-humidity")
        echo "Installing temp-humidity code"
        nodemcu-uploader -p $PORT upload \
            wemos/init.lua:init.lua \
            wemos/credentials.lua:credentials.lua \
            wemos/temp-humidity-mqtt.lua:application.lua \
            -r
    ;;
    "sonoff-s20")
        echo "Installing s20 code"
        sudo python3 reset-usb.py search "FTDI"
        nodemcu-uploader -p $PORT upload \
            s20/s20_init.lua:init.lua \
            s20/s20_001_credentials.lua:credentials.lua \
            s20/s20_application.lua:application.lua \
            common/status_led.lua:status_led.lua \
            -r
    ;;
esac
