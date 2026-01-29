inherit nxp-secure-boot

xdo_compile:append() {
    do_sign_image
}
