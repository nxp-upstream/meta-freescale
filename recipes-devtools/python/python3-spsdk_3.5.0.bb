SUMMARY = "Secure Provisioning SDK for NXP MCUs"
DESCRIPTION = "SPSDK provides tools and libraries for secure provisioning of NXP microcontrollers."
HOMEPAGE = "https://github.com/NXPmicro/spsdk"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=863e3c0c79e2589ac9d16c3918e115d1"

DEPENDS = "python3-setuptools-scm"

PYPI_PACKAGE = "spsdk"
UPSTREAM_CHECK_PYPI_PACKAGE = "${PYPI_PACKAGE}"

SRC_URI[sha256sum] = "1a2fc6ccd257608a838486e873bd75ab6d4f9d628db6f449897ac0ea18f835b6"

inherit pypi python_setuptools_build_meta

RDEPENDS:${PN}:class-target = " \
    python3-core \
    python3-click \
    python3-cryptography \
    python3-intelhex \
    python3-pyserial \
    python3-pyyaml \
    python3-rich \
"

# If SPSDK has extras or CLI tools, you can add:
# FILES:${PN} += "${bindir}"

BBCLASSEXTEND = "native nativesdk"
