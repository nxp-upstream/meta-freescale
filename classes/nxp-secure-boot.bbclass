DEPENDS += "nxp-imx-signer-native"

PACKAGECONFIG:append = " ${PACKAGECONFIG_NXP_SECURE_BOOT_SIGNING_TOOL}"
PACKAGECONFIG_NXP_SECURE_BOOT_SIGNING_TOOL ??= \
    "${@bb.utils.contains('NXP_SECURE_BOOT_TYPE', 'ahab', 'spsdk', 'cst', d)}"

PACKAGECONFIG[cst] = ",,,,,spsdk"
PACKAGECONFIG[spsdk] = ",,,,,cst"

NXP_SECURE_BOOT_TYPE:mx6-generic-bsp  = "hab"
NXP_SECURE_BOOT_TYPE:mx7-generic-bsp  = "hab"
NXP_SECURE_BOOT_TYPE:mx8-generic-bsp  = "ahab"
NXP_SECURE_BOOT_TYPE:mx8m-generic-bsp = "hab"
NXP_SECURE_BOOT_TYPE:mx9-generic-bsp  = "ahab"

NXP_SECURE_BOOT_SIGNING_TOOL ?= ""
NXP_SECURE_BOOT_SIGNING_DATA ?= "${NXP_SECURE_BOOT_SIGNING_TOOL}"

python() {
    import os
    import bb
    # Set NXP_SECURE_BOOT_TYPE_CFGFILE
    if bb.utils.filter('NXP_SECURE_BOOT_TYPE', 'ahab', d):
        cfgfile = 'sign.cfg'
    else:
        sig_data_path = d.getVar('SIG_DATA_PATH') or ''
        hab_cfg = os.path.join(sig_data_path, 'csf_hab4.cfg')
        if os.path.exists(hab_cfg):
            cfgfile = hab_cfg
        else:
            staging_native = d.getVar('STAGING_DIR_NATIVE') or ''
            datadir = d.getVar('datadir') or ''
            cfgfile = os.path.join(staging_native, datadir.lstrip('/'),
                                   'nxp-imx-signer', 'csf_hab4.cfg.sample')
    d.setVar('NXP_SECURE_BOOT_CFGFILE', cfgfile)
}

do_check_signing_tool_install() {
    if [ "${NXP_SECURE_BOOT_SIGNING_TOOL}" = "" ]; then
        bbfatal "Missing NXP_SECURE_BOOT_SIGNING_TOOL. Please set it in local.conf (or site.conf or user.conf)"
    fi
    signing_tool_type="${@bb.utils.filter('PACKAGECONFIG', 'cst spsdk', d)}"
    case "$signing_tool_type" in
    cst)
        signing_tool_folder="${NXP_SECURE_BOOT_SIGNING_TOOL}/linux64/bin/cst"
        ;;
    spsdk)
        signing_tool_folder="${NXP_SECURE_BOOT_SIGNING_TOOL}/spsdk"
        ;;
    *)
        bbfatal "The signing tool type is not recognized: \"$signing_tool_type\""
        ;;
    esac
    if [ ! -f "$signing_tool_folder" ]; then
        bbfatal "The signing tool is not found at location \"$signing_tool_folder\""
    fi
}
addtask do_check_signing_tool_install before do_configure

do_sign_image() {
    path=$1
    image=$2
    bbnote "Signing image $path/$image"
    bbnote SIG_TOOL_PATH=${NXP_SECURE_BOOT_SIGNING_TOOL} SIG_DATA_PATH=${NXP_SECURE_BOOT_SIGNING_DATA} \
        imx_signer -d -i $path/$image -c ${NXP_SECURE_BOOT_CFGFILE}
    SIG_TOOL_PATH=${NXP_SECURE_BOOT_SIGNING_TOOL} SIG_DATA_PATH=${NXP_SECURE_BOOT_SIGNING_DATA} \
        imx_signer -d -i $path/$image -c ${NXP_SECURE_BOOT_CFGFILE}
    if [ ! -e "signed-$image" ]; then
        bbfatal "The signed image \"$PWD/signed-$image\" is missing after signing operation"
    fi
    rm $path/$image
    mv signed-$image $path/$image
}

COMPATIBLE_MACHINE = "(mx6-generic-bsp|mx7-generic-bsp|mx8-generic-bsp|mx9-generic-bsp)"
