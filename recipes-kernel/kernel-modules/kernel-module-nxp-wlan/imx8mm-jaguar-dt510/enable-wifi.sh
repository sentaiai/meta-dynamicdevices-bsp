#!/bin/sh
# WIFI_PD# on GPIO3_IO7 — deassert power-down (logical high on active-low PD#).
# Hog wlan-power-down-hog normally owns this line; gpioset may no-op with EBUSY (harmless).
# Prefer soc gpiochip node id over gpiochipN index (probe order can vary across kernels).
echo "Enabling WiFi"
if command -v gpioset >/dev/null 2>&1; then
	gpioset 30220000.gpio 7=1 2>/dev/null || gpioset gpiochip2 7=1 2>/dev/null || true
fi
exit 0

