#!/bin/sh

FW_REG="/lib/firmware/tas2563-1amp-reg.bin"
FW_DSP="/lib/firmware/tas2563-1amp-dsp.bin"

# Firmware must exist before the OOT TAS2563 driver probes the codec.
i=0
while [ $i -lt 30 ]; do
    if [ -f "$FW_REG" ] && [ -f "$FW_DSP" ]; then
        break
    fi
    sleep 1
    i=$((i + 1))
done

if [ ! -f "$FW_REG" ] || [ ! -f "$FW_DSP" ]; then
    echo "load-audio-drivers: missing TAS2563 firmware ($FW_REG, $FW_DSP)" >&2
    exit 1
fi

modprobe snd-soc-fsl-micfil
modprobe snd-soc-integrated-tasdevice

if [ -x /usr/bin/detect-audio-hardware.sh ]; then
    /usr/bin/detect-audio-hardware.sh
    if [ -f /etc/default/audio-hardware ]; then
        # shellcheck disable=SC1091
        . /etc/default/audio-hardware
    fi
fi
