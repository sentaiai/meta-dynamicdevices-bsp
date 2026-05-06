# TAS2562 Driver Configuration
# This configuration enables the mainline TAS2562 driver with native TAS2563 support
# Uses the original TAS2562 driver which is register-compatible with TAS2563

# Machine feature definition
MACHINE_FEATURES_BACKFILL_CONSIDERED:append = " tas2562"

# TAS2562 driver is built into kernel with native TAS2563 support
# Remove any conflicting TAS2781 drivers and modules
MACHINE_EXTRA_RRECOMMENDS:remove = " \
    ${@bb.utils.contains('MACHINE_FEATURES', 'tas2562', 'kernel-module-tas2781 kernel-module-tas2563', bb.utils.contains('MACHINE_FEATURES', 'tas2563', 'kernel-module-tas2781 kernel-module-tas2563', '', d), d)} \
"

# Add TAS2563 firmware for TAS2562 driver (if needed)
MACHINE_EXTRA_RRECOMMENDS:append = " \
    ${@bb.utils.contains('MACHINE_FEATURES', 'tas2562', 'firmware-tas2563', bb.utils.contains('MACHINE_FEATURES', 'tas2563', 'firmware-tas2563', '', d), d)} \
"

# Ensure proper module loading order
KERNEL_MODULE_PROBECONF:append = " \
    ${@bb.utils.contains('MACHINE_FEATURES', 'tas2562', 'snd-soc-tas2562', bb.utils.contains('MACHINE_FEATURES', 'tas2563', 'snd-soc-tas2562', '', d), d)} \
"

# Configure TAS2562 module for optimal TAS2563 operation
# GPIO polarity is handled via device tree GPIO_ACTIVE_HIGH/LOW flags
