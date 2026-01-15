inherit nxp-secure-boot

do_configure:append() {
    case ${NXP_SECURE_BOOT_TYPE} in
    ahab) kconfig_option=CONFIG_AHAB_BOOT;;
     hab) kconfig_option=CONFIG_IMX_HAB;;
       *) echo bbfatal "Unknown NXP_SECURE_BOOT_TYPE value is \"${NXP_SECURE_BOOT_TYPE}\"";;
    esac
    unset i j
    for config in ${UBOOT_MACHINE}; do
        i=$(expr $i + 1);
        for type in ${UBOOT_CONFIG}; do
            j=$(expr $j + 1);
            if [ "${type}" = "sd" ] && [ "${j}" = "${i}" ]; then
                # Update defconfig to enable secure boot
                echo "$kconfig_option=y" >> ${config}-sd/.config
                break 2
            fi
        done
    done
}

do_compile:append() {
    if [ ${@bb.utils.filter('NXP_SECURE_BOOT_TYPE', 'hab', d)} ]; then
        unset i j
        for config in ${UBOOT_MACHINE}; do
            i=$(expr $i + 1);
            for type in ${UBOOT_CONFIG}; do
                j=$(expr $j + 1);
                if [ "${type}" = "sd" ] && [ "${j}" = "${i}" ]; then
                    uboot_image="${UBOOT_BINARYNAME}-sd.${UBOOT_SUFFIX}"
                    do_sign_image ${config}-sd $uboot_image
                    break 2
                fi
            done
        done
    fi
}

do_deploy:append() {
    # FIXME: Someone is not honoring the defined CWD for this function, so set it manually
    cd ${B}
    if [ ${@bb.utils.filter('NXP_SECURE_BOOT_TYPE', 'hab', d)} ]; then
        unset i j
        for config in ${UBOOT_MACHINE}; do
            i=$(expr $i + 1)
            for type in ${UBOOT_CONFIG}; do
                j=$(expr $j + 1)
                if [ "${type}" = "sd" ] && [ "${j}" = "${i}" ]; then
                    # Store the uboot config file so the linux build can extract
                    # CONFIG_SYS_LOAD_ADDR from it for signing
                    cp ${config}-${type}/.config ${DEPLOYDIR}/u-boot-imx.config
                    break 2
                fi
            done
        done
    fi
}
