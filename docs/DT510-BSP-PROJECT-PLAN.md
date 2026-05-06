# DT510 BSP & hardware bring-up — project plan

Working document for aligning **Ollie Hull’s DT510 pinout / hardware specification** with **`meta-dynamicdevices-bsp`** (device tree, kernel fragments, and related recipes). Update this file as the spec evolves and as tasks complete.

---

## 1. Purpose

- Make the **i.MX 8M Mini Jaguar DT510** (`imx8mm-jaguar-dt510`) match the **approved hardware definition** in software (DT, drivers, tests).
- Apply changes in **safe phases** so we do not destabilise **boot**, **OTA**, or **already-working** subsystems (e.g. Wi‑Fi, USB gadget audio, cellular) without intent.

---

## 2. Source of truth (hardware)

| Document | Role |
|----------|------|
| **[VIX DT510 pinout / hardware spec](https://docs.google.com/document/d/1dlVcfW7SrOifR-rGjkJnVbnQBO4uU8HeS1MEfDmgcYE/edit?usp=sharing)** (Google Doc) | **Primary SSOT** for pinmux, buses, I2C addresses, and major components. |

**Rule:** Electrical / mechanical reality wins. The Google Doc is the **first-cut SSOT**; if we find errors on schematic or bring-up, **update the doc** (or an errata section here) and then change the BSP.

**Sentai vs DT510 (what is only on Sentai in the BSP, shared features, and open BOM questions):** see [**`DT510-HARDWARE-AUDIT-CHECKLIST.md` — Sentai vs DT510**](DT510-HARDWARE-AUDIT-CHECKLIST.md#sentai-vs-dt510-product-clarification). Use it for issue #2 and hardware handoff.

---

## 3. Repositories & where things live

| Repo | Role |
|------|------|
| **`DynamicDevices/meta-dynamicdevices-bsp`** (this repo) | Board DTS, kernel `*.cfg` fragments, `linux-lmp-fslc-imx_%.bbappend`, `lmp-device-tree.bbappend`, machine `imx8mm-jaguar-dt510.conf`, userspace recipes tied to the board. **This document lives here.** |
| **`vixdt` / Foundries factory** | Factory images, containers, `vix-apps`; coordinates with BSP for OTA and apps. |

### Foundries: how DT510 images get built and tested

The LmP manifest pulls **`meta-dynamicdevices-bsp`** (e.g. `main` from GitHub) into the factory build. **To trigger a Foundries build** for the DT510 factory line, the team **commits and pushes** to **`meta-subscriber-overrides`** on the active factory branch (e.g. **`main-imx8mm-jaguar-dt510`**) — remote **`source.foundries.io/factories/vixdt/meta-subscriber-overrides`**.

Typical layout: that repo lives beside other factory checkouts (e.g. under a **`vixdt`** workspace as `meta-subscriber-overrides/`). A small commit there (even a doc or comment bump) starts the pipeline that **repo syncs** layers and builds **`imx8mm-jaguar-dt510`**.

**Ordering:** Merge BSP changes to **`DynamicDevices/meta-dynamicdevices-bsp`** `main` first, **then** push **`meta-subscriber-overrides`** so the factory build picks up the new BSP revision (manifest tracks BSP `main` unless pinned otherwise).

**BSP revision policy (factory / CI):** For routine build testing, keep the LmP manifest / layer setup following **`meta-dynamicdevices-bsp` `main`** (upstream **`DynamicDevices/meta-dynamicdevices-bsp`**). Avoid long-lived pins to a fork or stray SHA unless a release explicitly requires it — it keeps Foundries builds aligned with merged BSP work and reduces merge-test friction.

**Key paths inside this BSP layer (relative to repo root):**

- Canonical DT for Factory/LmP flows: `recipes-bsp/device-tree/lmp-device-tree/imx8mm-jaguar-dt510.dts`
- Kernel recipe: `recipes-kernel/linux/linux-lmp-fslc-imx/imx8mm-jaguar-dt510.dts` → **symlink** to the canonical file (Tier A1).

**Single-DTS policy:** One file on disk; the kernel recipe path must remain a symlink to the `lmp-device-tree` copy (see §6).

**Reference (not built):** Tool-generated / review-only DTS snapshots from hardware (e.g. Ollie’s generator output) live under **`docs/reference/dt510-ollie-tool-generated/`**. Use them for **requirements review and diffs** only — not as the shipping device tree until merged deliberately into the recipes above.

**Hardware audit (SSOT ↔ BSP):** Living checklist — [`docs/DT510-HARDWARE-AUDIT-CHECKLIST.md`](DT510-HARDWARE-AUDIT-CHECKLIST.md).

**USB dual audio (gadget) vs codecs:** [`docs/DT510-USB-DUAL-AUDIO.md`](DT510-USB-DUAL-AUDIO.md) — gadget support **stays in the image**; enable/bind for simulation or leave stopped for real codec use. **`dt510-usb-dual-audio-autostart`** only toggles **boot autostart** (optional remove for codec-first boots).

**SE050:** [`docs/DT510-SE050.md`](DT510-SE050.md) — SSOT **I2C4 @ `0x48`** matches **existing OpTEE SE05x** (`I2C_BUS=3` = `&i2c4`), same as Sentai; DT510 machine `se05x` / OEFID already correct.

---

## 4. Guiding principles

1. **SSOT:** Pinout / BOM decisions follow the Google Doc unless superseded by a documented schematic change.
2. **One change vector per step:** Prefer small PRs/commits that can be reverted and bisected.
3. **Boot first:** Avoid large simultaneous changes to pinctrl, clock parents, and built-in kernel options.
4. **Prefer `=m`:** For new drivers, prefer modules until the integration is proven, where the kernel policy allows.
5. **DT before `CONFIG`:** Add or adjust nodes with correct `compatible` and `reg`; then enable **`CONFIG_*`** via existing fragment layout under `recipes-kernel/linux/linux-lmp-fslc-imx/imx8mm-jaguar-dt510/`.
6. **DT510 SSOT overrides Sentai inheritance:** The board DTS builds on **`imx8mm-evk`** and has historically shared snippets with **`imx8mm-jaguar-sentai.dts`**. Where the **DT510 hardware Google Doc / schematic** disagrees with something carried over from Sentai or EVK, **DT510 wins** — drop or replace inherited **gpio-hogs**, duplicate GPIO claims, or placeholders (e.g. TAS2563 **CODEC_SD#** vs `tas2563` **`reset-gpios`**) after review.

---

## 5. Phased work plan (priority × risk)

Work **in order** within each tier unless a dependency forces otherwise.

### Tier A — Do first (high value, low boot risk)

| ID | Task | Notes |
|----|------|--------|
| A1 | **Single DTS source** | **Done:** `linux-lmp-fslc-imx/imx8mm-jaguar-dt510.dts` → symlink to `lmp-device-tree/imx8mm-jaguar-dt510.dts` (canonical). |
| A2 | **SSOT header in DTS** | **Done:** Comment block after NXP copyright in canonical DTS (SSOT pointer, symlink note, plan + reference folder). |
| A3 | **Audit spreadsheet / checklist** | **Done:** [`docs/DT510-HARDWARE-AUDIT-CHECKLIST.md`](DT510-HARDWARE-AUDIT-CHECKLIST.md) — SSOT blocks vs BSP; update as doc/hardware changes. |
| A4 | **Placeholder nodes** | **Done:** `&i2c3` — **`bq25792@6b` enabled (Tier B1)**; `lt9611@39` **disabled**. **SE050:** same as **Sentai** — **no** SE050 child in Jaguar DTS; **OpTEE** + **`se05x`** / **`SE05X_OEFID`** (see [`DT510-SE050.md`](DT510-SE050.md)). Optional explicit **`&i2c4` / `se050@48`** in kernel DT is **not** required for parity with Sentai — **Tier B4** if you want Linux-visible node. |

**Tier A — status:** **Complete** on `main` (software + interim lab smoke: factory images boot, OTA/SSH, DTS intent). **Full validation** (BOM/schematic, per-block electrical test, SSOT sign-off) is **queued for prototype hardware** — use §9 and Tier **B/C** when boards land. Git tag: **`dt510-tier-a-test-1`** (annotated, points at BSP `main` at tag time).

### Tier B — Medium priority (important features, moderate risk)

| ID | Task | Notes |
|----|------|--------|
| B1 | **BQ25792** (charger, I2C3 `0x6B`, `CHGR_INT#`) | **Done (DT + lab path):** `battery-dt510` + `bq25792@6b` **okay**. **Kernel:** when **`bq25792-charger`** is enabled, **`linux-lmp-fslc-imx`** applies **0010–0024** (BQ25703A stack + mainline **`ti,bq25703a.yaml`** import + Patchew **v6** BQ25792 series). **`git am`** verified on **`Freescale/linux-fslc`** tip **`97812d71`** (re-verify if **`SRCREV_machine`** differs). **CHGR_INT#** in DTS (GPIO4_IO9). Lab: **`i2c-dev`** + **`i2c-2`**. Factory kernel identity: **`bitbake -e linux-lmp-fslc-imx \| grep SRCREV`**. See issue **#3**. |
| B2 | **Digital I/O** (GPIO1 per doc) | **Done (mux):** **`pinctrl_gpio1_dio`** for **GPIO1_IO0–9**; **disabled** EVK **`ir_recv`**, **`reg_pcie0`**, **`backlight`** that clashed or unused; **prototype:** validate with SSOT / libgpiod. |
| B3 | **CP2108** quad-UART | **Done (doc):** USB-enumerated; **DTS** comment — add **reset GPIO** only when SSOT names a pin. |
| B4 | **SE050** (I2C4 `0x48`) | **Done (doc):** Same as Sentai — **OpTEE** + **`se05x`**; optional Linux **`&i2c4`** child still **not** required — [`DT510-SE050.md`](DT510-SE050.md). |

### Tier C — Higher effort / higher risk (schedule + validate on hardware)

| ID | Task | Notes |
|----|------|--------|
| C1 | **Ethernet — `&fec1` + KSZ9896** | **Phase 1 (prove hardware):** single CPU netdev, **`&fec1` + `fixed-link`**, **no** DSA, **no** I²C switch node — in-tree **`microchip,ksz9896`** DSA uses **I²C/SPI** regmap, not MIIM as full switch management for this product’s strap; see [`docs/DT510-ETHERNET-KSZ9896.md`](DT510-ETHERNET-KSZ9896.md) (*Phased plan* + *Simple bring-up*). RGMII pinctrl = **SSOT / board (Ollie)**, not EVK, unless schematics match EVK ENET. **Future:** I²C/SPI strap + DSA or richer switch control when the product needs per-port / VLAN / manageability; incremental bring-up, risk of boot hang if MDIO/PHY wrong — validate link before “full” bridge features. |
| C2 | **Audio vs SSOT** | **TAS6424:** `pinctrl_sai1_tas6424`, **`&sai1` okay**, **`sound-tas6424`** (`simple-audio-card` → **`tas6424-classd`**), **`tas6424@6a` okay** with **`dvdd`** + placeholder **`tas6424_hi_rail`** for **vbat/pvdd** (SSOT must replace); **standby/mute GPIOs** when netlist confirms; **`CONFIG_SND_SOC_TAS6424=m`**; **micfil / sound-micfil** off. Still to do: **TAA5412**, **TAC5301**, TDM/4ch if needed. **I2C2 `0x50`:** TAC5301. |
| C3 | **HDMI — LT9611** (I2C3 `0x72`) | Reset/int/fault lines per doc; check pinctrl vs other GPIO users. |
| C4 | **CAN — MCP2518xx on ECSPI2** | **DT510 has no XM125** (Sentai only). `&ecspi2` free for CAN bring-up when ready. |
| C5 | **GNSS** | Reset line per SSOT — no XM125/radar GPIO contention on DT510. |

#### Tier C2 — Scoped codec sequence (prototype hardware)

**Lab / product order (Ollie, issue #2):** **TAS6424** → **TAA5412** → **TAC5301** — do **not** enable all three in one DT PR without a working slice in between. **TAC5301** is explicitly **lowest priority** until the first two are stable.

**TAS6424 DAI format:** Use **I2S** for initial software and lab testing (`sound-tas6424` already sets `simple-audio-card,format = "i2s"`). **TDM / 4-channel** stays a follow-on with hardware SSOT and issue #2 — not required for the first bring-up pass.

| Step | Part | Bus | Audio link (SSOT / tool mux) | BSP focus |
|------|------|-----|------------------------------|-----------|
| 1 | **TAS6424** (class-D) | I2C2 `0x6A` | **SAI1** (+ SAI6 pins muxed via `pinctrl_sai1_tas6424`) | Validate rails + GPIOs + `CONFIG_SND_SOC_TAS6424`; TDM vs I2S decision (#2). |
| 2 | **TAA5412** (mic) | I2C2 `0x51` | **SAI5** — *not in shipping DTS yet* | Add **`&sai5`** + SSOT `pinctrl`; codec **`compatible = "ti,taa5412"`**; **`CONFIG_SND_SOC_PCM6240`** — **not** in current factory i.MX 6.6 kernel (see **TAA5412 kernel status** below); backport/patch or kernel advance before `status = "okay"`. |
| 3 | **TAC5301** (analog audio) | I2C2 `0x50` | Per SSOT (enable after **0x50** free — TCPC already removed) | Node + supplies/MCLK/`simple-audio-card` link; align with kernel `CONFIG_*` when driver story is clear. |

**TAA5412 — kernel driver status (investigated 2026-04-14)**

- **Step-by-step backport plan (phases, rollback, firmware):** [`docs/DT510-TAA5412-PCM6240-BACKPORT-PLAN.md`](DT510-TAA5412-PCM6240-BACKPORT-PLAN.md) (note: **PCM6240**, not PCM6420 — confirm part if unsure).
- **Factory / LmP kernel** is **`linux-lmp-fslc-imx`** → NXP **`linux-fslc`** at **`SRCREV_machine`** pinned by **meta-lmp** (e.g. **`e0f9e2afd4cff3f02d71891244b4aa5899dfc786`**, **`LINUX_VERSION ?= 6.6.52`**, branch **`6.6-2.2.x-imx`** on **`meta-lmp`** `4dffdff79b4df49c683c9a7faea406595cb7e9ca`).
- At that commit: **no** `sound/soc/codecs/pcm6240.c`; **no** `CONFIG_SND_SOC_PCM6240` / **`ti,taa5412`** in `sound/soc/codecs/Kconfig`.
- **Mainline** carries **`ti,taa5412`** in **`sound/soc/codecs/pcm6240.c`** from **Linux 6.10** onward (same file covers PCM6240 family devices).
- **Practical options:** (1) **Backport** pcm6240 + `Kconfig`/`Makefile` + DT binding from **mainline ≥ 6.10** into a **`linux-lmp-fslc-imx`** `.bbappend` patch series (review for merge conflicts with NXP delta); (2) **Advance** factory kernel to a revision that already includes pcm6240 (if/when NXP/imx ships it); (3) **Out-of-tree** module recipe until (1) or (2). **Do not** enable the codec in DT for production until one path is chosen and probe is verified.

**Cross-links:** [`DT510-HARDWARE-AUDIT-CHECKLIST.md`](DT510-HARDWARE-AUDIT-CHECKLIST.md) table rows; **I2C2** also carries **TAS2563** @ `0x4C` (already enabled).

### Tier D — Defer / careful batching

| ID | Task | Notes |
|----|------|--------|
| D1 | **Wide pinctrl / hog rewrites** | e.g. pins shared between HDMI int, Wi‑Fi wake, etc. — **only** with schematic sign-off. |
| D2 | **Bulk built-in `CONFIG_*` changes** | Prefer incremental fragments and test images between steps. |

---

## 6. DTS duplication — action item

**Status:** **Implemented (2026-04-13).** Canonical: `recipes-bsp/device-tree/lmp-device-tree/imx8mm-jaguar-dt510.dts`. Kernel recipe: `recipes-kernel/linux/linux-lmp-fslc-imx/imx8mm-jaguar-dt510.dts` → relative symlink to the canonical file.

**Verify on next build:** `bitbake virtual/kernel` / `lmp-device-tree` unpack the symlink correctly; `dtc` / image still contains expected `imx8mm-jaguar-dt510.dtb`.

**Clones:** Windows checkouts without symlink support may need `git config core.symlinks true` or WSL; Linux/macOS are fine.

---

## 7. Known spec ↔ BSP gaps (from first-pass review)

Use [**`DT510-HARDWARE-AUDIT-CHECKLIST.md`**](DT510-HARDWARE-AUDIT-CHECKLIST.md) as the live table; §7 is a short summary.

| Area | SSOT (doc) | BSP today (summary) |
|------|------------|---------------------|
| Driver speaker | TAS2563 @ `0x4C`, SAI3 | Present |
| Analog / mic / class-D | TAC5301, TAA5412, TAS6424 on I2C2 + SAI5/6/1 | Not fully described; SAI1 disabled |
| I2C `0x50` | TAC5301 | **TCPC node removed** from DT510 DTS — address free for TAC5301 when Tier C2 enables it |
| Charger | BQ25792 @ `0x6B` | **DT enabled** — kernel charger driver pending suitable upstream/kernel version |
| HDMI | LT9611 (`0x72` 8-bit → `0x39` 7-bit) | Placeholder `lt9611@39` **disabled** — enable Tier C3 |
| Ethernet | KSZ9896 RGMII | `fec1` disabled |
| SE050 | I2C4 `0x48` | **OpTEE/Sentai-aligned** — see [`DT510-SE050.md`](DT510-SE050.md); optional explicit DT child |
| CAN | MCP2518xx, ECSPI2 | `&ecspi2` disabled — enable for CAN (no XM125 on DT510) |
| GNSS | NEO-M9V | Per SSOT |

---

## 8. Execution rhythm (how we work together)

1. **Kickoff:** Confirm SSOT revision (append date to §2 or errata below).
2. **Per slice:** Pick one Tier A/B item → DT + fragment + `defconfig`/fragment → build → **boot smoke test** → merge.
3. **Reviews:** BSP PRs reference this doc section ID (e.g. “B1”) and the Google Doc section if applicable.
4. **Errata:** Log schematic/doc corrections here before re-editing DTS.

### Errata / revisions (fill in)

| Date | Change |
|------|--------|
| 2026-04-13 | Tier A3 audit checklist; A4 I2C3 placeholders; plan §3/§7 synced. |
| 2026-04-13 | Linked §2 to **Sentai vs DT510** clarification in `DT510-HARDWARE-AUDIT-CHECKLIST.md` (issue #2 / product questions). |
| 2026-04-13 | DT510: **removed** `tcpc@50` from DTS; **`stusb4500`** from `MACHINE_FEATURES` (no TCPC / STUSB4500 on board per Ollie). Docs + `production-test.sh` + `stusb4500-nvm` bbappend aligned. |
| 2026-04-13 | **Tier B1:** `battery-dt510` + `bq25792@6b` enabled in DTS; CHGR_INT# + in-tree kernel driver **TBD**. |
| 2026-04-13 | **Tier C2 step 1:** TAS6424 — `&sai1` + SSOT `pinctrl_sai1_tas6424`; `tas6424@6a` **disabled** pending supplies/GPIO; micfil off; **`MACHINE_FEATURES` `tas6424`** gates `tas6424-audio-codec.cfg` (same pattern as **`tas2562`**). |
| 2026-04-13 | **Tier C2 step 2:** TAS6424 — `sound-tas6424` + **`tas6424@6a` okay**; **`tas6424_hi_rail`** placeholder (12V) for vbat+pvdd; **`tas6424-audio-codec.cfg`** uses active `CONFIG_SND_SOC_TAS6424=m` (not commented). |
| 2026-04-13 | **Verification:** Documented **software-first vs prototype lab** criteria (§9) — pre-prototype images prove **enablement in rootfs/DT/kernel**, not fitted-silicon discovery. |
| 2026-04-14 | **Tier C2 scope:** Documented codec order **TAS6424 → TAA5412 (SAI5, `0x51`) → TAC5301 (`0x50`, last)** for prototype bring-up; cross-links checklist. |
| 2026-04-14 | **TAA5412:** Confirmed **no `pcm6240` / `CONFIG_SND_SOC_PCM6240`** in **linux-fslc** @ LmP-pinned **`SRCREV`** (6.6.52); driver is **mainline ≥ 6.10** — backport, kernel advance, or out-of-tree (see plan §5 Tier C2). |
| 2026-04-14 | **DT510 `&i2c2`:** **`/delete-node/ tcpc@50;`** — drop EVK-inherited PTN5110 TCPC; frees **0x50** for TAC5301 per SSOT. |
| 2026-04-14 | **Factory / §3:** Documented **follow `meta-dynamicdevices-bsp` `main`** for build testing; **Tier C2:** lock **I2S** for initial TAS6424 test (TDM later). |
| 2026-04-14 | **Lab / §9:** BSP stack verified on **current lab DT510** (e.g. Foundries target **151**) — **interim** hardware, **not** final prototype BOM; full electrical sign-off when prototype boards land. |
| 2026-04-15 | **TAS2563 / §4:** Removed Sentai **`audio-shutdown-hog`** on **GPIO5_IO4** (**CODEC_SD#**); **`tas2563` `reset-gpios`** now sole owner — **DT510 SSOT** over Sentai inheritance. |
| 2026-04-15 | **DTS:** Removed unused **`pinctrl_pdm`** (SAI1 PDM mux) — **micfil** disabled; **TAS6424** owns SAI1; group was never referenced. |
| 2026-04-15 | **DTS / §4:** Removed Sentai **`xm125@52`** + **`pinctrl_xm125_radar`** — XM125 **Sentai-only** per SSOT; DT510 keeps **I2C3 `0x52`** free for other use if BOM allows. |
| 2026-04-15 | **Foundries #150 / USB:** **`/delete-node/ tcpc@50`** removed **`typec1_dr_sw`**; **`&usbotg1`** still had **`remote-endpoint = <&typec1_dr_sw>`** (imx8mm-evk.dtsi) → DTC **phandle_references** failure. Fix: **`&usbotg1`** **`/delete-node/ port;`** + **`/delete-property/ usb-role-switch`** for peripheral-only gadget. |
| 2026-04-14 | **Lab log / #10:** Logged @ohull456 **TAS6424** input (always-on rails; **AMP_STBY#** / **AMP_MUTE#** pending ball→GPIO); **I2C3** GPIOs for charger/HDMI **deferred**. |
| *earlier* | Initial plan from engineering review. |
| 2026-04-14 | **A4 / SE050:** Aligned with **Sentai** — neither DTS adds an SE050 node; **OpTEE** handles I²C. Removed incorrect “wait for `&i2c4` in DT” gate for A4; optional DT child stays **B4** / [`DT510-SE050.md`](DT510-SE050.md). |
| 2026-04-14 | **Tier A:** Marked **complete**; interim lab validation done — **prototype hardware** is the next gate for full electrical/SSOT testing. Annotated tag **`dt510-tier-a-test-1`**. |
| 2026-04-14 | **Tier B:** BQ25792 kernel **cfg** notes; **GPIO1_IO0–9** pinmux + disabled clashing EVK nodes (**`ir_recv`**, **`reg_pcie0`**, **`backlight`**); CP2108/SE050 documentation in DTS + plan. |

---

## 9. Boot & regression checklist (minimal)

After each BSP change set:

- [ ] Image builds (`lmp-factory-image` or agreed target).
- [ ] Board boots to userspace / SSH or serial console.
- [ ] `dmesg` — no new critical probe failures on **unchanged** peripherals.
- [ ] If audio/USB/Wi‑Fi touched: run existing **DT510 smoke** (team script or manual) as available.

### Verification phases — software enablement vs prototype hardware

Use the right bar for the board you are flashing:

**Before the new prototype hardware is available** (interim boards, EVK-derived bring-up, or images exercised without fitted silicon), validate **software readiness** — not whether parts respond on the bus:

**Status (2026-04):** The BSP changes to date (Sentai tidyups, TCPC/USB gadget path, codec/DT alignment) have been **validated on current lab hardware** — boot, OSTree, SSH, live DT, and key drivers as checked — but that hardware is **not** the **final prototype BOM** yet. Treat this as **software + interim electrical** confidence; **re-run checklist and SSOT review** when prototype boards are available (pinmux, rails, fitted vs disabled nodes).

- **Image / machine:** Correct Foundries factory, machine, tag, and build number (e.g. `IMAGE_VERSION` / `os-release`); DT **`compatible`** includes **`fsl,imx8mm-jaguar-dt510`**.
- **Kernel:** Expected **`CONFIG_*`** and **`.ko`** modules under `/lib/modules/$(uname -r)/` for the BSP fragments you added (codecs, gadget, I²C/SAI as applicable). Use `zcat /proc/config.gz` and module paths when available.
- **Device tree shipped:** The booted DTB matches the **canonical DTS intent** (nodes, `status`, disabled blocks). **Success = boot to userspace without fatal DT errors** — **do not require** I²C devices to appear, drivers to bind to real chips, or ALSA playback.
- **Userspace / distro:** Recipes, systemd units, and **`MACHINE_FEATURES`**-gated behaviour as designed.

**After prototype hardware is in the lab**, add **electrical validation**: bus scans, ALSA cards and audio path, charger / power, and targeted `dmesg` review for probe failures.

**Note:** DT510 includes **`freescale/imx8mm-evk.dts`**. Interim units may still show **EVK-inherited** peripherals in DT or on buses. **Do not** treat “component not found on the bench” as a failed BSP merge unless the goal of that milestone was lab proof — distinguish **software delivered in the image** from **silicon present on the PCB**.

---

## 10. Owners & contacts

| Role | Name | Notes |
|------|------|--------|
| Hardware SSOT | Ollie Hull | Pinout / schematic clarifications; **lab verification** on DT510 hardware |
| BSP / DT | Alex Lennon | `meta-dynamicdevices-bsp`; implements changes and **posts handoff** on the tracking issue |
| Factory / apps | *assign* | `vixdt` / containers as needed |

---

## 11. Keeping the tracking issue up to date (BSP ↔ lab)

**Tracking issue:** [DynamicDevices/meta-dynamicdevices-bsp#2](https://github.com/DynamicDevices/meta-dynamicdevices-bsp/issues/2)

Use that issue as the **running thread** for “what landed” and “what was verified on hardware.” This markdown file stays the **structured plan**; the issue holds **time-ordered** handoffs and results so nothing relies on chat memory.

### Roles

| Who | Responsibility |
|-----|----------------|
| **Alex (BSP)** | After each meaningful change (or stack of small commits): add an **Implementation** comment on #2 (use template below). Link the **PR or commit SHA** and name the **tier ID** (e.g. A1). Flash/build instructions if non-obvious. |
| **Ollie (lab)** | When a build is available, run **agreed checks** on the DT510 in the hardware lab and add a **Lab result** reply on **the same thread** (template below). Note **PASS / FAIL / PARTIAL**, anomalies, and whether the pinout doc needs errata. |

### Cadence (lightweight)

1. **Implement** → merge to `main` (or share a PR build for early test).
2. **Comment on #2** (Implementation) — same day.
3. **Ollie tests** when the image is on the bench — **Lab result** comment.
4. **Update this doc** (PR): errata (§8), **lab log** (below), or tier notes — so the repo stays auditable.

### Comment template — Implementation (Alex)

Paste into [#2](https://github.com/DynamicDevices/meta-dynamicdevices-bsp/issues/2):

```text
### Implementation — [Tier XX] short title

- **Commit / PR:** `<sha>` / `#<pr>`
- **Scope:** (1–3 bullets: what changed in DT / kernel / recipes)
- **Image / artifact:** (e.g. Foundries build #, local WIC path, OTA target — whatever Ollie should flash)
- **Please verify in lab:**
  - [ ] Boot / serial or SSH
  - [ ] (specific checks for this change, e.g. `i2cdetect`, interface up, audio path)
- **Risks if any:** (regressions to watch)
```

### Comment template — Lab result (Ollie)

Reply under the matching Implementation thread (or quote it):

```text
### Lab result — [same Tier / title]

- **Build tested:** `<how identified — commit/sha/build #>`
- **Outcome:** PASS | FAIL | PARTIAL
- **Notes:** (what worked, what failed, `dmesg` snippets if useful)
- **Pinout doc / schematic:** OK | needs errata — (details)
```

### Lab verification log (update via PR to this file)

| Date | Tier | Commit / ref | Summary | Lab outcome |
|------|------|--------------|---------|-------------|
| 2026-04-14 | **B** | `1062677` | GPIO1 DIO pinmux; EVK **ir_recv** / **reg_pcie0** / **backlight** off; **bq25792-charger.cfg** kernel notes. | Prototype: validate mux + **CHGR_INT#** when SSOT ready. |
| 2026-04-14 | **A (complete)** | **`dt510-tier-a-test-1`** → `main` @ tag | **A1–A4** done; Sentai parity + DT cleanup; SE050 via OpTEE like Sentai. | Interim HW: PASS smoke (boot/SSH/DT). **Prototype BOM:** full test **pending** new boards. |
| 2026-04-14 | C2 / HW | [#2](https://github.com/DynamicDevices/meta-dynamicdevices-bsp/issues/2) @ohull456 | **TAS6424:** rails always-on (no SW sequencing); **AMP_STBY#** / **AMP_MUTE#** high for run, no pulls, no other use; **ball→GPIO TBD** for DTS. **I2C3** charger/HDMI GPIOs deferred (low pri). | N/A lab until GPIO mapping + prototype bench. |
| 2026-04-13 | A1–A2 | `d78fe3b` | Single DTS symlink + SSOT header; no hardware change. | N/A — confirm next image builds / boots unchanged. |
| 2026-04-13 | A3–A4 | `66d5c1f` | Audit checklist + disabled `bq25792` / `lt9611` placeholders on `&i2c3`. | Expect boot unchanged; `i2cdetect` may show `6b` / `39` if bus scanned. |

### Tips

- **One Implementation comment per “testable slice”** — avoids Ollie guessing what changed.
- If a change is **software-only** (no lab needed), say so in the Implementation comment and still log “N/A lab” in the table when you update the doc.
- For **FAIL**, open a **sub-issue** or reply with `@mention` only if you need a follow-up fix; keep #2 as the parent tracker.

---

*Last updated: 2026-04-14 — Tier B implemented (BQ25792 cfg notes, GPIO1 DIO mux, EVK disables, doc)*
