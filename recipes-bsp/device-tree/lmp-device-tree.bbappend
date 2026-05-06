FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:imx8mm-jaguar-sentai = " \
        file://imx8mm-jaguar-sentai.dts \
        ${@bb.utils.contains('MACHINE_FEATURES', 'xm125-radar', 'file://imx8mm-jaguar-sentai-xm125-radar.dtso', '', d)} \
"

SRC_URI:append:imx8mm-jaguar-dt510 = " \
        file://imx8mm-jaguar-dt510.dts \
        file://imx8mm-sw_pad_ctl.h \
        file://imx8mm-sw_pad_ctl-fields.h \
"

COMPATIBLE_MACHINE:imx8mm-jaguar-sentai = ".*"
COMPATIBLE_MACHINE:imx8mm-jaguar-dt510 = ".*"

SRC_URI:append:imx8mm-jaguar-inst = " \
        file://imx8mm-jaguar-inst.dts \
"

COMPATIBLE_MACHINE:imx8mm-jaguar-inst = ".*"

SRC_URI:append:imx8mm-jaguar-phasora = " \
        file://imx8mm-jaguar-phasora.dts \
"

COMPATIBLE_MACHINE:imx8mm-jaguar-phasora = ".*"

SRC_URI:append:imx8mm-jaguar-handheld = " \
        file://imx8mm-jaguar-handheld.dts \
"

COMPATIBLE_MACHINE:imx8mm-jaguar-handheld = ".*"

SRC_URI:append:imx8ulp-lpddr4-evk = " \
        file://imx8ulp-evk.dts \
"

COMPATIBLE_MACHINE:imx8ulp-lpddr4-evk = ".*"

SRC_URI:append:imx93-jaguar-eink = " \
        file://imx93-jaguar-eink.dts \
"

COMPATIBLE_MACHINE:imx93-jaguar-eink = ".*"

SRC_URI:append:imx93-11x11-lpddr4x-evk = " \
        file://imx93-11x11-evk.dts \
"

COMPATIBLE_MACHINE:imx93-11x11-lpddr4x-evk = ".*"
