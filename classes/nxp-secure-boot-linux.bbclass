inherit ${@bb.utils.contains('DISTRO_FEATURES', 'nxp-secure-boot', 'nxp-secure-boot-linux-impl', '', d)}
