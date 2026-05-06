# TAA5412 — PCM6240 driver backport plan (i.MX 6.6 factory kernel)

**Purpose:** Step-by-step plan to add **Texas Instruments PCM6240-family** ASoC support (including **`ti,taa5412`**) to the **existing** `linux-lmp-fslc-imx` / **Freescale `linux-fslc`** line **without** destabilising unrelated audio, boot, or OTA.

**Naming:** Mainline uses **`sound/soc/codecs/pcm6240.c`** and **`CONFIG_SND_SOC_PCM6240`**. If you searched for “PCM6420”, confirm part number — **TAA5412** is bound via **`ti,taa5412`** in the **PCM6240** driver family.

**Related:** [`DT510-BSP-PROJECT-PLAN.md`](DT510-BSP-PROJECT-PLAN.md) Tier C2 · Issue [#2](https://github.com/DynamicDevices/meta-dynamicdevices-bsp/issues/2)

---

## 1. Difficulty (honest summary)

| Factor | Assessment |
|--------|------------|
| **Code size** | **~2.2k lines** `pcm6240.c` + **~250 lines** `pcm6240.h` (mainline), plus **Kconfig** / **Makefile** / **DT binding** |
| **Risk** | **Medium–high** — large new driver; **merge conflicts** with NXP `linux-fslc` delta; **firmware** (`.bin`) may be required for full behaviour |
| **Skill** | ASoC + regmap + Yocto kernel bbappend experience |
| **Time** | Order of **several days** for a careful first integration + **hardware** validation (not a single afternoon) |

**Why it can break things:** incorrect Kconfig dependencies, `Makefile` ordering, or probe regressions on **I2C2** shared with **TAS2563 / TAS6424 / TAC5301** if DT enables nodes prematurely.

---

## 2. Principles (do not break the platform)

1. **Kernel ABI unchanged for existing modules** — add **`CONFIG_SND_SOC_PCM6240=m`** (module preferred); do not turn on “build all codecs” unless you accept image size and QA cost.
2. **Device tree:** start with **`status = "disabled"`** until driver loads and supplies/GPIOs are confirmed.
3. **One change vector per phase** — merge **driver + build** before **enabling** TAA5412 in DT.
4. **Always** keep a **known-good** kernel image / OTA path to roll back.
5. **Rebase** on the **exact** `SRCREV` your factory uses — document it in the PR/issue.

---

## 3. Preconditions (before writing patches)

- [ ] Record **pinned** `linux-lmp-fslc-imx` **`SRCREV_machine`**, **`LINUX_VERSION`**, and **`KERNEL_BRANCH`** from **meta-lmp** (and your **lmp-manifest** pin).
- [ ] Clone **Freescale `linux-fslc`** at that **commit** locally for patch development.
- [ ] Identify **mainline commits** that introduced **`pcm6240`** (use `git log -- sound/soc/codecs/pcm6240.c` on `torvalds/linux` from first introduction through **TAA5412** / `ti,taa5412` support).
- [ ] List **dependencies**: e.g. `regmap`, `firmware` API — usually already satisfied on 6.6; watch for **ASoC API** differences between **6.6** and **6.10+** (may need small adaption in backport, not blind cherry-pick).
- [ ] Read **TI** docs for **TAA5412** — confirm **I2C address** (`0x51` 7-bit per SSOT), **MCLK**, and whether **coefficient firmware** files are mandatory for your use case.

---

## 4. Phased plan of action

### Phase A — Patch preparation (offline)

1. **Export** a minimal patch series from mainline (or a single squashed patch) adding:
   - `sound/soc/codecs/pcm6240.c`
   - `sound/soc/codecs/pcm6240.h`
   - `sound/soc/codecs/Kconfig` + `Makefile` hunks for **`SND_SOC_PCM6240`**
   - `Documentation/devicetree/bindings/sound/ti,pcm6240.yaml` (optional for kernel build; useful for DT checks)
2. **Apply** onto **linux-fslc @ factory SRCREV** in a **local git** tree; resolve conflicts **only** in new files first if possible.
3. **If** ASoC APIs differ: add small **adapt** patches (document each hunk — “for 6.6.52 imx”).

### Phase B — Yocto integration (BSP layer)

1. Add patches under **`recipes-kernel/linux/linux-lmp-fslc-imx/`** (same pattern as existing `0008-*.patch` style).
2. Extend **`linux-lmp-fslc-imx_%.bbappend`**:
   - **`SRC_URI:append:imx8mm-jaguar-dt510`** (or machine-agnostic if appropriate) with patch files **in order**.
   - Add **`imx8mm-jaguar-dt510/pcm6240-audio-codec.cfg`** with **`CONFIG_SND_SOC_PCM6240=m`** (and any required `CONFIG_*` depends — mirror mainline `Kconfig` “depends on”).
3. **Optional:** gate with **`MACHINE_FEATURES`** (e.g. **`taa5412`**) like **`tas6424`**, so factory images can omit the module until ready.

### Phase C — Build validation (no hardware enable yet)

1. **`bitbake virtual/kernel`** (or CI) — must **complete** with **no** new `QA` warnings you care about.
2. Inspect **`/proc/config.gz`** (or deployed `config`) for **`CONFIG_SND_SOC_PCM6240=m`**.
3. **Install** image on **DT510** — **boot smoke**: existing **TAS2563**, **Wi‑Fi**, **USB**, **OTA** unchanged.
4. **`modprobe snd_soc_pcm6240`** — should **fail gracefully** if no device (expected) or **not load** if DT missing — **no kernel panic**.

### Phase D — Device tree (disabled node first)

1. Add **`&i2c2`** child **`taa5412@51`** (or name per binding) with **`compatible = "ti,taa5412"`**, **`reg = <0x51>`**, **`status = "disabled"`**.
2. Add **`&sai5`** + **`pinctrl_sai5_*`** from **SSOT** / `docs/reference/dt510-ollie-tool-generated/pin_mux.dts` — **do not** hog pins that clash with **Ethernet / HDMI / other** tiers.
3. **Do not** add a full **`sound-card`** until Phase E — or add **card** with codec **disabled** to avoid premature DAI probe (team preference).

### Phase E — Enable + audio path

1. **Supplies / GPIO** (from SSOT): `AVDD`, `DVDD`, reset, etc. — match driver binding.
2. **`status = "okay"`** on codec + **`simple-audio-card`** (or fsl-asoc) **CPU `&sai5` ↔ codec**.
3. **Firmware:** if driver requests **`.bin`** files, add **`linux-firmware`** bbappend or recipe install — **verify paths** in `dmesg`.
4. **Userland:** `aplay -l`, capture/playback test at **safe** levels.

### Phase F — Regression & sign-off

- [ ] Re-run **DT510 smoke** (team script or agreed checklist).
- [ ] **OTA** one cycle with new image (if applicable).
- [ ] Update [**`DT510-HARDWARE-AUDIT-CHECKLIST.md`**](DT510-HARDWARE-AUDIT-CHECKLIST.md) and **issue #2** with **PASS** / **PARTIAL** + build id.

---

## 5. Rollback / failure criteria

**Stop and revert** if any of:

- `virtual/kernel` fails to build or **defconfig** merge breaks **unrelated** `CONFIG_*`.
- Boot **regression** (hang, USB, Wi‑Fi, existing **tas2563** card missing).
- **`dmesg`** shows **repeated I2C errors** or **probe -EPROBE_DEFER** loops affecting **other** `i2c-2` devices.

**Rollback:** revert BSP commit(s); re-flash **previous** known-good image; keep **subscriber-overrides** manifest pointer to last good build.

---

## 6. Firmware / coefficient blobs

The mainline driver uses **`request_firmware()`** for register/coefficient binaries in some flows. Before declaring “done”:

- Confirm **which** `.bin` files (if any) **TAA5412** needs on your board.
- Package under **`/lib/firmware`** (or vendor path) and verify **file names** match driver expectations.

---

## 7. Ownership

| Who | Responsibility |
|-----|----------------|
| **BSP** | Patch series, bbappend, cfg fragment, **`MACHINE_FEATURES`** gating, DT **disabled** → **okay** sequence |
| **Hardware** | SSOT pins, rails, **I2C** address, **MCLK**, speaker/mic safety for tests |
| **Lab** | Phases C–E validation on **prototype** hardware; issue **#2** results |

---

*Last updated: 2026-04-14 — PCM6240 backport planning; kernel tree unchanged until patches are merged.*
