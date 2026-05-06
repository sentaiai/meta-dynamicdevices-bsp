# DT510 — KSZ9896 MIIM Clause 22 register dump (review)

**Purpose:** Snapshot of **standard MIIM registers (0–31)** on FEC MDIO bus **`30be0000.ethernet-1`** for PHY addresses **@0–@5**, for hardware/software review (e.g. with EE).

**Device:** `imx8mm-jaguar-dt510` — captured remotely via SSH (`mdio` from **mdio-tools**).

**Datasheet:** Microchip **KSZ9896C** DS00002390C — **§4.9.3 MIIM**, **Table 4‑27** (standard MIIM register map to internal **Port N** PHY space).

---

## How this was captured

```bash
BUS=30be0000.ethernet-1
sudo mdio "$BUS"                                    # probe
for p in 0 1 2 3 4 5; do
  for r in $(seq 0 31); do
    sudo mdio "$BUS" phy $p raw $r
  done
done
```

Register numbers **0–31** are **decimal** in the `mdio` CLI (= **0h–1Fh** in Table 4‑27). Values are **16‑bit hex** as printed by `mdio`.

**Not included here:** Clause **45** `mmd PRTAD:DEVAD raw …` (requires addresses from **§5.4**); switch global / **Port 6 RGMII** CSRs (**§5.2.3**, e.g. **0x6300** range) — those are **outside** Clause 22 `phy raw 0–31`.

---

## MDIO probe (same capture session)

| DEV   | PHY-ID     | LINK |
|-------|------------|------|
| 0x00  | 0x004540fe | down |
| 0x01  | 0x00221631 | up   |
| 0x02  | 0x00221631 | up   |
| 0x03  | 0x00221631 | down |
| 0x04  | 0x00221631 | down |
| 0x05  | 0x00221631 | down |

---

## PHY @0 — Clause 22 regs 0–31

### What **PRTAD 0** is on KSZ9896 **MIIM** (decode this first)

Strapping **LED4_1 / LED3_1 = 0 / 0** selects **MII Management (MIIM)** on **MDC/MDIO**. Microchip documents three facts that matter for **`mdio phy 0`**:

1. **MIIM reaches PHY registers only — not xMII, not switch globals.** The **KSZ989x hardware design checklist** (doc **00004151**, §**7.0**–§**7.4**) states that **SPI / I²C / IBA** can access **all** device registers, whereas **MIIM** can access **only PHY registers** — **not** switch‑global registers and **not** **xMII (MAC Port 6 / Port 7)** control registers (same section explains why MIIM is **least preferred** for bring‑up). So **PRTAD 0** Clause **22** access **does not** substitute **XMII / RGMII pad control** (e.g. delay **`0x3301`**‑class) or **switch** CSRs — those remain **I²C/SPI** (or IBA) paths per datasheet.

2. **`phy 0` ≠ `phy 1…5` by silicon.** On DT510, **PRTAD 1–5** report **PHY Identifier `0x00221631`** — the **integrated copper PHY** used on **RJ45 ports** (**datasheet PHY Ports 1–5**). **PRTAD 0** reports **`0x004540fe`**. That ID is **not** the copper‑PHY core; it is the **Microchip KSZ switch‑family PHY/Management identity** exposed at **STA 0**. In **DS00002390C**, **§4.9.3** / **Table 4‑27** maps **MIIM PHY addresses** to **internal Port N PHY register spaces** — confirm there which **Port** corresponds to **PRTAD 0** (hardware‑specific strap/board docs typically align **STA 0** with the **host / MAC Port 6** side, **not** an RJ45 PHY).

3. **Register row decode.** Registers **0–31** at **@0** still use **IEEE‑shaped** addresses, but **BMCR/BMSR/AN** fields **must** be interpreted from **Microchip’s descriptions for that PRTAD**, **not** by copying **@1** copper meanings. Values such as **BMCR `0x9200`** / **BMSR `0x0202`** indicate **this block’s** reset/control/link‑status model (`mdio` **LINK down** is consistent) — **not** “broken RJ45 PHY” behaviour.

**Bottom line for EE/SW:** Treat **PHY @0** as the **MIIM-accessible management PHY** **associated with the switch’s non–RJ45 host port path** (datasheet **MAC Port 6** context), with **PHY-ID `0x004540fe`**. Decode every register against **DS00002390C Table 4‑27 / §4.11** for **that** STA — **parallel** to copper **@1–@5**, **not interchangeable** with them.

