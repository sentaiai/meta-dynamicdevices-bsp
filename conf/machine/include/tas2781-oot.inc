# TI out-of-tree TAS2781 integrated driver for TAS2563 @ I2C 0x4C.
# Firmware is installed by kernel-module-tas2781 (tas2563-1amp-reg.bin, tas2563-1amp-dsp.bin).

MACHINE_FEATURES_BACKFILL_CONSIDERED:append = " tas2781-oot"

MACHINE_EXTRA_RDEPENDS:append = " \
    ${@bb.utils.contains('MACHINE_FEATURES', 'tas2781-oot', 'kernel-module-tas2781', '', d)} \
"

# Built-in mainline TAS2781/TAS2562 must not load; OOT module owns the codec.
MACHINE_EXTRA_RRECOMMENDS:remove = " \
    ${@bb.utils.contains('MACHINE_FEATURES', 'tas2781-oot', 'firmware-tas2563 kernel-module-tas2563', '', d)} \
"
