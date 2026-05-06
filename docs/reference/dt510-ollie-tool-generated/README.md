# DT510 — tool-generated DTS (reference only)

This folder holds **DeviceTree sources produced by an automated tool** (Ollie) for **review and gap analysis**. They are **not** wired into the Yocto build and **must not** be treated as a final BSP solution.

## Status

- **Incomplete** — intended for comparison against the hardware SSOT and `docs/DT510-BSP-PROJECT-PLAN.md`.
- **Non-authoritative** — canonical DT for the product remains under `recipes-bsp/device-tree/lmp-device-tree/` and `recipes-kernel/linux/linux-lmp-fslc-imx/` until deliberately replaced via a normal BSP change.

## How to use

1. Drop or update the `.dts` / `.dtsi` (and any companion `.c` / `.h` from the same tool run) as revisions arrive.
2. Review **diffs** against the current `imx8mm-jaguar-dt510.dts` and the [VIX DT510 pinout / hardware spec](https://docs.google.com/document/d/1dlVcfW7SrOifR-rGjkJnVbnQBO4uU8HeS1MEfDmgcYE/edit?usp=sharing).
3. Drive **implementation** in the real recipes (DT symlink policy, kernel fragments) from the project plan tiers — using this folder only as **reference input**.

## Files

| File | Notes |
|------|--------|
| `pin_mux.dts` | Tool-generated DTS snippet / overlay input — **review only**. |
| `pin_mux.c` | Generated C (often IMX pinmux init) — **not** compiled by this BSP layer unless explicitly integrated. |
| `pin_mux.h` | Generated header companion to `pin_mux.c`. |

*Initial import from a local `Downloads/dt510/` snapshot (2026-04-13).*
