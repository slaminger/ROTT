#!/usr/bin/env bash

rp_module_id="tinker-basic-install"
rp_module_desc="Automated basic install for TinkerRetroPie"
rp_module_section=""


function install_tinker-basic-install() {
    __ERRMSGS=()
    __INFMSGS=()

    local idx
    for idx in $(rp_getSectionIds core) $(rp_getSectionIds main); do
        rp_installModule "$idx"
    done

    echo "====== End basic install ======"

    local RETURN_CODE=0

    if [[ ${#__ERRMSGS[@]} -gt 0 ]]; then
        RETURN_CODE=1
        printMsgs "console" "${__ERRMSGS[@]}"
    fi
    if [[ ${#__INFMSGS[@]} -gt 0 ]]; then
        printMsgs "console" "${__INFMSGS[@]}"
    fi

    exit $RETURN_CODE
}
