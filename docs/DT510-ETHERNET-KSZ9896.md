# DT510 — KSZ9896CTXC Ethernet (bring-up)

## Phased plan (product intent)

1. **Now — DSA over I²C:** EE straps **KSZ9896** management to **I²C** (same strap pins as MIIM/SPI options per datasheet). BSP enables **`microchip,ksz9896`** on **`&i2c2`** **`switch@5f`** (**placeholder bus + 7-bit address** until pinout/strap SSOT — move node / adjust **`reg`** when confirmed).
2. **Earlier lab — MIIM-only:** older trees used **`&fec1`** **`mdio`** **`ethernet-phy@1`…`@5`** for Clause **22** probe only; that **`mdio`** block is **removed** once DSA owns the switch.

This doc is updated for the **I²C + DSA** device tree; §“Simple bring-up (analysis)” below still explains RGMII concepts.

**Hardware (EE):** management strap **I²C** — SoC **SDA/SCL** route to the KSZ strap pins (confirm controller + pins with **Ollie**). **MDC/MDIO** are **not** used for switch register access in this mode (pads may remain muxed for unused Clause-22 visibility only if hardware ties them).

**Linux / mainline:** **`microchip,ksz9896`** attaches via **`devm_regmap_init_i2c()`** (`ksz9477_i2c.c`). Internal PHY / XMII control uses the switch driver over that bus — **not** FEC MIIM for **`0x6301`**.

**Implemented DT (`imx8mm-jaguar-dt510.dts`):**

- **`&iomuxc`:** `pinctrl_fec1_dt510` — RGMII (+ legacy MDC/MDIO mux where routed), **Ollie** / SSOT.
- **`&fec1`:** `phy-mode = "rgmii-txid"`, **`fixed-link` 1G** + **`pause`**; **no** `phy-handle`; **no** FEC **`mdio`** — CPU MAC ties to DSA only.
- **`&i2c2`:** **`switch@5f`** **`microchip,ksz9896`**: **`interrupts`** on **GPIO4_IO0**, **`reset-gpios`** on **GPIO4_IO1**; **`ethernet-ports`** with **`phy-handle`** → internal **`mdio { ethernet-phy@0…@3 }`** (**Microchip EVB-style**); CPU **`port@5`** **`rgmii-txid`** + **`tx-internal-delay-ps = <2000>`** + **`fixed-link`** **`pause`**.
- **Kernel:** `ksz9896-ethernet-switch.cfg` enables **`CONFIG_NET_DSA_MICROCHIP_KSZ_COMMON`** + **`CONFIG_NET_DSA_MICROCHIP_KSZ9477_I2C`**; `ksz9896-mii-phy.cfg` retains PHYLIB helpers for integrated PHY code paths.

## KSZ9896C Port 6 — RGMII (default straps + DS §4.11.4)

DT510 is **pin-strapped** so **MAC Port 6** uses **RGMII** at **1000 Mbps**, consistent with **`&fec1`** / switch **`port@5`** **`rgmii-txid`** + **`fixed-link`** **1 Gbit/s full-duplex** (plus **`pause`** where enabled in DTS).

### Configuration straps (DS §3.2.1, Table 3-3)

| Strap | Function | Default relevant to **RGMII** |
|-------|-----------|--------------------------------|
| **RXD6_3, RXD6_2** | Port 6 interface mode | **00 = RGMII (Default)** |
| **RXD6_1** | MII / RMII / GMII sub-mode | **RGMII: No effect** |
| **RXD6_0** | Port 6 speed (when in RGMII) | **0 = 1000 Mbps (Default)** — strap **1** selects **100 Mbps** RGMII; **MII/RMII** straps require **100 Mbps** per datasheet |

With **weak internal pulls** and **no conflicting PCB overrides**, this matches **RGMII @ 1 G** bring-up.

### §4.11.4 Reduced Gigabit MII (RGMII) — behaviour (summary)

Per **DS00002390C §4.11.4** (see also **Table 4-35**):