| Reg | hex | Value | Analysis |
|-----|-----|-------|----------|
| 0 | 0x00 | 0x9200 | **BMCR:** Does **not** match idle copper patterns (**0x1140** family). Likely **vendor-specific control/staging** for this STA — **do not** decode as standard PHY BMCR without **DS** mapping. |
| 1 | 0x01 | 0x0202 | **BMSR:** Unlike **@1–@5** linked (**~0x796d**) or down (**~0x7949**); fits **probe LINK down** and **non–copper-PHY** behaviour for this object. |
| 2 | 0x02 | 0x0045 | **PHY ID [31:16]** — part of **0x004540fe**; confirms **different silicon/block** than **@1–@5**. |
| 3 | 0x03 | 0x40fe | **PHY ID [15:0]** — completes **OUI/model/rev** identity distinct from **0x00221631**. |
| 4 | 0x04 | 0x0000 | **AN advertisement:** Zero — **no** copper-style capability advertisement active in this snapshot (or not applicable to this STA). |
| 5 | 0x05 | 0x0000 | **AN link-partner ability:** Zero — **no** partner exchange (consistent with **down** / non-RJ45 context). |
| 6 | 0x06 | 0x0062 | **AN expansion:** Non-zero — interpret **only** via **DS** bitfields for **@0** (may still reflect IEEE-shaped registers with different meaning). |
| 7 | 0x07 | 0x3000 | **AN next page TX** (IEEE-shaped): Non-zero — **next-page machinery** may be active or latched; confirm in **DS** if relevant. |
| 8–21 | 0x08–0x15 | 0x0000 | **Regs 8–15** IEEE extended / **16–21** vendor begin — **all zero**: idle / reserved for this STA at capture. |
| 22 | 0x16 | 0x0318 | Non-zero **vendor / extended** — meaning **DS-only** (not generic IEEE decode). |
| 23–31 | 0x17–0x1f | 0x0000 | **Vendor window** mostly zero — no sticky vendor flags visible here at capture (see **§ Comprehensive analysis** for **17h/1Ch** when non-zero on copper). |

---

## PHY @1 — Clause 22 regs 0–31 (LINK **up**)

| Reg | hex | Value | Analysis |
|-----|-----|-------|----------|
| 0 | 0x00 | 0x1140 | **BMCR:** **AN enabled** + typical **Gb copper** control word (**0x1140** family); not reset / isolate / power-down in usual patterns. |
| 1 | 0x01 | 0x796d | **BMSR:** **Link up**, **AN capable/complete**, **extended status** present — aligns with **probe LINK up**. |
| 2 | 0x02 | 0x0022 | **PHY ID** high — **0x00221631** identity (Microchip / Kendin-class integrated PHY). |
| 3 | 0x03 | 0x1631 | **PHY ID** low — matches **@2–@5** family. |
| 4 | 0x04 | 0x0de1 | **AN advertisement:** Full **tech ability** field (1000/100/10 etc. per IEEE bit map) — active **advertising**. |
| 5 | 0x05 | 0xcde1 | **AN LP ability:** Non-zero — **real link partner** completed AN (**CDE1** partner code vs **@2**). |
| 6 | 0x06 | 0x000f | **AN expansion:** **Next-page** able + flags per IEEE — consistent with **completed AN**. |
| 7 | 0x07 | 0x2001 | **Next page TX:** **NP** ready / compliant exchange path (idle payload vs **@3** same register shape). |
| 8 | 0x08 | 0x6801 | **Next page RX:** Non-zero — partner **next-page** field seen (**differs from @2** **0x6001** — partner-dependent). |
| 9 | 0x09 | 0x0700 | **1000BASE-T control:** **TEST_MODE / master-slave** area per Clause **40** — typical **gig** negotiation staging (**0x0700** pattern). |
| 10 | 0x0a | 0x7800 | **1000BASE-T status:** Non-zero — **master/slave resolution / idle** indicators active (**link up** path). |
| 11 | 0x0b | 0x0000 | Reserved / unused in readback. |
| 12 | 0x0c | 0x0000 | Reserved / unused. |
| 13 | 0x0d | 0x4007 | **MMD indirect (DEVAD):** Part of **MMD access** framing — snapshot of address machinery, not an “intent” by itself. |
| 14 | 0x0e | 0x0006 | **MMD indirect (data/reg):** Companion to **reg 13** for Clause **45**-style access path. |
| 15 | 0x0f | 0x3000 | **Extended status (ESTATUS):** **1000BASE-T** capability bits present per IEEE (**0x3000** pattern in dump family). |
| 16 | 0x10 | 0x0000 | Reserved / vendor stub reads **0**. |
| 17 | 0x11 | 0x00f4 | **Vendor 11h — remote loopback:** Non-zero — verify **loopback disabled** for normal forwarding (**DS** bits). |
| 18 | 0x12 | 0x0000 | **Vendor 12h — LinkMD:** Idle (**no** cable test running). |
| 19 | 0x13 | 0x0406 | **Vendor 13h — PMA/PCS:** Status (**sync/lock/fault** class — **DS** decode). |
| 20 | 0x14 | 0x5cfe | **Vendor 14h:** Extension block — **DS-only** bitfields. |
| 21 | 0x15 | 0x0000 | **Vendor 15h — RXER:** **Zero** — no accumulated RX error count at snapshot (confirm under traffic). |
| 22 | 0x16 | 0x0000 | Vendor / reserved. |
| 23 | 0x17 | 0x0200 | **Vendor 17h:** Non-zero staging (**DS** — **not** **1Bh** interrupt register). |
| 24–27 | 0x18–0x1b | 0x0000 | Includes **1Bh** IRQ — **all clear** at capture. |
| 28 | 0x1c | 0x2400 | **Vendor 1Ch — Auto MDI-X:** Non-zero — **crossover** logic active/configured. |
| 29–30 | 0x1d–0x1e | 0x0000 | Vendor reserved. |
| 31 | 0x1f | 0x014c | **Vendor 1Fh — PHY control:** **Linked** pattern (**differs** from **down** ports **0x0100**). |

