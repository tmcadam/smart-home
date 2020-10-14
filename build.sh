# install esp tools
#sudo -H pip3 install -q esptool
# sudo -H pip3 install -q nodemcu-uploader

port="/dev/ttyUSB0"
version="latest"
PROJ_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

usage() {
  echo "Usage: $0 -t <local-lfs|local-lua|remote> -c <string> [-m] [-v <string>] [-p <string>] device_name" 1>&2;
  echo -e "Device name ALL can be used with target remote only"
  exit 1;
}

while getopts "mvt:p:c:" o; do
    case "${o}" in
        v)
            version=${OPTARG}
            ;;
        m)
            monitor=M
            ;;
        t)
            target=${OPTARG}
            ((target == "local-lfs" || target == "local-lua" || target == remote)) || usage
            ;;
        p)
            port=${OPTARG}
            ;;
        c)
            config=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

device=${1}

if [ -z "${target}" ] || [ -z "${port}" ] || [ -z "${device}" ]; then
    usage
fi

if [ ${target} != "remote" ] && [ $device == "ALL" ]; then
    usage
fi

# WEMOS: = FF="20m"; FM="dio"; FS="1MB"
# SONOFF S20: FF="40m"; FM="dout"; FS="1MB"
# NODEMCU: FF="40m"; FM="qio"; FS="4MB"
declare -a src_list
declare -a src_list_b

build_device() {
  echo "Building ${1}"
  DEV_DIR="${PROJ_DIR}/devices/${1}"

  let i=0
  while IFS= read -r line || [[ -n "$line" ]];  do
      if [[ "${line}" == *":"* ]]; then
          orig="$(cut -d':' -f1 <<<"$line")"
          mapped="$(cut -d':' -f2 <<<"$line")"
          cp $PROJ_DIR/src/$orig $PROJ_DIR/tmp/$mapped
          src_list[i]="$PROJ_DIR/tmp/${mapped}"
          src_list_b[i]="$PROJ_DIR/src/${orig}:${mapped}"
      else
          src_list[i]="$PROJ_DIR/src/${line}"
          src_list_b[i]="$PROJ_DIR/src/${line}:${line}"
      fi
      ((++i))
  done < "${DEV_DIR}/src_list.cfg"

  ${DEV_DIR}/luac.cross -f -o ${DEV_DIR}/${1}.img "${src_list[@]/#/}"

  echo "Build complete"
}

upload_build() {
  DEV_DIR="${PROJ_DIR}/devices/${1}"
  echo "Sending ${1}.img to OTA server"
  sshpass -p $WEBFACTION_PASS scp ${DEV_DIR}/${1}.img ${WEBFACTION_USER}@${WEBFACTION_HOST}:/home/ukfit/webapps/fw_swb/lfs/${1}_${version}.img
  echo "OTA server updated"
}

if [[ ${target} == "remote" ]]; then
    if [ ${device} == "ALL" ]; then
      for i in $(ls ${PROJ_DIR}/devices/);
      do
        dev=${i%%/}
        build_device $dev
        echo $dev
        upload_build $dev
      done
    else
        build_device ${device}
        upload_build ${device}
    fi
elif [[ ${target} == "local-lfs" ]]; then
    DEV_DIR="${PROJ_DIR}/devices/${1}"
    . "${DEV_DIR}/flash_options.cfg"
    ### load locally

    build_device ${device}
    echo "Building ${device}"

    sudo python3 reset-usb.py search ${usb_id}; sleep 1s

    nodemcu-uploader -p $port file remove init.lua
    nodemcu-uploader -p $port node restart
    sleep 2s

    nodemcu-uploader -p $port upload    ${DEV_DIR}/${device}.img:lfs.img \
                                        ${PROJ_DIR}/src/init_lfs.lua:init.lua \
                                        ${PROJ_DIR}/src/reflash.lua:reflash.lua
    if [[ ${config} ]]; then
        nodemcu-uploader -p $port upload ${PROJ_DIR}/config/${config}:config.json
    fi

    sleep 1s

    #nodemcu-uploader -p $PORT node restart
    nodemcu-uploader -p $port file do reflash.lua
    nodemcu-uploader -p $port node restart
elif [[ ${target} == "local-lua" ]]; then
    DEV_DIR="${PROJ_DIR}/devices/${1}"
    . "${DEV_DIR}/flash_options.cfg"

    build_device ${device}

    sudo python3 reset-usb.py search ${usb_id}; sleep 1s
    nodemcu-uploader -p $port file remove init.lua
    nodemcu-uploader -p $port node restart
    sleep 2s

    if [[ ${config} ]]; then
        nodemcu-uploader -p $port upload ${PROJ_DIR}/config/${config}:config.json
    fi
    nodemcu-uploader -p $port upload    "${src_list_b[@]/#/}" \
                                        ${PROJ_DIR}/src/init_non_lfs.lua:init.lua
    sleep 1s
    nodemcu-uploader -p $port node restart
fi

if [ -n "${monitor}" ]; then
    miniterm.py ${port} 115200
fi