- **12 signals** vs GMII’s **24**; **TXD6_[3:0]** / **RXD6_[3:0]** carry a **nibble** per clock edge at **1000 Mbps** (DDR timing).
- **TX_CLK6** is sourced by the **MAC** (i.MX FEC) at **125 MHz** (1000 M), **25 MHz** (100 M), **2.5 MHz** (10 M).
- **RX_CLK6** is sourced by the **KSZ** Port **6** side at the **same rate family** for each speed.
- **TX_CTL6** / **RX_CTL6** multiplex **enable + error** / **DV + ER**; control is valid on the **falling edge** of the respective clock (RGMII spec timing).
- **There is no mechanism for RGMII to adapt speed automatically** to the link partner. Straps set **1000 vs 100 Mbps** at reset; **XMII Port Control** registers can override speed (**including 10 Mbps**) per §4.11.4.

### Internal RGMII delay — **confirmation from DS00002390C** (XMII Port Control 1, **`0x6301`**)

§**4.11.4** and §**5.2.3.2** (**XMII Port Control 1 Register**, **`0xN301`**, **Port N = 6** ⇒ **`0x6301`**) define two independent enables; each adds **at least ~1.5 ns** to the indicated clock when set to **1**:

| Bit | Name (datasheet) | Clock (§4.11.4 wording) | **Power‑up default** | **Internal delay at default** |
|-----|------------------|-------------------------|----------------------|-------------------------------|
| **4** | **RGMII_ID_ig** (“ingress”) | **TX_CLK6** (from FEC toward KSZ TX datapath) | **R/W default `0`** | **Disabled** — **no** added delay on **TX_CLK6** |
| **3** | **RGMII_ID_eg** (“egress”) | **RX_CLK6** (from KSZ toward FEC RX datapath) | **R/W default `1`** | **Enabled** — **≥ ~1.5 ns** delay on **RX_CLK6** |

**Answer for bring-up:** **Yes — one of the two internal delays is on by default:** **RX_CLK6** delay (**RGMII_ID_eg**) is **enabled**; **TX_CLK6** delay (**RGMII_ID_ig**) is **off** by default. That matches §**4.11.4** narrative (**RGMII_ID_ig** default off, **RGMII_ID_eg** default on) and aligns **RGMII v2.0** “ID” style timing on the **receive** clock toward the MAC unless firmware clears bit **3**.

**FEC `phy-mode = "rgmii-id"`:** Linux expects **internal delay on at least one side** of the RGMII so setup/hold meet **RGMII v2.0**. Here the KSZ **defaults** supply delay on **RX_CLK6** only; the **i.MX FEC** may still apply its own **TX/RX ID** per **`rgmii-id`**. If the CPU link is marginal, confirm **bits [4:3]** on **`0x6301`** over **SPI/I²C** (not MIIM) and correlate with scope / **`ethtool -S`** counters.

**Runtime verification (recommended once you have SPI/I²C):** read **`0x6301`** and confirm **bit 4 = 0** (**RGMII_ID_ig** off), **bit 3 = 1** (**RGMII_ID_eg** on) unless software has changed them.

### Register map (Port **N = 6**) — §5.2.3

From **Table 5-2** / **§5.2.3** (Port **RGMII/GMII/MII/RMII** space **`0xN300`–`0xN3FF`**):

| Address (Port 6) | Register |
|------------------|----------|
| **`0x6300`** | **XMII Port Control 0** — duplex, flow control, **10/100** selection when sub-gigabit |
| **`0x6301`** | **XMII Port Control 1** — bit **6** **Port Speed 1000** (strap **`RXD6_0`** loads default); bits **4:3** **RGMII_ID_ig** / **RGMII_ID_eg** (defaults **`0`/`1`** — see table above); bits **[1:0]** **interface type** (**`00` = RGMII**, reflects **RXD6_[3:2]** straps) |

**MIIM vs SPI/I²C:** **§5.0** states the **MIIM** interface accesses **PHY registers only** and **does not** access **switch** (including **XMII**) registers. Reading **`0x6300`/`0x6301`** for lab bring-up requires **SPI** or **I²C** management (or **IBA**), not **FEC MDIO** alone — consistent with **`docs/DT510-KSZ9896-MIIM-register-dump.md`**.

