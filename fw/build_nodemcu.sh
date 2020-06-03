#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
port="/dev/ttyUSB0"

usage() { echo "Usage: $0 -t <build|flash|all> [-p <string>] device_type" 1>&2; exit 1; }

while getopts "t:p:" o; do
    case "${o}" in
        t)
            target=${OPTARG}
            ((target == build || target == flash || target == all)) || usage
            ;;
        p)
            port=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

device_type=${1}
if [ -z "${target}" ] || [ -z "${port}" ] || [ -z "${device_type}" ]; then
    usage
fi

DEV_DIR="${DIR}/devices/${device_type}"
FW_DIR="${DIR}/nodemcu"
mkdir -p "${FW_DIR}"

if [ "${target}" == "build" ] || [ "${target}" == "all" ]; then

    if [ ! -d "${FW_DIR}/nodemcu-firmware" ]; then
      ## master 3d917850180f67adc7f2c6b5d00f27c152e7194c
      git clone --recurse-submodules -b master https://github.com/nodemcu/nodemcu-firmware.git ${FW_DIR}/nodemcu-firmware
      cd "${FW_DIR}/nodemcu-firmware"
      git checkout 3d917850180f67adc7f2c6b5d00f27c152e7194c
      mkdir -p "${FW_DIR}/original-configs"
      cp "${FW_DIR}/nodemcu-firmware/app/include/user_config.h" "${FW_DIR}/original-configs"
      cp "${FW_DIR}/nodemcu-firmware/app/include/user_modules.h" "${FW_DIR}/original-configs"
    fi

    # copy configs into nodemcu-firmware
    cp "${DEV_DIR}/user_config.h" "${FW_DIR}/nodemcu-firmware/app/include/"
    cp "${DEV_DIR}/user_modules.h" "${FW_DIR}/nodemcu-firmware/app/include/"

    # run make
    cd "${FW_DIR}/nodemcu-firmware"
    make

    # copy bins and luac.cross to version folder
    echo "Moving build artifacts"
    mv "${FW_DIR}/nodemcu-firmware/bin/0x00000.bin" "${DEV_DIR}/"
    mv "${FW_DIR}/nodemcu-firmware/bin/0x10000.bin" "${DEV_DIR}/"

    if [ -f ${FW_DIR}/nodemcu-firmware/luac.cross ]; then
        mv ${FW_DIR}/nodemcu-firmware/luac.cross ${DEV_DIR}/luac.cross
    fi
    if [ -f ${FW_DIR}/nodemcu-firmware/luac.cross.int ]; then
        mv ${FW_DIR}/nodemcu-firmware/luac.cross.int ${DEV_DIR}/luac.cross
    fi

    # cleanup a little
    echo "Cleaning up"
    rm "${FW_DIR}/nodemcu-firmware/app/include/user_config.h"
    rm "${FW_DIR}/nodemcu-firmware/app/include/user_modules.h"

    echo -e "\nOutput Folder"
    echo "----------------------------------------------"
    ls -l ${DEV_DIR}
fi

if [ "${target}" == "flash" ] || [ "${target}" == "all" ]; then
    echo -e "\nFlashing firmware to device"

    . "${DEV_DIR}/flash_options.cfg"
    read -p "Restart device in boot mode and press Enter..."
    esptool.py --chip $chip --port ${port} write_flash -ff $ff -fs $fs -fm $fm 0x0000 "${DEV_DIR}/0x00000.bin"
    read -p "Restart device in boot mode and press Enter..."
    esptool.py --chip $chip --port ${port} write_flash -ff $ff -fs $fs -fm $fm 0x10000 "${DEV_DIR}/0x10000.bin"
fi