---

## PHY @2 — Clause 22 regs 0–31 (LINK **up**)

Same as **@1** except:

| Reg | Value @1 | Value @2 | Analysis |
|-----|----------|----------|----------|
| 5 | 0xcde1 | **0xc1e1** | **AN link-partner ability** differs only in **technology ability bits** — **different peer** (NIC/switch) advertised **slightly different** capability mask; **both** prove **non-zero partner** and **completed AN**. |
| 8 | 0x6801 | **0x6001** | **ANNPRR** (next-page receive): Lower bits differ with **partner** — normal **partner-specific** variation; **both** non-zero ⇒ **next-page path** saw data. |

All other registers **0–31** matched **@1** at capture time (same interpretations as **PHY @1** table).

---

## PHY @3 — Clause 22 regs 0–31 (LINK **down**)

| Reg | hex | Value | Analysis |
|-----|-----|-------|----------|
| 0 | 0x00 | 0x1140 | **BMCR:** Same **AN-enabled** baseline as **@1** (**idle jack** still programmed to advertise). |
| 1 | 0x01 | 0x7949 | **BMSR:** **Link down** pattern (**0x7949** vs **0x796d**) — **no** established link / partner. |
| 2 | 0x02 | 0x0022 | **PHY ID** — same **0x00221631** as other copper ports. |
| 3 | 0x03 | 0x1631 | **PHY ID** low — matches **@1**. |
| 4 | 0x04 | 0x0de1 | **AN advertisement:** Still **0x0de1** (local advertise active) even with **no cable**. |
| 5 | 0x05 | 0x0000 | **AN LP ability:** **Zero** — **no** partner **seen** (open port / no far-end PHY). |
| 6 | 0x06 | 0x0004 | **AN expansion:** Typical **idle/down** expansion flags (**0x0004** vs **0x000f** when linked). |
| 7 | 0x07 | 0x2001 | **Next page TX:** Present but **no** partner exchange — consistent **idle** staging. |
| 8 | 0x08 | 0x0000 | **ANNPRR:** Zero — **no** partner **next-page** field (**contrast @1**). |
| 9 | 0x09 | 0x0700 | **1000BASE-T control:** Same control word class as **@1** — **gig** control path idle until partner. |
| 10 | 0x0a | 0x0000 | **1000BASE-T status:** **Zero** — **no** gig resolution (**no link**). |
| 11 | 0x0b | 0x0000 | Reserved. |
| 12 | 0x0c | 0x0000 | Reserved. |
| 13 | 0x0d | 0x4007 | **MMD DEVAD** snapshot — same machinery pattern as **@1**. |
| 14 | 0x0e | 0x0006 | **MMD data** companion to **reg 13**. |
| 15 | 0x0f | 0x3000 | **ESTATUS** — still reports **capability** bits (**link state** is in **BMSR**, not here). |
| 16 | 0x10 | 0x0000 | Reserved. |
| 17 | 0x11 | 0x00f4 | **Remote loopback** vendor — same read as **@1** (configuration, not link state). |
| 18 | 0x12 | 0x0000 | **LinkMD** idle. |
| 19–22 | 0x13–0x16 | 0x0000 | **PMA/PCS + vendor 14–16** — **zeroed** vs **@1** (idle PHY depth / power state). |
| 23 | 0x17 | 0x0200 | **Vendor 17h** staging — non-zero base pattern. |
| 24–27 | 0x18–0x1b | 0x0000 | **IRQ (1Bh)** clear. |
| 28 | 0x1c | 0x2400 | **Auto MDI-X** — same class as **@1** (PHY still configured). |
| 29–30 | 0x1d–0x1e | 0x0000 | Reserved. |
| 31 | 0x1f | 0x0100 | **PHY control:** **Down/unlinked** pattern (**vs 0x014c** on **@1**). |