### FAQ — can **`0x6301[4:3]`** (internal RGMII delay) be set via **MIIM**?

**No — not per DS00002390C.** §**5.0** states **MIIM reaches PHY registers only**; **`0x6301`** lives in **Port 6 switch register space** (**§5.2.3**, **`0x6300`–`0x63FF`**), which **MIIM does not decode**. There is **no** documented **MDIO** path to read or write **`0x6301`** on KSZ9896C.

**What you can do instead:**

| Approach | Effect on **`RGMII_ID_ig` / `_eg`** |
|----------|-------------------------------------|
| **SPI or I²C** management (strap **LED4_1 / LED3_1** to enable those buses; board must route pins) | **Full read/write** of **`0x6301`** and rest of switch map |
| **In-band management (IBA)** — if strap-enabled per §3.2.1 | **Same** register access model as SPI/I²C (datasheet), subject to IBA setup |
| **`&fec1` `phy-mode`** (`rgmii-id`, `rgmii-rxid`, `rgmii-txid`, `rgmii`) | Adjusts **i.MX FEC RGMII delay / pad skew**, **not** KSZ **`0x6301`** — use for timing when **KSZ register access** is unavailable |
| **Hardware strap / PCB** only | Does **not** change **`0x6301`** bits directly; defaults remain **§5.2.3.2** unless overridden by **SPI/I²C/IBA** |

So on **DT510’s MIIM-only strap**, **you cannot program internal KSZ delays through FEC MDIO**; tune **MAC-side** **`phy-mode`** / pinctrl or add **SPI/I²C** (or use **IBA**) if you must flip **`0x6301`**.

### i.MX **`&fec1`** — RGMII timing options (device tree)

These apply to the **FEC MAC** toward **Port 6** on the KSZ (**`fixed-link`** still uses **`phy-mode`** so **phylink** / **`fec`** configure **RGMII pad timing** correctly).

#### **`phy-mode`** (main knob)

Normative enum matches **`phy-connection-type`** in Linux **`Documentation/devicetree/bindings/net/ethernet-controller.yaml`**:

| `phy-mode` | Intended PCB / delay split (informative text from kernel docs) |
|------------|------------------------------------------------------------------|
| **`rgmii`** | **PCB** adds ~**2 ns** skew (clock vs data) on **both** RX and TX — **not** typical unless traces are length-matched for delay. |
| **`rgmii-id`** | **PCB does not** add that skew — **internal delay** in **MAC and/or link partner** (**“ID”**). Most boards without engineered trace delay use this. **DT510 uses this today.** |
| **`rgmii-rxid`** | **PCB** adds skew on **TX** only; **RX** delay comes from **internal** logic (PHY/MAC as negotiated by driver). |
| **`rgmii-txid`** | **PCB** adds skew on **RX** only; **TX** delay internal. |

Swapping modes changes how **Linux** expects **FEC** vs **KSZ** to split **RGMII v2.0** timing — tune **only with measurement** (scope / eye) because wrong choice yields **intermittent CRC / no link**.

#### **`rx-internal-delay-ps` / `tx-internal-delay-ps`** (optional fine tuning)

The same **ethernet-controller.yaml** binding allows **`rx-internal-delay-ps`** and **`tx-internal-delay-ps`** on the **Ethernet MAC** node when **`phy-mode`** is one of **`rgmii`**, **`rgmii-id`**, **`rgmii-rxid`**, **`rgmii-txid`** — values are **picoseconds** for MACs that implement **programmable** internal delay.

Whether **i.MX 8MM FEC** actually honours these properties depends on the **`fec`** driver / silicon for your kernel — many designs rely on **`phy-mode`** + **partner** (here, **KSZ `0x6301`**) instead. If your tree’s **`fec`** ignores them, changing **`phy-mode`** remains the practical DT knob.

#### **Pinctrl (`fsl,pins` PAD values)**

