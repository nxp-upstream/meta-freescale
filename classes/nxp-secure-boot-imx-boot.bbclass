inherit_defer ${@bb.utils.contains('DISTRO_FEATURES', 'nxp-secure-boot', 'nxp-secure-boot-imx-boot-impl', '', d)}
