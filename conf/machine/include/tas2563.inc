# TI TAS2563 smart amplifier — kernel uses the TAS2562 ASoC stack + tas2781/tas2563 patches
# (`CONFIG_SND_SOC_TAS2562`, `ti,tas2563`). Fragments are gated from linux-lmp-fslc-imx_%.bbappend
# when MACHINE_FEATURES contains `tas2563`.
#
# To disable on a machine that includes this file: MACHINE_FEATURES:remove:<machine> = " tas2563"

MACHINE_FEATURES_BACKFILL_CONSIDERED:append = " tas2563"
