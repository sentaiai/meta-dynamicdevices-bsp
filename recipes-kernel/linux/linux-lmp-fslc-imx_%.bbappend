FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
# imx8mm-jaguar-dt510 DTS + imx8mm-sw_pad_ctl.h live under lmp-device-tree (SoC pad words, shared header).
FILESEXTRAPATHS:prepend:imx8mm-jaguar-dt510 := "${THISDIR}/../../recipes-bsp/device-tree/lmp-device-tree:"

# Fix buildpaths QA warnings by ensuring debug prefix mapping is applied to kernel builds
# This prevents TMPDIR references from being embedded in debug information
DEBUG_PREFIX_MAP:append = " -fdebug-prefix-map=${TMPDIR}=/usr/src/debug/tmpdir"
DEBUG_PREFIX_MAP:append = " -fdebug-prefix-map=${WORKDIR}=/usr/src/debug/${PN}/${PV}"

SRC_URI:append:imx8mm-jaguar-sentai = " \
		file://i2c-dev-interface.cfg \
		file://imx8mm-jaguar-sentai/lp50xx-led-driver.cfg \
		file://usb-modem-support.cfg \
		file://gpio-keys.cfg \
		file://imx8mm-jaguar-sentai/stts22h-temperature-sensor.cfg \
		file://imx8mm-jaguar-sentai/lis2dh-accelerometer.cfg \
		file://imx8mm-jaguar-sentai/sht4x-humidity-sensor.cfg \
		file://imx8mm-jaguar-sentai/video-disable.cfg \
		file://imx8mm-jaguar-sentai/tas2562-audio-codec.cfg \
		file://imx8mm-jaguar-sentai/wifi-power-management.cfg \
		file://lis2dh12-sensor.cfg \
		file://usb-gadgets.cfg \
		${@bb.utils.contains('DISTRO', 'lmp-mfgtool', '', 'file://imx8mm-jaguar-sentai/usb-audio-gadget.cfg', d)} \
		file://0001-wireless-remove-nl80211-regdom-warning.patch \
		file://0004-dts-imx8mm-evkb-fix-duplicate-label.patch \
		file://0005-dts-imx8mm-evkb-fix-lp50xx-led-driver.patch \
		file://0003-wireless-wilc1000-disable-scan-progress-message.patch \
		file://imx8mm-jaguar-sentai/0006-leds-lp50xx-set-default-configuration.patch \
		file://0002-asoc-tas2781-add-tas2563-codec-support.patch \
		${@bb.utils.contains('MACHINE_FEATURES', 'tas2562', 'file://0008-asoc-tas2562-fix-format-definition.patch', bb.utils.contains('MACHINE_FEATURES', 'tas2563', 'file://0008-asoc-tas2562-fix-format-definition.patch', '', d), d)} \
		${@bb.utils.contains('MACHINE_FEATURES', 'tas2562', 'file://tas2562-driver.cfg', bb.utils.contains('MACHINE_FEATURES', 'tas2563', 'file://tas2562-driver.cfg', '', d), d)} \
		${@bb.utils.contains('ENABLE_BOOT_PROFILING', '1', 'file://boot-profiling.cfg', '', d)} \
		file://imx8mm-jaguar-sentai/rdc-driver.cfg \
		file://imx8mm-jaguar-sentai.dts \
"

# NOTE: This DTB file is created as a default for use with local development
#       when building lmp-base. It is NOT used by the lmp build or under CI
#       which uses the DTS in lmp-device-tree
do_configure:append:imx8mm-jaguar-sentai(){
 if [ -f ${WORKDIR}/imx8mm-jaguar-sentai.dts ]; then
     cp ${WORKDIR}/imx8mm-jaguar-sentai.dts ${S}/arch/arm64/boot/dts
     echo "dtb-y += imx8mm-jaguar-sentai.dtb" >> ${S}/arch/arm64/boot/dts/Makefile
 else
     bbwarn "imx8mm-jaguar-sentai.dts not found in ${WORKDIR}, skipping DTS copy"
 fi
}

# NOTE: Device tree is now provided by the BSP layer lmp-device-tree recipe
#       This ensures consistent DTS across all build types (lmp, lmp-base, CI)

