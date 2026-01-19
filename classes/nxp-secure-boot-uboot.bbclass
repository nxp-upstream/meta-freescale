inherit_defer ${@bb.utils.contains('DISTRO_FEATURES', 'nxp-secure-boot', '${NXP_SECURE_BOOT_UBOOT_IMPL}', '', d)}

NXP_SECURE_BOOT_UBOOT_IMPL = ""
NXP_SECURE_BOOT_UBOOT_IMPL:mx6-generic-bsp = "nxp-secure-boot-uboot-impl"
NXP_SECURE_BOOT_UBOOT_IMPL:mx7-generic-bsp = "nxp-secure-boot-uboot-impl"
