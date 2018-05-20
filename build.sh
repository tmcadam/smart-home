# install esp tools
pip install esptool
pip install nodemcu-uploader

device=$1
while getopts ":f" o; do
    case "${o}" in
        f)
            echo "Updating firmware ...."
            # With GPIO, DHT, MQTT, TLS/SSL
            esptool.py --chip esp8266 --port /dev/ttyUSB0 write_flash -fm dio -ff 20m -fs detect 0x0000 fw_flash/nodemcu-master-11-modules-2018-05-11-17-42-12-float.bin
            device=$2
    esac
done

case $device in
  "switch")
    echo "Installing switch code"
    nodemcu-uploader upload init.lua credentials.lua relay-mqtt.lua:application.lua -r
    ;;
  "temp-humidity")
    echo "Installing temp-humidity code"
    nodemcu-uploader upload init.lua credentials.lua temp-humidity-mqtt.lua:application.lua -r
    ;;
esac

# nodemcu-uploader terminal
