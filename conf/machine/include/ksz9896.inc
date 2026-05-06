# Microchip KSZ9896 — DSA Ethernet switch (I2C management + built-in PHYs).
# Kernel fragments `ksz9896-ethernet-switch.cfg` + `ksz9896-mii-phy.cfg` are appended from
# linux-lmp-fslc-imx_%.bbappend when MACHINE_FEATURES contains `ksz9896`.

MACHINE_FEATURES_BACKFILL_CONSIDERED:append = " ksz9896"
