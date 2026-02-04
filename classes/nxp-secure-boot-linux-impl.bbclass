xDEPENDS += "${DEPENDS_BOOTLOADER}"
DEPENDS_BOOTLOADER:arm = "u-boot-imx"
DEPENDS_BOOTLOADER:aarch64 = "imx-boot"

inherit nxp-secure-boot

do_nxp_sign_kernel_hab() {
    # Only kernel image type Image and zImage are supported by i.MX devices
    if [ ${KERNEL_IMAGETYPE} != "zImage" ] && \
       [ ${KERNEL_IMAGETYPE} != "Image" ]; then
        bbfatal "Unknown kernel image format"
    fi

    cp ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${MACHINE}.bin ${S}/${KERNEL_IMAGETYPE}
    IMAGE="${S}/${KERNEL_IMAGETYPE}"

    if [ "${KERNEL_IMAGETYPE}" = "Image" ]; then
        # Get kernel image pad size
        image_pad_size="$(od -An -j 16 -N 4 -i ${IMAGE} | tr -d ' ')"
        # Pad the image
    elif [ "${KERNEL_IMAGETYPE}" = "zImage" ]; then
        # Get kernel image pad size after padding it to next 1K
        image_size="$(stat -L --printf=%s ${IMAGE})"
        image_pad_size="$(expr ${image_size} + $(expr 4096 - $(expr ${image_size} % 4096)))"
    else
        bbfatal "Unknown kernel image format"
    fi

    # Pad the image
    objcopy -I binary -O binary --pad-to "${image_pad_size}" --gap-fill=0x00 ${IMAGE} "${SIGNDIR}/${KERNEL_IMAGETYPE}_pad.bin"

    load_address_hex="$(sed -n 's/CONFIG_SYS_LOAD_ADDR=//p' ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/u-boot-imx.config)"
    load_address="$(printf "%u" ${load_address_hex})"
    ivt_pointer="$(expr ${load_address} + ${image_pad_size})"
    csf_pointer="$(expr ${ivt_pointer} + 32)"

    # Generate Image Vector Table script
    GEN_IVT="$(cat <<-EOF
	import struct
	ivt = open('${SIGNDIR}/ivt.bin', 'wb') or Exception('Unable to open ivt file').throw()
	ivt.write(struct.pack('<L', 0x432000D1)) # Signature
	ivt.write(struct.pack('<L', ${load_address})) # Load Address (*load_address)
	ivt.write(struct.pack('<L', 0x0)) # Reserved
	ivt.write(struct.pack('<L', 0x0)) # DCD pointer
	ivt.write(struct.pack('<L', 0x0)) # Boot Data
	ivt.write(struct.pack('<L', ${ivt_pointer})) # Self Pointer (*ivt)
	ivt.write(struct.pack('<L', ${csf_pointer})) # CSF Pointer (*csf)
	ivt.write(struct.pack('<L', 0x0)) # Reserved
	ivt.close()
	EOF
)"

    # Generate Image Vector Table
    python3 -c "${GEN_IVT}"

    # Attach IVT
    cat ${SIGNDIR}/${KERNEL_IMAGETYPE}_pad.bin ${SIGNDIR}/ivt.bin > ${SIGNDIR}/${KERNEL_IMAGETYPE}_pad_ivt.bin
}

do_sign_kernel_image:append:hab4() {

    # Creating a cfg file for imx_signer
    if [ -e "${SIG_DATA_PATH}/csf_hab4.cfg" ]; then
        # Use user defined keys
        install -m 0755 ${SIG_DATA_PATH}/csf_hab4.cfg ${SIGNDIR}/${SIG_CFGFILE}
    else
        # Use default keys
        install -m 0755 ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/csf_hab4.cfg.sample ${SIGNDIR}/${SIG_CFGFILE}
    fi
}

do_sign_kernel_image:append:hab4() {

    # Generate signed image data
    SIG_TOOL_PATH=${SIG_TOOL_PATH} SIG_DATA_PATH=${SIG_DATA_PATH} ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/imx_signer -d -i ${SIGNDIR}/${KERNEL_IMAGETYPE}_pad_ivt.bin -c ${SIGNDIR}/${SIG_CFGFILE}
    if [ ! -e "${S}/signed-${KERNEL_IMAGETYPE}_pad_ivt.bin" ]; then
        bbfatal 'Kernel Image signing failed'
    fi
}

xdo_compile:append() {
    if [ "${NXP_SECURE_BOOT_TYPE}" = "ahab" ]; then
        do_nxp_sign_kernel_ahab
    else
        do_nxp_sign_kernel_hab
    fi
}

xdo_compile:append() {
    unset i j
    for config in ${UBOOT_MACHINE}; do
        i=$(expr $i + 1);
        for type in ${UBOOT_CONFIG}; do
            j=$(expr $j + 1);
            if [ "${type}" = "sd" ] && [ "${j}" = "${i}" ]; then
                uboot_image="${UBOOT_BINARYNAME}-sd.${UBOOT_SUFFIX}"
                if [ "${NXP_SECURE_BOOT_TYPE}" = "ahab" ]; then
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

xdo_deploy:append() {
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
