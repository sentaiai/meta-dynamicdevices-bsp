/* SPDX-License-Identifier: (GPL-2.0 OR MIT) */
/*
 * i.MX 8M Mini — SW_PAD_CTL_PAD_* bitfields (second cell of &iomuxc fsl,pins).
 *
 * Only bits [8:0] are meaningful for typical GPIO-class pads; [31:9] are reserved —
 * see IMX8MMRM Chapter 8 (SW_PAD_CTL_PAD_<NAME> per pad).
 *
 * Layout (matches NXP RM figure for GPIO-class pads and Linux
 * arch/arm64/boot/dts/freescale/imx8mm-pinfunc.h MX8MM_* literals):
 *
 *     PE    HYS   PUE    ODE   FSEL    DSE
 *    [8]   [7]   [6]    [5]   [4:3]   [2:0]
 *
 * PE    — Pull Enable (often labeled PE in RM tables).
 * HYS   — Hysteresis (CMOS vs Schmitt).
 * PUE   — Pull direction when PE is set (see RM; Linux MX8MM_PULL_UP / PULL_DOWN).
 * ODE   — Open Drain Enable.
 * FSEL  — Slew / frequency select (Linux: MX8MM_FSEL_FAST / FSEL_SLOW).
 * DSE   — Drive Strength; **encoding is not sequential** — use named macros below.
 */

#ifndef __IMX8MM_SW_PAD_CTL_FIELDS_H
#define __IMX8MM_SW_PAD_CTL_FIELDS_H

/* Valid electrical bits for typical GPIO pads (reserved bits above must stay 0). */
/* No C unsigned suffix on hex — dtc rejects tokens like 0x100u in fsl,pins cells. */
#define IMX8MM_SW_PAD_CTL_MASK_TRAILING		0x1ff

/*
 * Drive strength [2:0] — values from Linux imx8mm-pinfunc.h (non-linear encoding).
 */
#define IMX8MM_SW_PAD_CTL_DSE_X1		0x0
#define IMX8MM_SW_PAD_CTL_DSE_X2		0x4
#define IMX8MM_SW_PAD_CTL_DSE_X4		0x2
#define IMX8MM_SW_PAD_CTL_DSE_X6		0x6

#define IMX8MM_SW_PAD_CTL_FSEL_SLOW		0x0
#define IMX8MM_SW_PAD_CTL_FSEL_FAST		0x10

#define IMX8MM_SW_PAD_CTL_ODE_DIS		0x0
#define IMX8MM_SW_PAD_CTL_ODE_EN		0x20

#define IMX8MM_SW_PAD_CTL_PUE_DOWN		0x0
#define IMX8MM_SW_PAD_CTL_PUE_UP		0x40

#define IMX8MM_SW_PAD_CTL_HYS_CMOS		0x0
#define IMX8MM_SW_PAD_CTL_HYS_SCHMITT		0x80

#define IMX8MM_SW_PAD_CTL_PE_DIS		0x0
#define IMX8MM_SW_PAD_CTL_PE_EN			0x100

/*
 * Optional mux note (not SW_PAD_CTL): Linux sets SION via bit in IOMUXC mux register
 * (e.g. I2C 0x400001c3) — do not confuse with pad electricals.
 */

#endif /* __IMX8MM_SW_PAD_CTL_FIELDS_H */
