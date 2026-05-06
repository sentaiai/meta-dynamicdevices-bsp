SUMMARY = "USB Gadget Scripts for imx8mm-jaguar-sentai"
DESCRIPTION = "USB gadget configuration scripts for CDC serial and audio gadget support. Provides setup scripts for USB composite gadget with CDC ACM serial port and UAC1/UAC2 audio."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = " \
    file://setup-usb-serial-gadget.sh \
    file://setup-usb-mixed-audio-gadget \
    file://setup-fixed-uac2.sh \
    file://start-fixed-usb-audio.sh \
    file://usb-composite-gadget-fixed.service \
    file://usb-audio-test.sh \
    file://uac2-module-test.sh \
"

# DT510-specific: dual USB audio gadget (2x UAC2 only, no ACM)
SRC_URI:append:imx8mm-jaguar-dt510 = " \
    file://setup-usb-dual-audio-gadget \
    file://usb-dual-audio-gadget-dt510.service \
    file://60-usb-gadget-libcomposite.conf \
"

S = "${WORKDIR}"

RDEPENDS:${PN} = "bash"

inherit systemd

SYSTEMD_SERVICE:${PN} = "usb-composite-gadget-fixed.service"
# DT510: dual UAC2 gadget at boot (no CDC ACM — endpoint limit)
SYSTEMD_SERVICE:${PN}:imx8mm-jaguar-dt510 = "usb-dual-audio-gadget-dt510.service"
SYSTEMD_AUTO_ENABLE:${PN} = "disable"
SYSTEMD_AUTO_ENABLE:${PN}:imx8mm-jaguar-sentai = "enable"
# DT510: autostart only if MACHINE_FEATURES contains dt510-usb-dual-audio-autostart
# (see imx8mm-jaguar-dt510.conf). Remove that feature for codec-first images; use
# `systemctl start usb-dual-audio-gadget-dt510` for simulated USB testing without autostart.
SYSTEMD_AUTO_ENABLE:${PN}:imx8mm-jaguar-dt510 = "${@bb.utils.contains('MACHINE_FEATURES', 'dt510-usb-dual-audio-autostart', 'enable', 'disable', d)}"

do_install() {
    # Install USB gadget setup scripts
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/setup-usb-serial-gadget.sh ${D}${bindir}/setup-usb-serial-gadget
    install -m 0755 ${WORKDIR}/setup-usb-mixed-audio-gadget ${D}${bindir}/setup-usb-mixed-audio-gadget
    install -m 0755 ${WORKDIR}/setup-fixed-uac2.sh ${D}${bindir}/setup-fixed-uac2.sh
    install -m 0755 ${WORKDIR}/start-fixed-usb-audio.sh ${D}${bindir}/start-fixed-usb-audio.sh
    install -m 0755 ${WORKDIR}/usb-audio-test.sh ${D}${bindir}/usb-audio-test.sh
    install -m 0755 ${WORKDIR}/uac2-module-test.sh ${D}${bindir}/uac2-module-test.sh
    
    # Create symlinks for convenience (matching documentation)
    ln -sf setup-usb-mixed-audio-gadget ${D}${bindir}/setup-usb-composite-gadget
    ln -sf setup-usb-mixed-audio-gadget ${D}${bindir}/setup-usb-cdc-gadget
    ln -sf setup-usb-mixed-audio-gadget ${D}${bindir}/setup-usb-audio-gadget
    
    # Install systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/usb-composite-gadget-fixed.service ${D}${systemd_system_unitdir}/
}

do_install:append:imx8mm-jaguar-sentai() {
	# LmP preset-all does not reliably enable serial-getty@ttyGS0; ship the enable symlink.
	install -d ${D}${sysconfdir}/systemd/system/getty.target.wants
	ln -sf ${systemd_system_unitdir}/serial-getty@.service \
		${D}${sysconfdir}/systemd/system/getty.target.wants/serial-getty@ttyGS0.service
}


do_install:append:imx8mm-jaguar-dt510() {
    # DT510-specific: dual USB audio gadget (2x UAC2)
    install -m 0755 ${WORKDIR}/setup-usb-dual-audio-gadget ${D}${bindir}/setup-usb-dual-audio-gadget
    install -m 0644 ${WORKDIR}/usb-dual-audio-gadget-dt510.service ${D}${systemd_system_unitdir}/
    install -d ${D}${sysconfdir}/modules-load.d
    install -m 0644 ${WORKDIR}/60-usb-gadget-libcomposite.conf ${D}${sysconfdir}/modules-load.d/
}

FILES:${PN} += " \
    ${bindir}/setup-usb-serial-gadget \
    ${bindir}/setup-usb-mixed-audio-gadget \
    ${bindir}/setup-fixed-uac2.sh \
    ${bindir}/start-fixed-usb-audio.sh \
    ${bindir}/usb-audio-test.sh \
    ${bindir}/uac2-module-test.sh \
    ${bindir}/setup-usb-composite-gadget \
    ${bindir}/setup-usb-cdc-gadget \
    ${bindir}/setup-usb-audio-gadget \
    ${systemd_system_unitdir}/usb-composite-gadget-fixed.service \
"

FILES:${PN}:append:imx8mm-jaguar-sentai = " \
    ${sysconfdir}/systemd/system/getty.target.wants/serial-getty@ttyGS0.service \
"

FILES:${PN}:append:imx8mm-jaguar-dt510 = " \
    ${bindir}/setup-usb-dual-audio-gadget \
    ${systemd_system_unitdir}/usb-dual-audio-gadget-dt510.service \
    ${sysconfdir}/modules-load.d/60-usb-gadget-libcomposite.conf \
"
