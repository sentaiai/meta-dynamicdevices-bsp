#!/bin/sh
# Simple USB CDC ACM Serial Gadget - for testing USB gadget port connectivity
# CDC-only, no audio. Host sees new ttyACM device (Linux Foundation 1d6b:0107)
#
# Usage: setup-usb-serial-gadget {setup|stop|status|restart}
# Test: On host, run 'ls /dev/ttyACM*' - new device appears when connected to OTG port

CONFIGFS=/sys/kernel/config/usb_gadget
GADGET_NAME="g_serial_test"
GADGET=$CONFIGFS/$GADGET_NAME
CONFIG=$GADGET/configs/c.1
FUNCTIONS=$GADGET/functions

modprobe libcomposite 2>/dev/null || true

VID="0x1d6b"
PID="0x0107"  # Distinct PID for serial-only test
SERIALNUMBER="$(cat /sys/devices/soc0/serial_number 2>/dev/null || cat /etc/machine-id 2>/dev/null || echo 'DD-SERIAL-TEST')"
MANUFACTURER="Dynamic Devices Ltd"
PRODUCT="USB Serial Gadget Test"

cleanup() {
    for gadget_dir in "$CONFIGFS"/g_*; do
        [ -d "$gadget_dir" ] || continue
        echo "" > "$gadget_dir/UDC" 2>/dev/null || true
        rm -f "$gadget_dir/configs/c.1"/* 2>/dev/null || true
        rm -rf "$gadget_dir" 2>/dev/null || true
    done
    sleep 1
}

setup_gadget() {
    echo "=== Setting up USB Serial Gadget (CDC ACM only) ==="
    mkdir -p "$GADGET" || return 1
    echo $VID > "$GADGET/idVendor"
    echo $PID > "$GADGET/idProduct"
    mkdir -p "$GADGET/strings/0x409"
    echo "$SERIALNUMBER" > "$GADGET/strings/0x409/serialnumber"
    echo "$MANUFACTURER" > "$GADGET/strings/0x409/manufacturer"
    echo "$PRODUCT" > "$GADGET/strings/0x409/product"
    mkdir -p "$CONFIG/strings/0x409"
    echo "CDC Serial" > "$CONFIG/strings/0x409/configuration"
    echo 0x80 > "$CONFIG/bmAttributes"
    echo 250 > "$CONFIG/MaxPower"
    mkdir -p "$FUNCTIONS/acm.gs0" || return 1
    ln -s "$FUNCTIONS/acm.gs0" "$CONFIG/" || return 1
    udc_device="$(ls /sys/class/udc | head -1)"
    [ -n "$udc_device" ] || { echo "No UDC found"; return 1; }
    echo "$udc_device" > "$GADGET/UDC" || return 1
    echo "✅ Serial gadget enabled on $udc_device"
    echo "   Host should see: lsusb 1d6b:0107, /dev/ttyACM*"
}

case "$1" in
    setup|start) cleanup; setup_gadget ;;
    stop|disable) cleanup; echo "Stopped" ;;
    status)
        if [ -d "$GADGET" ] && [ -n "$(cat "$GADGET/UDC" 2>/dev/null)" ]; then
            echo "Serial gadget: CONFIGURED (UDC: $(cat $GADGET/UDC))"
        else
            echo "Serial gadget: NOT CONFIGURED"
        fi
        ;;
    restart) cleanup; setup_gadget ;;
    *) echo "Usage: $0 {setup|stop|status|restart}"; exit 1 ;;
esac