---

## PHY @4 — Clause 22 regs 0–31 (LINK **down**)

Notable: **BMCR (reg 0) = 0x1100** vs **0x1140** on other ports; **reg 4** auto-neg advertisement differs.

| Reg | hex | Value | Analysis |
|-----|-----|-------|----------|
| 0 | 0x00 | **0x1100** | **BMCR:** **Differs from 0x1140** by PHY-specific selector/speed bits (**bit 6** region); tools may decode oddly — **do not** assume **10 M** on wire without **regs 4–10** + cable test. **Flag for EE:** strap / mode / jack wiring vs **@3/@5**. |
| 1 | 0x01 | 0x7949 | **BMSR:** **Down** — same family as **@3** (**no link**). |
| 2 | 0x02 | 0x0022 | **PHY ID** — same silicon as **@1–@5**. |
| 3 | 0x03 | 0x1631 | **PHY ID** low — matches others. |
| 4 | 0x04 | **0x0c01** | **AN advertisement:** **Differs** from **0x0de1** (**@1/@3/@5**) — **fewer/different tech abilities** advertised locally — **consistent with BMCR anomaly**; verify intended **programming**. |
| 5 | 0x05 | 0x0000 | **AN LP:** No partner (**open** / no negotiation complete). |
| 6 | 0x06 | 0x0004 | **AN expansion:** Same **idle** class as **@3**. |
| 7 | 0x07 | 0x2001 | **Next page TX** — idle staging. |
| 8 | 0x08 | 0x0000 | **ANNPRR:** No partner. |
| 9 | 0x09 | **0x0400** | **1000BASE-T control:** **Differs** from **0x0700** on **@1/@3/@5** — **gig control path** not aligned with others — **correlate** with **BMCR + reg 4**. |
| 10 | 0x0a | 0x0000 | **1000BASE-T status:** Zero (**no link**). |
| 11–19 | 0x0b–0x13 | mostly **0** | Idle / collapsed vendor reads (**through reg 19**). |
| 20 | 0x14 | **0x1000** | **Vendor 14h:** **Non-zero pattern differs** from **@1** **0x5cfe** — suggests **different internal staging** on this port (**DS** decode). |
| 21–22 | 0x15–0x16 | **0** | RXER path zeroed. |
| 23 | 0x17 | 0x0200 | Same **17h** family as other ports. |
| 24–27 | 0x18–0x1b | **0** | **IRQ** clear. |
| 28 | 0x1c | 0x2400 | **Auto MDI-X** — same **0x2400** as **@3**. |
| 29–30 | 0x1d–0x1e | **0** | Reserved. |
| 31 | 0x1f | 0x0100 | **PHY control:** **Down** pattern (matches **@3**). |

---

## PHY @5 — Clause 22 regs 0–31 (LINK **down**)