Not a substitute for **`phy-mode`**, but **drive strength / slew** (**e.g.** **`0x116`**, **`0x1916`** on **`pinctrl_fec1_dt510`**) affect **SI margins** at **125 MHz** RGMII — keep aligned with **Ollie** / board SSOT when chasing marginal timing.

### EE goal — **~1.5–2 ns** RGMII clock/data skew (how to satisfy it)

**RGMII** expects roughly **2 ns** skew between clock and data lines (see **`ethernet-controller.yaml`** informative text). On KSZ9896C, §**4.11.4** / §**5.2.3.2** implement this as **≥ ~1.5 ns minimum** per enabled internal-delay bit (**not** a continuous trim to exactly 2 ns).

**What we already have (defaults):**

| Location | Mechanism | Typical effect |
|----------|-----------|----------------|
| **KSZ Port 6** | **`0x6301` bit 3** (**`RGMII_ID_eg`**) **= 1** default | **≥ ~1.5 ns** on **RX_CLK6** (KSZ → FEC **receive** path) |
| **KSZ Port 6** | **`0x6301` bit 4** (**`RGMII_ID_ig`**) **= 0** default | **No** extra delay on **TX_CLK6** at reset |
| **i.MX FEC** | **`phy-mode = "rgmii-id"`** | MAC stack expects **internal delay** on at least one side — aligns **software** model with **no PCB-length skew** |

So **receive direction toward the MAC** already has a **datasheet internal delay**; **transmit direction** (FEC → KSZ) relies on **FEC `rgmii-id`** behaviour ± PCB unless **`RGMII_ID_ig`** is turned **on**.

**If Michael’s review says “add delay” (marginal scope / CRC):**

1. **Confirm on silicon:** read **`0x6301`** (**SPI/I²C**, Port **6** = **`0x6301`**). Expect **bit 3 = 1**, **bit 4 = 0** unless something changed them.
2. **KSZ — enable TX-path internal delay:** set **`0x6301` bit 4 = 1** (**`RGMII_ID_ig`**) via **SPI/I²C** (read-modify-write), power/strap unchanged. Adds **≥ ~1.5 ns** on **TX_CLK6** toward the KSZ **receive** (FEC→KSZ direction).
3. **FEC — swap `phy-mode` experimentally** (with scope): try **`rgmii-txid`** / **`rgmii-rxid`** / **`rgmii-id`** only **one step at a time** so **MAC vs KSZ** don’t both cancel delays — measure **RX and TX** separately at the connector.
4. **FEC — DT delay properties:** The generic **`fsl,fec`** binding allows **`tx-internal-delay-ps`** / **`rx-internal-delay-ps`** on some SoCs, but the **i.MX 8M Mini reference manual** documents the corresponding **ENET_ECR** delay-related bits as **reserved / not supported** for programmable MAC-side RGMII delay on this silicon — **DT510 does not** use those DT properties; rely on **`phy-mode`**, **KSZ Port 6 `0x6301`** (SPI/I²C when available), **PCB**, or **straps** for skew instead.
5. **MIIM-only hardware:** cannot write **`0x6301`** **from FEC MDIO** — either **board rework / strap** for **I²C/SPI** to the KSZ or tune **`phy-mode`** / **FEC-only** properties until management exists.

**Verification:** scope **TXC/TD*** and **RXC/RD*** vs **CTL** at the balls; **`ethtool -S`** error counters; fewer **CRC** / silent drops on **`end0`**.

## EVK vs DT510 `&fec1` (same SoC, different link)

| | **i.MX8MM EVK** (`imx8mm-evk.dtsi`) | **DT510** |
|---|-------------------------------------|-----------|
| **Topology** | FEC → **one external RGMII PHY** (e.g. QCA) on MDIO | FEC → **RGMII to KSZ** **CPU** port (MAC–MAC path for link purposes) |
| **`phy-mode`** | `rgmii-id` (matches **that** PHY) | `rgmii-id` (same *name*; must match **KSZ + board** delay, not “because EVK”) |
| **`phy-handle` / link partner** | **`phy-handle = <&ethphy0>`** + **`fixed-link` absent** | **`/delete-property/ phy-handle`** (from EVK include); **only** `fixed-link` 1G full for **CPU** port |
| **`fsl,magic-packet`**| **enabled** (PHY feature) | **deleted** (not applicable to this path) |
| **MDIO children** | **`ethernet-phy@0`** + reset, supplies | **`ethernet-phy@1`…`@5`** (internal PHY **probe**); **not** **phy@0** and **not** a replacement for `fixed-link` on the **CPU** port |
| **Pinctrl** | **`pinctrl_fec1`** (NXP pad values + **SAI2_RXC→GPIO4_IO22** for EVK) | **`pinctrl_fec1_dt510`** — **Ollie** **0x116** / **TX_CTL 0x1916**; **no** SAI2→GPIO4_IO22 in this group (DT510 ZB) |

