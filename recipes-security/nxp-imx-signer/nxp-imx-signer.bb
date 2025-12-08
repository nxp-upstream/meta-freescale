SUMMARY = "NXP IMX Signer"
DESCRIPTION = "Image signing automation tool using CST/SPSDK"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=1f6f1c0be32491a0c8d2915607a28f36"

SRC_URI = "${CST_SIGNER};branch=${SRCBRANCH}"
CST_SIGNER ?= "git://github.com/nxp-imx-support/nxp-cst-signer.git;protocol=https"
SRCBRANCH = "master"
SRCREV = "7c7812a39d0470115f363cf45736be3c8284cb40"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/src/imx_signer ${D}${bindir}
    install -d ${D}${datadir}/${BPN}
    install -m 0644 ${S}/*.cfg.sample ${D}${datadir}/${BPN}
}

BBCLASSEXTEND = "native nativesdk"