| Reg | hex | Value | Analysis |
|-----|-----|-------|----------|
| 0 | 0x00 | **0x1140** | **BMCR:** **Matches @3** (**0x1140**) — **not** the **@4** **0x1100** anomaly; typical **AN-on** idle copper. |
| 1 | 0x01 | 0x7949 | **BMSR:** **Down** — same as **@3/@4**. |
| 2 | 0x02 | 0x0022 | **PHY ID** — **0x00221631** family. |
| 3 | 0x03 | 0x1631 | **PHY ID** low. |
| 4 | 0x04 | **0x0de1** | **AN advertisement:** **Same 0x0de1** as **@1/@3** — **contrast @4** **0x0c01** (this port looks **“normal idle”** vs **@4**). |
| 5 | 0x05 | 0x0000 | **AN LP:** No partner. |
| 6 | 0x06 | 0x0004 | **AN expansion:** Idle/down (**same as @3**). |
| 7 | 0x07 | 0x2001 | **Next page TX** — idle. |
| 8 | 0x08 | 0x0000 | **ANNPRR:** No partner. |
| 9 | 0x09 | **0x0700** | **1000BASE-T control:** **Matches @3** (**0x0700**) — **not** **@4**’s **0x0400**; consistent with **BMCR 0x1140** path. |
| 10 | 0x0a | 0x0000 | **1000BASE-T status:** Zero (**no link**). |
| 11–19 | 0x0b–0x13 | mostly **0** | Same **idle** shape as **@3/@4** collapsed region. |
| 20 | 0x14 | **0x1000** | **Vendor 14h:** Same **0x1000** pattern as **@4** (not **@1** **0x5cfe**) — **down-port** vendor staging family. |
| 21–22 | 0x15–0x16 | **0** | RXER clear. |
| 23 | 0x17 | 0x0200 | **Vendor 17h** — same as **@3/@4**. |
| 24–27 | 0x18–0x1b | **0** | **IRQ** clear. |
| 28 | 0x1c | 0x2400 | **Auto MDI-X** — **0x2400**. |
| 29–30 | 0x1d–0x1e | **0** | Reserved. |
| 31 | 0x1f | 0x0100 | **PHY control:** **Down** pattern. |

---

## Cross-reference — Table 4‑27 (MIIM → meaning)

| MIIM (hex) | Typical name (DS Table 4‑27) |
|------------|------------------------------|
| 0h–Fh | IEEE: BMCR, BMSR, PHY ID, AN, 1000BASE-T control/status, MMD setup/data, extended status |
| 11h | Vendor: PHY remote loopback |
| 12h | Vendor: PHY LinkMD |
| 13h | Vendor: digital PMA/PCS status |
| 15h | Vendor: port RXER count |
| 1Bh | Vendor: port interrupt ctrl/status |
| 1Ch | Vendor: PHY Auto MDI/MDI-X |
| 1Fh | Vendor: PHY control |

Bit-level interpretation requires **DS00002390C** register field tables.

---

## Comprehensive analysis (IEEE + KSZ context)

This section walks **Clause 22** registers **0–31** using **IEEE Std 802.3™** Clause **22** naming for regs **0–15**, plus **Table 4‑27** vendor naming for **16–31**. Exact bit meanings for **vendor** registers **11h–1Fh** are defined only in **Microchip DS00002390C** (± chip revision); use this as a **bring-up guide**, not a substitute for the datasheet **register diagrams**.

### Legend — IEEE registers **0h–Fh**

| Reg (hex) | Name | Role |
|-----------|------|------|
| **0** | **BMCR** | PHY control: reset, loopback, power-down, isolate, **autoneg enable**, duplex/speed selection (exact interpretation depends on PHY type and vendor extensions). |
| **1** | **BMSR** | PHY status: **link**, capabilities, **remote fault**, **autoneg complete**, extended-status capability. |
| **2–3** | **PHY ID** | **PHY Identifier** — combined **`0xWWXX`** / **`0xYYZZ`** form **`OUI + model + revision`** (IEEE registration). |
| **4** | **AN advertisement** | Capabilities this PHY **advertises** during **autonegotiation** (selector + technology ability fields). |
| **5** | **AN LP ability** | Last received **link-partner** advertisement (**zeros** ⇒ no partner seen / no AN exchange). |
| **6** | **AN expansion** | Parallel detection fault flags, **next-page** ability, etc. |
| **7–8** | **AN next page** | Next-page TX/RX (often idle unless multi-gig next pages used). |
| **9** | **1000BASE-T control** | **1000BASE-T** master/slave manual cfg, test modes (IEEE Table **40–** family — confirm bits in **802.3** Clause **40**). |
| **10** | **1000BASE-T status** | Resolution of master/slave, idle/error indications after gigabit AN. |
| **13–14** | **MMD indirect** | Load address (**13**) / read-write data (**14**) for **MMD** access paths (**§5.4** / PHY-specific sequencing). |
| **15** | **Extended status** | Presence/capability bits for **1000BASE-T** half/full (among others). |

