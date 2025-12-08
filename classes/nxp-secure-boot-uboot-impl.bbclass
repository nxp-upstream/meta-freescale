inherit nxp-secure-boot

do_configure:append() {
    unset i j
    for config in ${UBOOT_MACHINE}; do
        i=$(expr $i + 1);
        for type in ${UBOOT_CONFIG}; do
            j=$(expr $j + 1);
            if [ "${type}" = "sd" ] && [ "${j}" = "${i}" ]; then
                # Update defconfig to enable secure boot
                kconfig_option="${@bb.utils.contains('NXP_SECURE_BOOT_TYPE', 'ahab', 'CONFIG_AHAB_BOOT', 'CONFIG_IMX_HAB'  , d)}"
                echo "$kconfig_option=y" >> ${B}/${config}-sd/.config
                break 2
            fi
        done
    done
}

do_compile:append() {
    unset i j
    for config in ${UBOOT_MACHINE}; do
        i=$(expr $i + 1);
        for type in ${UBOOT_CONFIG}; do
            j=$(expr $j + 1);
            if [ "${type}" = "sd" ] && [ "${j}" = "${i}" ]; then
                uboot_image="${UBOOT_BINARYNAME}-sd.${UBOOT_SUFFIX}"
                if [ ${@bb.utils.filter('NXP_SECURE_BOOT_TYPE', 'ahab', d)} ]; then
                    cfgfile="sign.cfg"
                elif [ -e "${SIG_DATA_PATH}/csf_hab4.cfg" ]; then
                    cfgfile="${SIG_DATA_PATH}/csf_hab4.cfg"
                else
                    cfgfile="${STAGING_DIR_NATIVE}${datadir}/nxp-imx-signer/csf_hab4.cfg.sample"
                fi
                bbnote SIG_TOOL_PATH=${NXP_SECURE_BOOT_SIGNING_TOOL} \
                    SIG_DATA_PATH=${NXP_SECURE_BOOT_SIGNING_DATA} \
                    imx_signer -d \
                    -i ${B}/${config}-sd/$uboot_image \
                    -c $cfgfile
                SIG_TOOL_PATH=${NXP_SECURE_BOOT_SIGNING_TOOL} \
                    SIG_DATA_PATH=${NXP_SECURE_BOOT_SIGNING_DATA} \
                    imx_signer -d \
                    -i ${B}/${config}-sd/$uboot_image \
                    -c $cfgfile
                if [ ! -e "${B}/${config}-sd/signed-$uboot_image" ]; then
                    bbfatal 'Signed image missing after signing operation'
                fi
                break 2
            fi
        done
    done
}

do_deploy:append() {
    if [ ${@bb.utils.filter('NXP_SECURE_BOOT_TYPE', 'hab', d)} ]; then
        unset i j
        for config in ${UBOOT_MACHINE}; do
            i=$(expr $i + 1)
            for type in ${UBOOT_CONFIG}; do
                j=$(expr $j + 1)
                if [ "${type}" = "sd" ] && [ "${j}" = "${i}" ]; then
                    # Store the uboot config file so the linux build can extract
                    # CONFIG_SYS_LOAD_ADDR from it for signing
                    cp ${B}/${config}-${type}/.config ${DEPLOYDIR}/nxp-secure-boot-uboot.config
                    break 2
                fi
            done
        done
    fi
}
