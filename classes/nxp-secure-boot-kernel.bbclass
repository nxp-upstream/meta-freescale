inherit_defer ${@bb.utils.contains('DISTRO_FEATURES', 'nxp-secure-boot', 'nxp-secure-boot-kernel-impl', '', d)}