SRC_URI:append:imx8mm-jaguar-dt510 = " \
		file://i2c-dev-interface.cfg \
		file://imx8mm-sw_pad_ctl.h \
		file://imx8mm-sw_pad_ctl-fields.h \
		file://imx8mm-jaguar-dt510/pmic-pca9450.cfg \
		${@bb.utils.contains('MACHINE_FEATURES', 'cp2108-usb-serial', 'file://imx8mm-jaguar-dt510/cp2108-usb-serial.cfg', '', d)} \
		${@bb.utils.contains('MACHINE_FEATURES', 'mcp251xfd-can', 'file://imx8mm-jaguar-dt510/mcp251xfd-can.cfg', '', d)} \
		file://usb-modem-support.cfg \
		file://gpio-keys.cfg \
		file://imx8mm-jaguar-dt510/video-disable.cfg \
		${@bb.utils.contains('MACHINE_FEATURES', 'tas2563', 'file://imx8mm-jaguar-dt510/tas2562-audio-codec.cfg', '', d)} \
		${@bb.utils.contains('MACHINE_FEATURES', 'tas6424', 'file://imx8mm-jaguar-dt510/tas6424-audio-codec.cfg', '', d)} \
		file://imx8mm-jaguar-dt510/wifi-power-management.cfg \
		file://usb-gadgets.cfg \
		${@bb.utils.contains('DISTRO', 'lmp-mfgtool', '', 'file://imx8mm-jaguar-dt510/usb-audio-gadget.cfg', d)} \
		file://0001-wireless-remove-nl80211-regdom-warning.patch \
		file://0004-dts-imx8mm-evkb-fix-duplicate-label.patch \
		file://0003-wireless-wilc1000-disable-scan-progress-message.patch \
		${@bb.utils.contains('MACHINE_FEATURES', 'tas2563', 'file://0002-asoc-tas2781-add-tas2563-codec-support.patch', '', d)} \
		${@bb.utils.contains('MACHINE_FEATURES', 'tas2562', 'file://0008-asoc-tas2562-fix-format-definition.patch', bb.utils.contains('MACHINE_FEATURES', 'tas2563', 'file://0008-asoc-tas2562-fix-format-definition.patch', '', d), d)} \
		${@bb.utils.contains('MACHINE_FEATURES', 'tas2562', 'file://tas2562-driver.cfg', bb.utils.contains('MACHINE_FEATURES', 'tas2563', 'file://tas2562-driver.cfg', '', d), d)} \
		${@bb.utils.contains('ENABLE_BOOT_PROFILING', '1', 'file://boot-profiling.cfg', '', d)} \
		file://imx8mm-jaguar-dt510/rdc-driver.cfg \
		${@bb.utils.contains('MACHINE_FEATURES', 'ksz9896', 'file://imx8mm-jaguar-dt510/ksz9896-ethernet-switch.cfg file://imx8mm-jaguar-dt510/ksz9896-mii-phy.cfg', '', d)} \
		${@bb.utils.contains('MACHINE_FEATURES', 'bq25792-charger', 'file://imx8mm-jaguar-dt510/bq25792-charger.cfg file://imx8mm-jaguar-dt510/0010-mfd-bq257xx-add-bq25703a-core-fslc.patch file://imx8mm-jaguar-dt510/0011-power-supply-bq257xx-charger.patch file://imx8mm-jaguar-dt510/0012-regulator-bq257xx-boost-fslc.patch file://imx8mm-jaguar-dt510/0013-dt-bindings-mfd-ti-bq25703a-Import-binding-from-main.patch file://imx8mm-jaguar-dt510/0014-dt-bindings-mfd-ti-bq25703a-Expand-to-include-BQ2579.patch file://imx8mm-jaguar-dt510/0015-regulator-bq257xx-Remove-reference-to-the-parent-MFD.patch file://imx8mm-jaguar-dt510/0016-regulator-bq257xx-Drop-the-regulator_dev-from-the-dr.patch file://imx8mm-jaguar-dt510/0017-regulator-bq257xx-Make-OTG-enable-GPIO-really-option.patch file://imx8mm-jaguar-dt510/0018-power-supply-bq257xx-Fix-VSYSMIN-clamping-logic.patch file://imx8mm-jaguar-dt510/0019-power-supply-bq257xx-Make-the-default-current-limit-.patch file://imx8mm-jaguar-dt510/0020-power-supply-bq257xx-Consistently-use-indirect-get-s.patch file://imx8mm-jaguar-dt510/0021-power-supply-bq257xx-Add-fields-for-charging-and-ove.patch file://imx8mm-jaguar-dt510/0022-mfd-bq257xx-Add-BQ25792-support.patch file://imx8mm-jaguar-dt510/0023-regulator-bq257xx-Add-support-for-BQ25792.patch file://imx8mm-jaguar-dt510/0024-power-supply-bq257xx-Add-support-for-BQ25792.patch file://imx8mm-jaguar-dt510/bq257xx-mfd-kconfig.cfg', '', d)} \
		file://imx8mm-jaguar-dt510.dts \
"

