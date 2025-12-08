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

COMPATIBLE_MACHINE = "(mx6-generic-bsp|mx7-generic-bsp|mx8-generic-bsp|mx9-generic-bsp)"
