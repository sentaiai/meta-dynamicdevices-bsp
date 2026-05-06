#!/bin/sh
# DT510 — KSZ9896 DSA
#
# - lan1 / WAN: DHCP client toward upstream (internet). Connection DT510-wan (ipv4.method auto).
# - lan2–lan4 / LAN: bridged as br-lan; NetworkManager ipv4.method shared runs a DHCP server for
#   hosts plugged into those ports and NATs outbound traffic via the WAN default route.
set -e
WAN_IF="${DT510_WAN_IFACE:-lan1}"
BR_IF="${DT510_LAN_BRIDGE_NAME:-br-lan}"
WAN_CON="DT510-wan"
BR_CON="DT510-lan-bridge"

sleep 2

for n in 1 2 3 4; do
	if [ ! -d "/sys/class/net/lan${n}" ]; then
		exit 0
	fi
done

if ! nmcli connection show "${WAN_CON}" >/dev/null 2>&1; then
	nmcli connection add type ethernet con-name "${WAN_CON}" ifname "${WAN_IF}" \
		ipv4.method auto ipv6.method auto \
		connection.autoconnect yes \
		connection.autoconnect-priority 200
fi

if ! nmcli connection show "${BR_CON}" >/dev/null 2>&1; then
	nmcli connection add type bridge ifname "${BR_IF}" con-name "${BR_CON}" \
		ipv4.method shared ipv6.method ignore \
		bridge.stp no \
		connection.autoconnect yes \
		connection.autoconnect-priority 50
fi

for p in 2 3 4; do
	SLAVE_CON="DT510-lan-br-port${p}"
	if ! nmcli connection show "${SLAVE_CON}" >/dev/null 2>&1; then
		nmcli connection add type ethernet slave-type bridge \
			ifname "lan${p}" con-name "${SLAVE_CON}" master "${BR_CON}" \
			connection.autoconnect yes
	fi
done

# Drop legacy single-port DHCP profile from earlier BSP revisions.
nmcli connection delete DT510-lan1-dhcp 2>/dev/null || true

nmcli connection up "${WAN_CON}" 2>/dev/null || true
nmcli connection up "${BR_CON}" 2>/dev/null || true