### BMCR (**reg 0**) — values observed

| PHYAD | Value | Analysis |
|-------|-------|----------|
| **@1–@3, @5** | **0x1140** | Typical **gigabit PHY with autoneg enabled**: commonly decoded by tools as **1000BASE-T full-duplex intent** with **AN enabled**. Not reset/isolate/power-down in the usual sense (**bits 15/10/11** patterns differ when those are active). |
| **@4** | **0x1100** | **Differs from 0x1140 by PHY-specific speed/select bits** (often **bit 6** / selector combinations). `mdio`’s text decoder previously showed **10 Mbps-class** interpretation for this BMCR pattern — treat as **“this port’s advertised/control path differs”**, not necessarily physical **10 M** on wire until correlated with **regs 4–5–9–10** and **link partner**. **Compare after stable cable** on that jack; resolve against **Table 4‑27** PHY-control chapter. |
| **@0** | **0x9200** | **Not** the same **`0x00221631`** core as copper PHYs. High byte **`0x92`** suggests **different reset/control semantics** (possibly **reset-related bit**, vendor staging). **Do not** apply copper PHY BMCR decoding blindly — only correlate **`@0`** with **§4.11** / CPU-path docs **after** confirming **which** internal block uses MDIO address **0** (that is **still not** “Port 6” by address alone). |

### BMSR (**reg 1**) — **0x796d** (linked) vs **0x7949** (no link)

| Pattern | Typical meaning |
|---------|-----------------|
| **0x796d** (**@1**, **@2**) | Probe **LINK up**. In Clause **22**, commonly indicates **extended capabilities**, **autoneg capable**, **link OK**, **autoneg complete**, **remote fault clear**, **extended status register present** — consistent with **healthy negotiated copper**. |
| **0x7949** (**@3–@5**) | Probe **LINK down**. Same family as above but **without** completed link/autoneg snapshot typical of **idle/disconnected** RJ45 ( **`reg 5` all-zero** reinforces **no partner**). |

**Practice:** always correlate **`mdio` probe LINK column** with **`reg 1`** + **`reg 5`** + **`reg 6`** (expansion).

### PHY identifier (**regs 2–3**)

| PHYAD | regs **2+3** | Analysis |
|-------|--------------|----------|
| **@1–@5** | **0x0022** / **0x1631** → combined **`0x00221631`** | Matches **Microchip / legacy Kendin** PHY identity commonly seen on KSZ integrated PHYs; confirms **same PHY silicon family** across ports **1–5**. |
| **@0** | **0x0045** / **0x40fe** → combined **`0x004540fe`** | **Different** identity — corresponds to **different MDIO-visible block** (often internal **switch CPU / non-RJ45** face per KSZ docs). |

### Autonegotiation (**regs 4–6**) — copper ports

| PHYAD | Reg **4** | Reg **5** | Reg **6** | Analysis |
|-------|-----------|-----------|-----------|----------|
| **@1** | **0x0de1** | **0xcde1** | **0x000f** | **Non-zero partner (`reg 5`)** ⇒ **AN exchange occurred** with link partner; **`reg 6`** expansion shows **next-page capable** paths per IEEE when bits assert — cable/link partner is **real**. |
| **@2** | **0x0de1** | **0xc1e1** | **0x000f** | Same **advertisement** as **@1**; **partner code differs** only in **technology ability bitfield** (`cde1` vs `c1e1`) — normal **partner-dependent** variation (different NIC switch advertisement). |
| **@3–@5** | **0x0de1** or **0x0c01** | **0x0000** | **0x0004** typical | **`reg 5 = 0`** ⇒ **no link partner** reached stable AN — matches **no cable / no far-end PHY**. |
| **@4** | **0x0c01** | **0x0000** | **0x0004** | **Advertisement differs** from **`0x0de1`** pattern — combined with **BMCR 0x1100** ⇒ flag **@4** as **“different programmed advertise path”** vs **@1** until datasheet bits confirmed. |

### 1000BASE-T (**regs 9–10**) — highlights

| PHYAD | Reg **9** | Reg **10** | Analysis |
|-------|-----------|------------|----------|
| **@1**, **@2** | **0x0700** | **0x7800** | Typical **gigabit control/status** pattern when **1000BASE-T** negotiation path active — **`reg 10` non-zero** supports **gig resolution / idle** indicators per Clause **40**. |
| **@3**, **@5** | **0x0700** | **0x0000** | Control word present; **status idle/zero** until partner — consistent **no-link**. |
| **@4** | **0x0400** | **0x0000** | **Differs** from **@1/@2** — aligns with **BMCR/advertisement anomaly** on **@4**; verify **single cable** / **port remap** / **strap**. |

