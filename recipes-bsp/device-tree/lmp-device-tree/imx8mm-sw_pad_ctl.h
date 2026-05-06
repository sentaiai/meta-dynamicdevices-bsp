/* SPDX-License-Identifier: (GPL-2.0 OR MIT) */
/*
 * i.MX 8M Mini — full SW_PAD_CTL words for &iomuxc fsl,pins (second cell).
 *
 * Field definitions: imx8mm-sw_pad_ctl-fields.h (IMX8MMRM Chapter 8).
 *
 * **Mux vs pad control:** The first cell (MX8MM_IOMUXC_* macro) selects signal routing. The second cell
 * is only SW_PAD_CTL electricals.
 *
 * Names below describe **role on the board** where possible. Several roles share the same hex word as
 * NXP imx8mm-evk.dtsi (called out per macro).
 */

#ifndef __IMX8MM_SW_PAD_CTL_H
#define __IMX8MM_SW_PAD_CTL_H

#include "imx8mm-sw_pad_ctl-fields.h"

/*
 * --- 0x140 (imx8mm-evk UART default): PE + internal pull-up ---
 * Same electrical word is used for ECSPI and many GPIO strap / sideband lines on EVK and DT510.
 */
#define IMX8MM_PAD_PULLUP_BUS						\
	(   IMX8MM_SW_PAD_CTL_PE_EN				\
	  | IMX8MM_SW_PAD_CTL_PUE_UP )

#define IMX8MM_PAD_UART_DEFAULT				IMX8MM_PAD_PULLUP_BUS
#define IMX8MM_PAD_SPI_HOST_DEFAULT			IMX8MM_PAD_PULLUP_BUS
#define IMX8MM_PAD_GPIO_STRAP_PULLUP			IMX8MM_PAD_PULLUP_BUS

/*
 * --- 0x114 — imx8mm-evk GPIO1_IO00 recipe (PE + fast slew + DSE X2); optional per-pin override ---
 */
#define IMX8MM_PAD_GPIO_DIO_WEAK					\
	(   IMX8MM_SW_PAD_CTL_PE_EN				\
	  | IMX8MM_SW_PAD_CTL_FSEL_FAST				\
	  | IMX8MM_SW_PAD_CTL_DSE_X2 )

/*
 * --- 0x116 — Fast slew + DSE X6 + pull-down select (general GPIO, ENET switch sideband, codec GPIOs) ---
 */
#define IMX8MM_PAD_GPIO_STD						\
	(   IMX8MM_SW_PAD_CTL_PE_EN				\
	  | IMX8MM_SW_PAD_CTL_FSEL_FAST				\
	  | IMX8MM_SW_PAD_CTL_DSE_X6				\
	  | IMX8MM_SW_PAD_CTL_PUE_DOWN )

/* Front-panel / connector DIO — one SW_PAD recipe for all GPIO1_IO00/01/04–09 lines (imx8mm-evk general GPIO). */
#define IMX8MM_PAD_GPIO_DEFAULT				IMX8MM_PAD_GPIO_STD

/*
 * --- 0x156 — EVK GPIO1_IO05 recipe (pull-up select); optional per-pin override ---
 */
#define IMX8MM_PAD_GPIO_PULLUP_STRONG					\
	(   IMX8MM_SW_PAD_CTL_PE_EN				\
	  | IMX8MM_SW_PAD_CTL_PUE_UP				\
	  | IMX8MM_SW_PAD_CTL_FSEL_FAST				\
	  | IMX8MM_SW_PAD_CTL_DSE_X6 )

#define IMX8MM_PAD_I2S_BUS					IMX8MM_PAD_GPIO_STD
#define IMX8MM_PAD_I2S_SYNC					IMX8MM_PAD_GPIO_STD

/* USDHC — imx8mm-evk usdhc2grp / 100 MHz / 200 MHz */

#define IMX8MM_PAD_USDHC_CLK						\
	(   IMX8MM_SW_PAD_CTL_PE_EN				\
	  | IMX8MM_SW_PAD_CTL_HYS_SCHMITT			\
	  | IMX8MM_SW_PAD_CTL_FSEL_FAST				\
	  | IMX8MM_SW_PAD_CTL_DSE_X1 )

#define IMX8MM_PAD_USDHC_BUS						\
	(   IMX8MM_SW_PAD_CTL_PE_EN				\
	  | IMX8MM_SW_PAD_CTL_HYS_SCHMITT			\
	  | IMX8MM_SW_PAD_CTL_PUE_UP				\
	  | IMX8MM_SW_PAD_CTL_FSEL_FAST				\
	  | IMX8MM_SW_PAD_CTL_DSE_X1 )

#define IMX8MM_PAD_USDHC_CLK_100MHZ					\
	(   IMX8MM_SW_PAD_CTL_PE_EN				\
	  | IMX8MM_SW_PAD_CTL_HYS_SCHMITT			\
	  | IMX8MM_SW_PAD_CTL_FSEL_FAST				\
	  | IMX8MM_SW_PAD_CTL_DSE_X2 )

#define IMX8MM_PAD_USDHC_BUS_100MHZ					\
	(   IMX8MM_SW_PAD_CTL_PE_EN				\
	  | IMX8MM_SW_PAD_CTL_HYS_SCHMITT			\
	  | IMX8MM_SW_PAD_CTL_PUE_UP				\
	  | IMX8MM_SW_PAD_CTL_FSEL_FAST				\
	  | IMX8MM_SW_PAD_CTL_DSE_X2 )

#define IMX8MM_PAD_USDHC_CLK_200MHZ					\
	(   IMX8MM_SW_PAD_CTL_PE_EN				\
	  | IMX8MM_SW_PAD_CTL_HYS_SCHMITT			\
	  | IMX8MM_SW_PAD_CTL_FSEL_FAST				\
	  | IMX8MM_SW_PAD_CTL_DSE_X6 )

#define IMX8MM_PAD_USDHC_BUS_200MHZ					\
	(   IMX8MM_SW_PAD_CTL_PE_EN				\
	  | IMX8MM_SW_PAD_CTL_HYS_SCHMITT			\
	  | IMX8MM_SW_PAD_CTL_PUE_UP				\
	  | IMX8MM_SW_PAD_CTL_FSEL_FAST				\
	  | IMX8MM_SW_PAD_CTL_DSE_X6 )

/*
 * ENET / RGMII — literals from imx8mm-evk fec1grp (pad-specific decode); do not reuse 0x03 elsewhere.
 */
#define IMX8MM_PAD_ENET_MDIO						0x03

#define IMX8MM_PAD_ENET_RGMII_TX					0x1f

#define IMX8MM_PAD_ENET_RGMII_RX					0x91

/* SAI — imx8mm-evk sai2/sai3/spdif style */
#define IMX8MM_PAD_SAI_DEFAULT						\
	(   IMX8MM_SW_PAD_CTL_HYS_SCHMITT			\
	  | IMX8MM_SW_PAD_CTL_PUE_UP				\
	  | IMX8MM_SW_PAD_CTL_FSEL_FAST				\
	  | IMX8MM_SW_PAD_CTL_DSE_X6 )

#endif /* __IMX8MM_SW_PAD_CTL_H */
