#!/bin/sh

FW_RCA="/lib/firmware/tas2563RCA1.bin"
FW_COEF="/lib/firmware/tas2563-coef.bin"

# Firmware must exist before the TAS2781 driver probes the codec.
i=0
while [ $i -lt 30 ]; do
    if [ -f "$FW_RCA" ] && [ -f "$FW_COEF" ]; then
        break
    fi
    sleep 1
    i=$((i + 1))
done

if [ ! -f "$FW_RCA" ] || [ ! -f "$FW_COEF" ]; then
    echo "load-audio-drivers: missing TAS2563 firmware ($FW_RCA, $FW_COEF)" >&2
    exit 1
fi

modprobe snd-soc-fsl-micfil
modprobe snd-soc-tas2781-comlib-i2c
modprobe snd-soc-tas2781-fmwlib
modprobe snd-soc-tas2781-i2c

if [ -x /usr/bin/detect-audio-hardware.sh ]; then
    /usr/bin/detect-audio-hardware.sh
    if [ -f /etc/default/audio-hardware ]; then
        # shellcheck disable=SC1091
        . /etc/default/audio-hardware
    fi
fi