### Extended status (**reg 15**) — **ESTATUS**

All copper PHYs show **`0x3000`** here in this dump — consistent with **extended status pages present** and **1000BASE-T** capability bits (**interpret via IEEE ESTATUS bit definitions**).

### MMD indirect (**regs 13–14**)

Values **`0x4007`** / **`0x0006`** (when seen) reflect **MMD addressing machinery**, not user intent by themselves — **only meaningful after** a defined **write `reg 13` → access `reg 14`** sequence per **PHY/MMD** programming guide.

### Vendor registers (**16–31** / **10h–1Fh**) — Table 4‑27 names

**Index convention:** `mdio phy N raw R` uses **decimal** `R`; **Table 4‑27** uses **hex** MIIM addresses (**11h** = decimal **17**, **1Bh** = decimal **27**, etc.). Several registers read **0** in this capture (**10h**, **16h**, **18h–1Ah**, **1Bh**, **1Dh–1Eh** on **@1**); the table below focuses on **non-zero** or **review-critical** values.

**Do not confuse** IEEE **Clause 22** registers **13–14** (decimal), which implement **MMD indirect** (`0x4007` / `0x0006` in this dump), with **Microchip** MIIM address **13h**, which is **decimal register 19** (**PMA/PCS status**, `0x0406` below).

| MIIM (hex) | Dec. | Value @1 (typ.) | Purpose (DS Table 4‑27 title / note) |
|------------|------|-----------------|--------------------------------------|
| **11h** | 17 | **0x00f4** | PHY **remote loopback** — confirm **normal forwarding** vs test modes (**DS** bitfields). |
| **12h** | 18 | **0x0000** | PHY **LinkMD** — idle unless **cable diagnostic** is running. |
| **13h** | 19 | **0x0406** | Digital **PMA/PCS** status — **sync / lock / fault** class per **Microchip** (**DS**). |
| **14h** | 20 | **0x5cfe** | Vendor extension block — **decode only from DS** (not IEEE). |
| **15h** | 21 | **0x0000** | **Port RXER** / error-count class — **zero** at snapshot (confirm under **traffic**). |
| **17h** | 23 | **0x0200** | Vendor-specific control/status — **not** the same address as **1Bh**; map to **DS** fields for this **MIIM** offset. |
| **1Bh** | 27 | **0x0000** | Port **interrupt** ctrl/status (**Table 4‑27**) — **all-zero** here ⇒ **no sticky IRQ bits** set at capture (if this is the correct port map). |
| **1Ch** | 28 | **0x2400** | PHY **Auto MDI/MDI‑X** — **crossover** handling on copper. |
| **1Fh** | 31 | **0x014c** (linked) / **0x0100** (idle) | PHY **control** — differs **link vs no-link** (expected). |

Ports **@3–@5** zero many vendor-status registers — consistent with **no-link** power/state machines.

### PHY **@0** (special STA)

