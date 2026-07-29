SUMMARY = "TI TAS2781 Smart Amplifier Driver with TAS2563 Hardware Support"
DESCRIPTION = "Advanced Linux driver for TI TAS2781/TAS2563 smart amplifiers with DSP support, \
firmware loading, and echo reference functionality for audio applications."
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://tasdevice-codec.c;beginline=1;endline=14;md5=bf3ad78054a3e702be98b345c246c294"

inherit module


SRC_URI = "git://git.ti.com/tas2781-linux-drivers/tas2781-linux-driver.git;branch=master;protocol=https \
           file://tas2563-1amp-reg.bin \
           file://TAS2XXX3870.bin \
           file://0001-tas2781-yocto-build-compatibility.patch \
           file://0002-tas2781-fix-irq-gpio-handling.patch \
           file://0003-tas2781-add-separate-mute-control.patch \
           file://0004-tas2781-fix-power-state-reset.patch \
          "
SRCREV = "124282c12d471a53a2302881788c008fc2d3c364"

S = "${WORKDIR}/git/src"

do_configure() {
}

do_install:append() {
  install -d ${D}${nonarch_base_libdir}/firmware
  # Install official TAS2563 regbin firmware (modified for single device) from Linux firmware repository
  install -m 644 ${WORKDIR}/tas2563-1amp-reg.bin ${D}${nonarch_base_libdir}/firmware/tas2563-1amp-reg.bin
  # Install official TAS2563 DSP firmware from Linux firmware repository  
  install -m 644 ${WORKDIR}/TAS2XXX3870.bin ${D}${nonarch_base_libdir}/firmware/tas2563-1amp-dsp.bin
}

FILES:${PN} += "/lib/modules*"
FILES:${PN} += "${nonarch_base_libdir}/firmware/tas2563-1amp-reg.bin" 
FILES:${PN} += "${nonarch_base_libdir}/firmware/tas2563-1amp-dsp.bin" 

COMPATIBLE_MACHINE = "(imx8mm-jaguar-sentai)"
