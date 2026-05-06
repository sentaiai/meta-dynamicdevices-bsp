# SPDX-License-Identifier: GPL-2.0-only
# memtool only — built from NXP imx-test/test/memtool (same sources as imx-test2),
# without alsa/freetype/libdrm or the rest of the unit test suite.

SUMMARY = "NXP imx-test memtool — MMIO register peek/poke via /dev/mem"
DESCRIPTION = "Standalone build of test/memtool from nxp-imx/imx-test. Installs as ${bindir}/memtool."
HOMEPAGE = "https://github.com/nxp-imx/imx-test"
SECTION = "devel"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${S}/test/memtool/COPYING-GPL-2;md5=59530bdf33659b29e73d4adb9f9f6552"

SRC_URI = "git://github.com/nxp-imx/imx-test.git;protocol=https;branch=${SRCBRANCH}"
SRCBRANCH = "lf-6.1.22_2.0.0"
SRCREV = "9fe083c29439b71292df9a8e4d40c73f25828a69"

S = "${WORKDIR}/git"

PN = "imx-memtool"

# Align with imx-test2_git.bb imx-test snapshot (SRCREV); fixed PV keeps builds reproducible.
PV = "7.0"

# Sources listed in upstream test/memtool/Makefile (BUILD = memtool).
MT_OBJS = "memtool.o mx6dl_modules.o mx6q_modules.o mx6sl_modules.o mx6sx_modules.o mx6ul_modules.o mx7d_modules.o mx6ull_modules.o mx7ulp_modules.o mx8mq_modules.o"

do_configure[noexec] = "1"

do_compile() {
	cd ${S}/test/memtool
	for o in ${MT_OBJS}; do
		src="${o%.o}.c"
		${CC} ${CFLAGS} -Os -Wall -c "${src}" -o "${o}"
	done
	${CC} ${CFLAGS} ${MT_OBJS} ${LDFLAGS} -o memtool
}

do_install() {
	install -d ${D}${bindir}
	install -m 0755 ${S}/test/memtool/memtool ${D}${bindir}/memtool
}

FILES:${PN} = "${bindir}/memtool"