**NXP mainline (browse):** [imx8mm-evk.dtsi `&fec1`](https://raw.githubusercontent.com/torvalds/linux/master/arch/arm64/boot/dts/freescale/imx8mm-evk.dtsi) — search for `&fec1` and `pinctrl_fec1`.

**FAQ — can we use the EVK `&fec1` setup on DT510?** **Not verbatim.** The EVK ties the MAC to **one** external **PHY@0** via **`phy-handle`**, **no** `fixed-link`, **`fsl,magic-packet`**, and **`pinctrl_fec1`**. DT510 ties the MAC to the **KSZ CPU** port (**`fixed-link`**), lists **internal** PHYs at **1…5** for **probe** only, keeps **`phy-handle` deleted**, and uses **`pinctrl_fec1_dt510`**. Copying the EVK block **as-is** would be the wrong link model and **wrong** pins.

**Implications:** there is **no** `lan1`… DSA user ports from `ksz9477` until one of: hardware adds **I2C** (strap **01**) to a SoC I2C master and the node returns; **SPI** strap + SPI DT; a **downstream/OO** driver that bit-bangs or speaks switch management over the supplied MDIO; or **NXP/Microchip**-specific integration beyond this doc.

## Simple bring-up (analysis) — *unmanaged + one CPU IP + no per-port control*

This is the suggested **phase 1** pattern for **hardware prove-out** before a more complex control plane (see *Phased plan* above).

| Idea | On DT510 today | Notes |
|------|----------------|--------|
| **`&fec1` + `fixed-link` (1 G, full) + no `phy-handle`** | **Yes** | Correct model for **MAC (FEC) → RGMII → KSZ CPU port** — there is **no** Clause-22 **PHY in front of** the MAC on that link. The switch port is not “discovered” like an AR8031; **L1 to the rest of the world** is **implicit** in the **switch fabric** + cable PHYs, not a second Linux link on `&fec1`. |
| **`mdio` + phy children** | EVK: **one** child **@0** + **`phy-handle`** | DT510: **five** children **@1…@5** for **KSZ** internal PHYs; **`phy-handle` absent** (CPU RGMII = **`fixed-link`**) |
| **EVK `pinctrl` if RGMII pinout matches** | **Not using EVK FEC** | DT510 **ENET1** is **`pinctrl_fec1_dt510`**, matching **Ollie’s** `pin_mux` / **board** routing — **not** `imx8mm-evk` RGMII. **Only** reuse **EVK** FEC pinctrl if a **schematic/SSOT diff** shows **the same** ball-level ENET1 layout as the EVK; otherwise **SSOT wins** (as in the canonical DTS). |
| **`phy-mode`** | **`rgmii-id`** in tree | Chosen for **RGMII delay** context (KSZ + layout). It is **not** guaranteed identical to the **EVK** (external PHY) choice — tune with **measure** / datasheet if the CPU link misbehaves. |
| **“Unmanaged”** | Straps / default switching | The KSZ can **bridge** with **default** **VID** and forwarding **without** Linux talking **switch** registers. **Phase 1** does **not** add I²C DSA. |

**Summary:** **`&fec1`** is **minimal** for the **CPU** link (`fixed-link` + Ollie pinctrl). **EVK pinctrl** is **not** copied — **SSOT** ENET1 only. **Future:** optional **I²C+DSA** or `mdio` phy children for debug (see *Phased plan*).

**Sideband GPIOs (PME# / INTR# / RST#):** same physical balls as SAI1/TAS6424 pinctrl in current DT — see previous notes; `reset-gpios` for the switch not wired without an EE/SAI1 trade-off.

## Build → flash → test (short)

1. Pin BSP / manifest per `conf/DT510-HARDWARE-BRINGUP.md`.  
2. Build **`imx8mm-jaguar-dt510`**.  
3. On device: `dmesg | grep -iE 'fec|mdio|phy'`, `ip link` — expect a single **FEC**-backed link (e.g. `end0` / `eth0`), not DSA `lan*`.  
4. **MDIO:** `ls /sys/bus/mdio/devices` — expect **PHY @1…@5** if the internal PHYs respond; **`phy-handle` is not** used for the **CPU** RGMII path (`fixed-link`). `i2cdetect` will **not** show the switch at I²C `0x5F` (expected).  
5. RGMII timing: if the CPU link is wrong, tune `phy-mode` / delays (see NXP + KSZ threads). Port links are separate from CPU `fixed-link`.

## PHY diagnostics on-target (`mdio` vs `phytool`)

Use this when validating **internal PHY @1…@5** on the KSZ (Clause 22 over the FEC MDIO bus). **Switch MIB / per-port bridge counters** are **not** covered here — see Microchip DS00002390 (MIB sections); **`end0`** does not attribute RX to a front-panel port without DSA or switch register tools.

### Why `phytool` often fails on DT510

- **`phytool read end0/N/R`** uses MII ioctl calls through the **`end0`** netdev.
- On this stack, **`phytool`** typically returns **`phy_read (-1)`** for PHY addresses **1–5** — the **FEC** driver path does not expose **per-address MII** access that **`phytool`** expects through **`end0`**.
- **`phytool -h`** / **`--help`** is parsed as a bad **location** on some builds; run **`phytool`** with **no** arguments for usage.

**Use `mdio` from `mdio-tools`** instead (needs **`sudo`** for **`mdio_netlink`**).

### Find the MDIO bus name

```bash
sudo mdio
```

Example line on DT510: **`30be0000.ethernet-1`** (FEC MDIO controller).

### Probe all Clause 22 devices on the bus

Table of **PHY-ID** and **LINK** column (quick health check):

```bash
sudo mdio 30be0000.ethernet-1
```

Address **0x00** is the internal device used for the **CPU/RGMII** side in this topology; **0x01–0x05** are the **copper PHY** ports.

### Decode BMCR / BMSR / PHY ID (same info as `phytool print` would show)

Per PHY address **`N`** in **`1…5`**:

```bash
sudo mdio 30be0000.ethernet-1 phy N
```

This prints **BMCR (0x00)**, **BMSR (0x01)**, **ID (0x02/0x03)**, **ESTATUS (0x0F)**, etc., with flags such as **+link**, **+aneg-complete**, negotiated speed.

Re-run while plugging cables to see **link** change on the matching **PHY @N**.

**Note:** This image’s **`mdio`** expects **`sudo mdio BUS phy N`** for a status dump — not **`mdio … read`** with the word **`read`** in the position that older examples use; use **`mdio --help`** on the target if in doubt.

### What you cannot get from Clause 22 alone

- **Which RJ45** forwarded a given packet seen on **`end0`** — all CPU traffic arrives on one **RGMII** pipe; use **controlled cabling**, **MIB** (datasheet), or future **DSA** for per-port visibility.
- **`/sys/bus/mdio/devices`** may be **empty** or absent on some configurations even when **`sudo mdio …`** works — trust the **`mdio`** tool if the probe succeeds.

### Related

- Dev image PHY/debug packages: `meta-dynamicdevices-distro` **`lmp-feature-dev.inc`** (**`phytool`**, **`mdio-tools`** when dev features are enabled).
- GPIO sideband (**RST/PME/INTR**): `docs/GPIO-HOG-ACTIVE-POLARITY.md`.

## Silicon errata (**DS80000757**) — relevance to DT510

Official PDF: **KSZ9896C Silicon Errata and Data Sheet Clarification** (**DS80000757**, e.g. revision **F**). Applies to **silicon A1** (top mark **B000** per Table 1 — confirm on your parts).

### Port 6 (RGMII / CPU link)

**No erratum in DS80000757** targets **Port 6 RGMII**, **XMII (`0x6300`–`0x63FF`)**, or **internal delay (`0x6301`)**. Timing bring-up remains **datasheet + scope + `phy-mode`** as elsewhere in this doc.

### Integrated copper PHY ports **1–5** (likely relevant)

Errata **explicitly allow applying PHY workarounds via `MDC/MDIO`** (same list as I²C/SPI/IBA for PHY-side sequences):

| Module | Topic | Why it might matter |
|--------|--------|---------------------|
| **1** | PHY **MMD** tuning for **RX performance** | RX errors on **long cables** if defaults left untouched |
| **2** | **MMD** TX waveform | Corner-case TX compliance |
| **3** | **EEE must be disabled** (MMD **7**, reg **0x3C** → **`0x0000`**) | **Link drops** when peer negotiates **EEE** — **high diagnostic value** if links flap with modern NICs |
| **4** | Toggling **PHY power-down** disturbs **other PHYs** | Avoid PD cycling one port while others carry traffic |
| **6** | Extra **MMD** writes for **supply current** vs datasheet | Thermal / AVDDH behaviour outside **1000BASE-T** |

**Important note** at the start of the errata: before **MMD** programming sequences, force **100 Mbps**, **AN off** (`0xN100`–`0xN101` = **`0x2100`** pattern per errata), then restore **AN** (**`0x1340`**) after all PHY-related writes — follow Microchip’s exact recipe when implementing **MMD** workarounds.

**Module 5** (**16-bit vs 32-bit PHY writes** for **`0xN120`–`0xN13F`**) applies to **SPI / I²C / IBA** access patterns; **Clause 22 MIIM** traffic may not hit the same bug — still follow errata if your tooling does wide writes through switch management.

### Switch-global registers — **not via MIIM**

Several modules require **global** registers (**e.g.** **`0x0330`**, **`0x0331`**) with text **“SPI, I2C, or in-band … **but not via the MIIM interface**”** — consistent with **§5.0** (MIIM = PHY space only). Examples: **Module 10** (back-pressure mode), **Module 11** (alternate backoff). Irrelevant unless you enable those **half-duplex** / advanced paths.

### Half-duplex / VLAN / tail-tag (usually **not** DT510 phase 1)

**Modules 10–11, 13, 16–17**: failure modes around **half-duplex**, **VLAN**, **tail tag**, **length check**. DT510 **CPU + RJ45** paths are normally **full-duplex** **1000BASE-T** / **RGMII** — low priority unless you deliberately configure HD/VLAN features.

### SPI-only

**Module 7**: automatic SPI clock-edge selection unstable near **25 MHz** — only if you move to **SPI** strap later.

---

## References

- `docs/DT510-KSZ9896-MIIM-register-dump.md` — Clause **22** **`mdio phy @0–@5 raw 0–31`** snapshot for EE review.
- `Documentation/devicetree/bindings/net/dsa/microchip,ksz.yaml`
- `linux/drivers/net/dsa/microchip/ksz9477_i2c.c` (I2C regmap; **not** used when HW is MIIM-only)
- Microchip **KSZ9896C** DS00002390C — **§3.2.1** straps (Table 3-3), **§4.11.4** RGMII (Port 6), **§5.0** / **§5.2.3** registers (**XMII** **`0x6300`**–**`0x63FF`**)
- Microchip **KSZ9896C** **DS80000757** — silicon errata (**§ Silicon errata** above); PHY **MMD** workarounds apply per module tables in PDF
- Linux **`Documentation/devicetree/bindings/net/ethernet-controller.yaml`** — **`phy-mode`** / **`phy-connection-type`** (**RGMII** variants), optional **`rx-internal-delay-ps`** / **`tx-internal-delay-ps`**
- `docs/DT510-BSP-PROJECT-PLAN.md` — Tier **C1** Ethernet
