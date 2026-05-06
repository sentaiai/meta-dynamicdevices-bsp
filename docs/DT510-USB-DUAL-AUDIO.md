# DT510: USB dual audio (gadget) vs on-board codecs

## Philosophy

**Gadget support stays in the image** (`usb-gadget-scripts`, `setup-usb-dual-audio-gadget`, systemd unit). There is no need to remove it from the build when moving to real codecs.

- **Real hardware audio:** use the on-board codec path (SAI/I2S, ALSA, AVM). Simply **do not start** the USB gadget service if you do not want USB simulation (or turn off **autostart** — see below).
- **Simulated / lab USB audio:** **enable** and **bind** the gadget (`systemctl start` …) when you want the host to see dual UAC2; same image, different runtime choice.

So: **one image**, optional USB gadget enable/bind for simulation, codec stack when using physical transducers.

## Roles

| Path | Use |
|------|-----|
| **USB dual UAC2 gadget** | **Simulated / lab** — host sees two audio interfaces (driver + passengers) over USB; pairs with AVM/container tests and laptop bridge scripts. |
| **On-board codecs** (TAS2563, future TAC5301 / TAA5412 / TAS6424 per SSOT) | **Product audio** — I2S/SAI to physical transducers; this is the long-term implementation. |

Both paths can coexist; **boot policy** only controls whether the gadget **starts automatically** at boot — not whether support is installed.

## Machine feature: `dt510-usb-dual-audio-autostart`

Defined in **`conf/machine/imx8mm-jaguar-dt510.conf`**. When **present**, **`usb-dual-audio-gadget-dt510.service`** is **enabled** at boot (`usb-gadget-scripts` recipe).

- **Default in BSP:** feature is **on** — same behaviour as before this toggle (gadget comes up automatically for lab/CI).
- **Codec-first / production-style images:** remove the feature so the gadget **does not** start at boot:

```bitbake
MACHINE_FEATURES:remove:imx8mm-jaguar-dt510 = "dt510-usb-dual-audio-autostart"
```

Add that line in **factory `local.conf` / `site.conf`**, **meta-subscriber-overrides** machine fragment, or another high-priority config layer — wherever you centralise machine overrides for that image.

## Manual simulated testing (autostart off)

Packages and scripts remain installed:

```bash
sudo systemctl start usb-dual-audio-gadget-dt510
# optional persistence for that image:
sudo systemctl enable usb-dual-audio-gadget-dt510
```

Stop:

```bash
sudo systemctl stop usb-dual-audio-gadget-dt510
```

## Device tree / kernel

Gadget mode requires **`&usbotg1`** **peripheral** mode (already set in `imx8mm-jaguar-dt510.dts`). Disabling the systemd unit does not change DT; it only skips creating the configfs gadget at boot.

**USB‑C / PD:** DT510 does **not** use an **STUSB4500** (or TCPC) — the board is **not** USB‑C powered; there is no `stusb4500` machine feature on `imx8mm-jaguar-dt510`. The OTG link is for **USB gadget / device** behaviour (including this lab dual‑UAC2 path), not ST‑micro PD negotiation. **Sentai** retains STUSB4500 in its machine config.

## See also

- [`DT510-BSP-PROJECT-PLAN.md`](DT510-BSP-PROJECT-PLAN.md) — phased hardware bring-up.
- [`DT510-HARDWARE-AUDIT-CHECKLIST.md`](DT510-HARDWARE-AUDIT-CHECKLIST.md) — codec SSOT vs BSP.

---

*Last updated: 2026-04-13 — noted no STUSB4500 on DT510.*