Full MIIM / **PRTAD 0** meaning is documented under **§ PHY @0 — Clause 22 regs 0–31** above (**PHY-ID `0x004540fe`**, checklist §**7.0**/**7.4**, Table 4‑27 mapping). **Short recap:** **`@0`** is **not** the integrated copper PHY **`0x00221631`**; bitfields follow **Microchip** definitions for that STA — **not** **@1–@5** copper decode.

### What this dump **cannot** settle (RGMII / CPU port)

These **Clause 22** blocks describe **embedded PHY / PHY-management** objects at **MDIO STAs**. They **do not** replace:

- **Port 6 RGMII MAC** register file (**§5.2.3**, **`0x6300`–`0x63FF`**). **`0x6301[4:3]`** internal delays — **cannot be read or written via MIIM** (**§5.0**: MIIM = PHY regs only). Defaults + FAQ (**SPI/I²C / IBA / `phy-mode` alternatives**): **`docs/DT510-ETHERNET-KSZ9896.md`** (**FAQ — MIIM vs `0x6301`**).
- **Actual LVTTL/TMDS pad behavior**, **clock skew**, or **PCB** issues on **RGMII TX**.

If the symptom is **“frames exit Linux `end0` but fail on wire toward laptop,”** combine this PHY analysis with **`ethtool -S end0`**, **scope**, and **Port 6** CSR access per strap (**SPI/I2C** may be required for full switch view — **MIIM-only** designs sometimes expose **PHY-side only** through **`fec` MDIO**).

---

## Interpretation notes (high level)

**Two different “port” ideas (easy to mix up):**

| Name in this doc | What it is **not** | What it actually is |
|------------------|--------------------|---------------------|
| **PHY @0** | **Not** “switch Port 0”, **not** copper **`0x00221631`** | **PRTAD 0** on MIIM — **PHY-ID `0x004540fe`**, **Microchip** management / host‑side PHY register bank (**see § PHY @0** and **Table 4‑27** in **DS00002390C**). |
| **PHY @1–@5** | **Not** KSZ “Port 1 … Port 5” by pin name alone | **MDIO** stations **1–5** — integrated **RJ45 copper PHY** identity **`0x00221631`**. |
| **Port 6** (datasheet) | **Not** MDIO address **6** | **MAC** interface (**RGMII**) to **CPU**. **xMII control registers** are **not** visible through MIIM (**checklist §7.0**); many live in **SPI/I²C** space (**§5.2.3** **0x6300**…). |

**PHY @0** answers **“what is MIIM STA 0?”** — the **`0x004540fe`** block. **Port 6** answers **“which pins/signals face the SoC?”** **Table 4‑27** ties **MIIM PHY addresses** to **internal Port PHY spaces**; **full** Port **6** bring‑up still combines **@0** Clause **22** (if needed) **with** **non‑MIIM** register access where the datasheet requires it.

1. **@1 / @2** show **link up** in probe; **reg 1** **0x796d** and non-zero **reg 5** on **@1** are consistent with **autoneg complete + partner**.
2. **@3–@5** **down**: **reg 1** **0x7949**, **reg 5** **0x0000** — no partner / no cable.
3. **@4** stands out (**BMCR 0x1100**, **reg 4** **0x0c01**, **reg 9** **0x0400**) vs typical **0x1140** / **0x0de1** / **0x0700** on linked ports — worth correlating with **strap**, cable, or **forced mode** per datasheet.
4. **MDIO PHY @0** has a **different PHY-ID** than **@1–@5** — treat it as a **different management object**, not “RJ45 PHY @0”. Do **not** reuse copper **@1–@5** bitfield decoding for **@0**.
5. **Port 6 RGMII / xMII** tuning is **not** fully covered by **MIIM** alone (**checklist §7.0** — **no xMII regs** on MDIO). Use **SPI/I²C** + **§5.2.3** where the datasheet puts **XMII** control; use **§ PHY @0** for **PRTAD 0** Clause **22** only. **Copper** issues still pivot on **@1–@5**.

---

## Related docs (same BSP repo)

- `docs/DT510-ETHERNET-KSZ9896.md` — topology, `mdio` vs `phytool`, Table 4‑27 usage, **Port 6 RGMII** default straps (**§3.2.1**), **§4.11.4**, **§5.2.3** **`0x6301`** **RGMII_ID_ig/_eg** defaults (**internal RX_CLK delay on**, **TX_CLK delay off**), MIIM-only limitation (**§5.0**).
- `docs/GPIO-HOG-ACTIVE-POLARITY.md` — KSZ9896 sideband reset / PME / INTR.

---

## Revision

| Date       | Notes |
|------------|--------|
| 2026-04-28 | Initial dump and tables from live `mdio` session on DT510. |
| 2026-04-28 | Added comprehensive IEEE/KSZ analysis (BMCR/BMSR/AN/1G/vendor) for EE review. |
| 2026-04-28 | Clarified MDIO PHY @0 vs datasheet Port 6 (terminology). |
| 2026-04-28 | Per-register **Analysis** column on PHY **@0–@5** dump tables. |
| 2026-04-28 | **PHY @0:** authoritative MIIM / **PRTAD 0** decode (**0x004540fe**, checklist §7.x, Table 4‑27). |
| 2026-04-28 | Cross-ref **`DT510-ETHERNET-KSZ9896.md`** Port **6** **RGMII** (**§4.11.4**, straps, **XMII** regs). |
| 2026-04-28 | Pointer to **`0x6301`** internal **RGMII** delay defaults (**egress on**, **ingress off**). |
| 2026-04-28 | Clarified **`0x6301`** **not** accessible via MIIM; FAQ in **`DT510-ETHERNET-KSZ9896.md`**. |
