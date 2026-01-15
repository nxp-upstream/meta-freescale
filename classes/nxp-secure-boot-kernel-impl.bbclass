inherit nxp-secure-boot

DEPENDS += "u-boot-imx"

do_sign_image_ahab() {
    bbnote "Signing for AHAB"
}

do_sign_image_hab() {
    path=${KERNEL_OUTPUT_DIR}
    image=${KERNEL_IMAGETYPE}

    # Pad the image
    case ${KERNEL_IMAGETYPE} in
    Image)
        image_pad_size="$(od -An -j 16 -N 4 -i $path/$image | tr -d ' ')"
        ;;
    zImage)
        # Pad image to next 1k
        image_size="$(stat -L --printf=%s $path/$image)"
        image_pad_size="$(expr ${image_size} + $(expr 4096 - $(expr ${image_size} % 4096)))"
        ;;
    *)
        bbfatal "Unknown KERNEL_IMAGETYPE value is \"${KERNEL_IMAGETYPE}\""
        ;;
    esac
    objcopy -I binary -O binary --pad-to $image_pad_size --gap-fill=0x00 $path/$image $path/$image-pad

    load_address_hex=$(sed -n 's/CONFIG_SYS_LOAD_ADDR=//p' ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/u-boot-imx.config)
    load_address=$(printf "%u" $load_address_hex)
    ivt_pointer=$(expr $load_address + $image_pad_size)
    csf_pointer=$(expr $ivt_pointer + 32)

    # Generate and attach Image Vector Table
    gen_ivt="$(cat <<-EOF
	import struct
	ivt = open('$path/$image-ivt', 'wb') or Exception('Unable to open ivt file').throw()
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
    python3 -c "$gen_ivt"
    cat $path/$image-pad $path/$image-ivt > $path/$image-pad-ivt

    # Generate signed image
    do_sign_image $path $image-pad-ivt
}

do_compile:append() {
    case ${NXP_SECURE_BOOT_TYPE} in
    ahab)
        do_sign_image_ahab
        ;;
    hab)
        do_sign_image_hab
        ;;
    *)
        bbfatal "Unknown NXP_SECURE_BOOT_TYPE value is \"${NXP_SECURE_BOOT_TYPE}\""
        ;;
    esac
}
