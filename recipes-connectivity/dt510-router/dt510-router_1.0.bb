# SPDX-License-Identifier: MIT
SUMMARY = "dt510-router — NM WAN DHCP + LAN DHCP/NAT (KSZ9896 DSA)"
DESCRIPTION = "Unmanages DSA master end0. DT510-wan: DHCP client on lan1 (WAN). \
DT510-lan-bridge: br-lan with lan2–lan4 as bridge ports; ipv4.method shared provides \
a DHCP server for devices on those ports plus NAT to WAN. Override DT510_WAN_IFACE \
or DT510_LAN_BRIDGE_NAME via systemd Environment= if needed."

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit systemd

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "file://dt510-dsa-master-unmanaged.conf \
           file://setup-dt510-network-layout.sh \
           file://setup-dt510-network-layout.service \
"

SYSTEMD_SERVICE:${PN} = "setup-dt510-network-layout.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

RDEPENDS:${PN} += "networkmanager bash"

do_install() {
	install -d ${D}${sysconfdir}/NetworkManager/conf.d
	install -m 0644 ${WORKDIR}/dt510-dsa-master-unmanaged.conf \
		${D}${sysconfdir}/NetworkManager/conf.d/

	install -d ${D}${bindir}
	install -m 0755 ${WORKDIR}/setup-dt510-network-layout.sh ${D}${bindir}/

	install -d ${D}${systemd_unitdir}/system
	install -m 0644 ${WORKDIR}/setup-dt510-network-layout.service \
		${D}${systemd_unitdir}/system/
}

pkg_postinst:${PN} () {
	if [ -n "$D" ]; then
		return 0
	fi
	systemctl disable setup-dt510-lan1-connection.service 2>/dev/null || true
}

FILES:${PN} += "${sysconfdir}/NetworkManager/conf.d ${bindir} ${systemd_unitdir}/system"
