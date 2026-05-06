# DT510 hardware audit checklist (SSOT ↔ BSP)

**Purpose:** Track each major block from the [VIX DT510 hardware SSOT](https://docs.google.com/document/d/1dlVcfW7SrOifR-rGjkJnVbnQBO4uU8HeS1MEfDmgcYE/edit?usp=sharing) against **`imx8mm-jaguar-dt510.dts`** and kernel fragments. Update as the doc or board changes.

**Milestone:** [Project plan §5 Tier A](DT510-BSP-PROJECT-PLAN.md#tier-a--do-first-high-value-low-boot-risk) is **complete** on `main` (test tag **`dt510-tier-a-test-1`**). Interim lab boards validated boot/software; **full SSOT ↔ bench checks** target **prototype hardware** when available.

**Related:** [`DT510-BSP-PROJECT-PLAN.md`](DT510-BSP-PROJECT-PLAN.md) · **I²C bus / runtime status (update per build):** [`DT510-HARDWARE-I2C-STATUS.md`](DT510-HARDWARE-I2C-STATUS.md) · Tool reference: [`reference/dt510-ollie-tool-generated/`](reference/dt510-ollie-tool-generated/) · **Sentai vs DT510:** [§ below](#sentai-vs-dt510-product-clarification)

**Legend — BSP status:** present | partial | missing | placeholder | conflict | N/A

---

## Sentai vs DT510: product clarification

Machine: **`imx8mm-jaguar-sentai`** vs **`imx8mm-jaguar-dt510`**. Use this when triaging “is this hardware only on Sentai?” or [meta-dynamicdevices-bsp#2](https://github.com/DynamicDevices/meta-dynamicdevices-bsp/issues/2). **BSP references:** `conf/machine/imx8mm-jaguar-sentai.conf`, `conf/machine/imx8mm-jaguar-dt510.conf`, `recipes-bsp/device-tree/lmp-device-tree/imx8mm-jaguar-sentai.dts`, `imx8mm-jaguar-dt510.dts`.

### Different by design in the BSP

| Topic | Sentai | DT510 |
|--------|--------|--------|
| **Acconeer XM125 radar** | `MACHINE_FEATURES` includes **`xm125-radar`**; DTS **`xm125@52`** enabled; **`xm125-radar-monitor`** recipe is **`COMPATIBLE_MACHINE = imx8mm-jaguar-sentai`** only | XM125 **not populated**; **`xm125@52`** + **`pinctrl_xm125_radar`** **removed** from DT510 DTS (Sentai only); no **`xm125-radar`** feature |
| **USB dual UAC2 gadget autostart** | Not a DT510-specific machine feature | **`dt510-usb-dual-audio-autostart`** — toggles **boot** autostart of the lab/simulated gadget path (see [`DT510-USB-DUAL-AUDIO.md`](DT510-USB-DUAL-AUDIO.md)) |
| **Charger / HDMI placeholders** | Not in the DT510-vs-Sentai DTS diff as matching disabled nodes | **`bq25792@6b` enabled** (Tier B1 — kernel charger TBD); **`lt9611@39` disabled** — confirm **BOM** when enabling HDMI |
| **STUSB4500 / USB‑C PD** | `MACHINE_FEATURES` **`stusb4500`**; PD firmware / distro feature | **Not on DT510** — IC not populated; **`stusb4500`** removed from `imx8mm-jaguar-dt510.conf` |
| **PTN5110 / TCPC @ `0x50`** | Legacy **`tcpc@50`** in Jaguar DTS variants | **Not on DT510** — node **removed** from `imx8mm-jaguar-dt510.dts`; **`0x50`** reserved for **TAC5301** per SSOT |

### Same `MACHINE_FEATURES` stack in both machine configs (not Sentai-only)

Both append **`nxpiw612-sdio`**, **`zigbee`**, **`tas2562`**, and the same **`se05x`** / **`SE05X_OEFID`** pattern (when not local-dev). **Sentai** also enables **`stusb4500`** (`MACHINE_FEATURES`); **DT510 does not** — no STUSB4500 USB‑PD IC on board (not USB‑C powered). Wi‑Fi, Zigbee, amp, and SE050-class bring-up are not Sentai-only; **USB‑PD** is.

**Product check:** `imx8mm-jaguar-dt510.conf` notes Wi‑Fi may still follow **Sentai for demo** until new hardware — confirm whether DT510 **hardware** matches Sentai or only the **software** profile.

### Historical (Sentai DTS comments only)

Sentai comments refer to **BGT 60TR13C** radar **replaced by XM125** during bring-up. That is **lineage** on older Sentai work, not an assumption for DT510. Useful when reconciling **old Sentai boards** vs current BOM.

### Open by SKU (use the table below + project plan)

**CAN, GNSS, Ethernet switch, full audio codec set, HDMI** depend on **what is fitted** — not a single global “Sentai yes / DT510 no” flag. **ECSPI2:** on Sentai the XM125 GPIO story used those pins; on DT510 **`&ecspi2`** is **free for CAN** (e.g. MCP2518xx) when ready — see plan tiers C4/C5.

| SSOT block | Bus / address (SSOT) | BSP status | Notes / DT / driver | Plan tier |
|------------|----------------------|------------|----------------------|-----------|
| Analog audio **TAC5301** | I2C2 `0x50` | missing | **No TCPC on DT510** — legacy `tcpc@50` **removed** from DTS; address free for TAC5301 per SSOT (enable Tier C2 when ready) | C2 |
| Driver speaker **TAS2563** | I2C2 `0x4C`, SAI3 | present | `tas2563@4C`, `sound-tas2563`, `&sai3` | — |
| Mic **TAA5412** | I2C2 `0x51` | missing | SAI5 — not in DTS; **`ti,taa5412`** / **`snd_soc_pcm6240`** — **not** in factory **linux-fslc 6.6.52** @ LmP SRCREV; mainline **6.10+** — backport/kernel bump/out-of-tree before enable | C2 |
| Class-D **TAS6424** | I2C2 `0x6A`, SAI1 | **enabled (validate)** | **`tas6424@6a` okay** + **`sound-tas6424`** (`tas6424-classd`); **`tas6424_hi_rail`** placeholder for vbat/pvdd — **confirm SSOT**; **`&sai1` okay** + `pinctrl_sai1_tas6424`; **`&micfil` / `sound-micfil` disabled**; `CONFIG_SND_SOC_TAS6424=m` | C2 |
| Charger **BQ25792** | I2C3 `0x6B`, `CHGR_INT#` | **partial (validate probe)** | **`bq25792@6b` enabled** + `simple-battery`; BSP kernel patches **0010–0024** (BQ25703A stack + binding import + Patchew v6 BQ25792) when **`bq25792-charger`** — **`git am`** checked on fslc **`97812d71`**; re-verify on your **`SRCREV`**. **CHGR_INT#** in DTS (GPIO4_IO9). Lab: **`i2c-dev`** on **`i2c-2`**. **Issue #3.** | B1 |
| HDMI **LT9611** | I2C3 — SSOT `0x72` (8-bit) → DT **7-bit `0x39`** | placeholder | `lt9611@39` **disabled** in DTS — enable Tier C3 | C3 |
| Auth **SE050** | I2C4 `0x48` | **aligned with stack** | OpTEE **`CFG_CORE_SE05X_I2C_BUS=3`** = **`&i2c4`** (same as Sentai). Machine `se05x` + OEFID set. Optional: explicit DT node — see [`DT510-SE050.md`](DT510-SE050.md) | B4 |
| **MCP2518xx** CAN | ECSPI2 + GPIO | missing | `&ecspi2` disabled — **not** XM125 on DT510 (Sentai only); enable for CAN when ready | C4 |
| Ethernet **KSZ9896** | ENET RGMII + **MIIM (MDC/MDIO)** | in DT (validate) | `&fec1` + `mdio` subnode, **no** KSZ on I²C; DSA I²C not used — see `docs/DT510-ETHERNET-KSZ9896.md` | C1 |
| GNSS **NEO-M9V** | GPIO reset | missing | Per SSOT — no XM125 on DT510 (frees GPIOs that Sentai used for radar) | C5 |
| HDMI misc **HDMI2C1-6C1** | GPIO | partial | Fault line per SSOT — align with LT9611 bring-up | C3 |
| **CP2108** quad-UART | GPIO reset | **doc / optional DT** | USB enumeration; DTS comment — add GPIO when SSOT names reset | B3 |
| Digital I/O | GPIO1_IO0–9 | **partial** | **`pinctrl_gpio1_dio`** + EVK **`ir_recv` / `reg_pcie0` / `backlight`** disabled; validate on prototype | B2 |
| **MAYA-W276** (Wi‑Fi / BT / 802.15.4) | SDIO, SPI, UART, SAI2 | partial | `&usdhc2`, `&ecspi1`, `&uart1`, `&sai2` etc. | — |
| **STUSB4500** / USB‑C PD | — | **N/A (DT510)** | **Not populated** — no `stusb4500` machine feature; gadget uses **`&usbotg1`** peripheral only (see `DT510-USB-DUAL-AUDIO.md`). **Sentai** retains STUSB4500. | — |
| **USB dual UAC2 gadget** | `usbotg1` peripheral + systemd | present | **Simulated / lab** path — see [`DT510-USB-DUAL-AUDIO.md`](DT510-USB-DUAL-AUDIO.md); feature `dt510-usb-dual-audio-autostart` | — |
| **XM125** radar | — | **N/A (DT510)** | **Sentai only** — not on DT510; **`xm125@52`** node **not present** in `imx8mm-jaguar-dt510.dts` | — |

\* SSOT “0x72” for LT9611 is treated as **8-bit** address; Linux `reg` uses **7-bit** `0x39`.

---

## Next actions (from this audit)

**Tier C2 codec order (prototype DT510 — see plan §5 Tier C2 scoped sequence):**

1. **TAS6424** @ `0x6A` / SAI1 — validate on hardware (kernel config, card, rails/GPIOs per #2); then TDM vs I2S if product chooses TDM.
2. **TAA5412** @ I2C2 **`0x51`** / **SAI5** — add **`&sai5`** + pinctrl from SSOT / `pin_mux` reference; **kernel:** **pcm6240** driver **absent** from **6.6.52** imx tree — choose backport (mainline ≥ **6.10**), kernel advance, or out-of-tree (**plan §5**); then codec + ALSA card.
3. **TAC5301** @ I2C2 **`0x50`** — **last** (low priority per lab). TCPC already removed; enable node + audio link when SSOT + driver path are ready.

**Other tiers**

4. **Tier B1 (follow-up):** Add **CHGR_INT#** to DTS when GPIO is in SSOT; enable **CONFIG_MFD_BQ257XX** / **CONFIG_CHARGER_BQ257XX** when factory kernel ships **bq257xx** (see **`bq25792-charger.cfg`** notes).
5. **Tier C3:** LT9611 + reset/int pinctrl from SSOT.
6. **Tier B4:** Optional explicit `&i2c4` + SE050 DT node for kernel; **Tier B** closed at **doc** parity with Sentai — see [`DT510-SE050.md`](DT510-SE050.md).

---

*Last updated: 2026-04-14 — Tier C2 codec order; TAA5412/pcm6240 kernel investigation (see plan §5).*