# NOTE: This DTB file is created as a default for use with local development
#       when building lmp-base. It is NOT used by the lmp build or under CI
#       which uses the DTS in lmp-device-tree
do_configure:append:imx8mm-jaguar-dt510(){
 if [ -f ${WORKDIR}/imx8mm-jaguar-dt510.dts ]; then
     cp ${WORKDIR}/imx8mm-jaguar-dt510.dts ${S}/arch/arm64/boot/dts
     if [ -f ${WORKDIR}/imx8mm-sw_pad_ctl.h ]; then
         cp ${WORKDIR}/imx8mm-sw_pad_ctl.h ${S}/arch/arm64/boot/dts
     fi
     if [ -f ${WORKDIR}/imx8mm-sw_pad_ctl-fields.h ]; then
         cp ${WORKDIR}/imx8mm-sw_pad_ctl-fields.h ${S}/arch/arm64/boot/dts
     fi
     echo "dtb-y += imx8mm-jaguar-dt510.dtb" >> ${S}/arch/arm64/boot/dts/Makefile
 else
     bbwarn "imx8mm-jaguar-dt510.dts not found in ${WORKDIR}, skipping DTS copy"
 fi
}

SRC_URI:append:imx8mm-jaguar-inst = " \
		file://i2c-dev-interface.cfg \
                file://usb-modem-support.cfg \
		file://gpio-keys.cfg \
		file://imx8mm-jaguar-inst.dts \
		file://0003-wireless-wilc1000-disable-scan-progress-message.patch \
		file://usb-gadgets.cfg \
                file://imx8mm-jaguar-inst/0001-wireless-iwlwifi-support-tx-power-cmd-v8.patch \
                file://imx8mm-jaguar-inst/0002-wireless-iwlwifi-mvm-fix-crash-on-7265.patch \
		file://imx8mm-jaguar-inst/micrel-phy-support.cfg \
"

# NOTE: This DTB file is created as a default for use with local development
#       when building lmp-base. It is NOT used by the lmp build or under CI
#       which uses the DTS in lmp-device-tree
do_configure:append:imx8mm-jaguar-inst(){
 if [ -f ${WORKDIR}/imx8mm-jaguar-inst.dts ]; then
     cp ${WORKDIR}/imx8mm-jaguar-inst.dts ${S}/arch/arm64/boot/dts
     echo "dtb-y += imx8mm-jaguar-inst.dtb" >> ${S}/arch/arm64/boot/dts/Makefile
 else
     bbwarn "imx8mm-jaguar-inst.dts not found in ${WORKDIR}, skipping DTS copy"
 fi
}

# NOTE: This DTB file is created as a default for use with local development
#       when building lmp-base. It is NOT used by the lmp build or under CI
#       which uses the DTS in lmp-device-tree
do_configure:append:imx8mm-jaguar-handheld(){
 if [ -f ${WORKDIR}/imx8mm-jaguar-handheld.dts ]; then
     cp ${WORKDIR}/imx8mm-jaguar-handheld.dts ${S}/arch/arm64/boot/dts
     echo "dtb-y += imx8mm-jaguar-handheld.dtb" >> ${S}/arch/arm64/boot/dts/Makefile
 else
     bbwarn "imx8mm-jaguar-handheld.dts not found in ${WORKDIR}, skipping DTS copy"
 fi
}

# NOTE: This DTB file is created as a default for use with local development
#       when building lmp-base. It is NOT used by the lmp build or under CI
#       which uses the DTS in lmp-device-tree
do_configure:append:imx8mm-jaguar-phasora(){
 if [ -f ${WORKDIR}/imx8mm-jaguar-phasora.dts ]; then
     cp ${WORKDIR}/imx8mm-jaguar-phasora.dts ${S}/arch/arm64/boot/dts
     echo "dtb-y += imx8mm-jaguar-phasora.dtb" >> ${S}/arch/arm64/boot/dts/Makefile
 else
     bbwarn "imx8mm-jaguar-phasora.dts not found in ${WORKDIR}, skipping DTS copy"
 fi
}

# TODO: Make binder module based on DISTRO
SRC_URI:append:imx8mm-jaguar-handheld = " \
		file://i2c-dev-interface.cfg \
		file://imx8mm-jaguar-handheld.dts \
                file://imx8mm-jaguar-handheld/android-binder.cfg \
		file://imx8mm-jaguar-handheld/iptables-extensions.cfg \
		file://imx8mm-jaguar-handheld/erofs-filesystem.cfg \
"

SRC_URI:append:imx8mm-jaguar-phasora = " \
		file://i2c-dev-interface.cfg \
		file://ksz9563-ethernet-switch.cfg \
		file://pca953x-gpio-expander.cfg \
		file://dwc3-usb.cfg \
		file://upd72020x-usb3-firmware.cfg \
		file://imx8mm-jaguar-phasora.dts \
                file://imx8mm-jaguar-phasora/st7701-display-driver.cfg \
                file://imx8mm-jaguar-phasora/edt-ft5x06-touchscreen.cfg \
		file://0006-usb-dwc3-synopsys-load-firmware-support.patch \
"

# PHASE 1.2-4.6: Adding back Very Low + Low + Medium + All High Risk configs (14 changes)
SRC_URI:append:imx93-jaguar-eink = " \
		file://imx93-jaguar-eink.dts \
		file://i2c-dev-interface.cfg \
		file://gpio-keys.cfg \
		file://imx93-jaguar-eink/imx93-core-system.cfg \
		file://imx93-jaguar-eink/spi-support.cfg \
		file://imx93-jaguar-eink/ocotp-nvmem-support.cfg \
		file://imx93-jaguar-eink/imx93-hardware-disable.cfg \
		file://imx93-jaguar-eink/module-signing.cfg \
		file://imx93-jaguar-eink/config-conflicts-fix.cfg \
		file://imx93-jaguar-eink/imx93-wireless.cfg \
		file://imx93-jaguar-eink/lte-modem-support.cfg \
		file://imx93-jaguar-eink/essential-eink-verification.cfg \
		file://imx93-jaguar-eink/suspend-debug.cfg \
		file://imx93-jaguar-eink/imx93-power-management.cfg \
		file://imx93-jaguar-eink/dsm-power-management.cfg \
		file://imx93-jaguar-eink/delayed-components.cfg \
		file://imx93-jaguar-eink/safe-boot-params.cfg \
"

# TEMPORARILY DISABLED FOR BOOT DEBUGGING - PCF2131 patch causing boot failures
# file://imx93-jaguar-eink/0008-rtc-pcf2127-add-complete-INTA-INTB-support-with-devicetree.patch

# NOTE: Device tree is handled by lmp-device-tree recipe, not kernel recipe

# NOTE: This DTB file is created as a default for use with local development
#       when building lmp-base. It is NOT used by the lmp build or under CI
#       which uses the DTS in lmp-device-tree
do_configure:append:imx93-jaguar-eink(){
 if [ -f ${WORKDIR}/imx93-jaguar-eink.dts ]; then
     cp ${WORKDIR}/imx93-jaguar-eink.dts ${S}/arch/arm64/boot/dts
     echo "dtb-y += imx93-jaguar-eink.dtb" >> ${S}/arch/arm64/boot/dts/Makefile
 else
     bbwarn "imx93-jaguar-eink.dts not found in ${WORKDIR}, skipping DTS copy"
 fi
}

#do_configure:append:imx8mm-jaguar-phasora() {
#   for i in ../*.cfg; do
#      [ -f "$i" ] || break
#      bbdebug 2 "applying $i file contents to .config"
#      cat ../*.cfg >> ${B}/.config
#   done
#}
