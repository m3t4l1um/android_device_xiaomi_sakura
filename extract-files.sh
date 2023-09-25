#!/bin/bash
#
# Copyright (C) 2017 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

function blob_fixup() {
    case "${1}" in
        vendor/lib64/libvendor.goodix.hardware.fingerprint@1.0-service.so)
        "${PATCHELF_0_8}" --remove-needed "libprotobuf-cpp-lite.so" "${2}"
        ;;
        etc/permissions/privapp-permissions-qti.xml)
            # MODIFY_PHONE_STATE
            sed -i 's|<permission name="android.permission.READ_PRECISE_PHONE_STATE"/>|<permission name="android.permission.MODIFY_PHONE_STATE"/>\n        <permission name="android.permission.READ_PRECISE_PHONE_STATE"/>|g' "${2}"
            # READ_PRIVILEGED_PHONE_STATE
            sed -i 's|<permission name="android.permission.READ_PRECISE_PHONE_STATE"/>|<permission name="android.permission.READ_PRECISE_PHONE_STATE"/>\n        <permission name="android.permission.READ_PRIVILEGED_PHONE_STATE"/>|g' "${2}"
            # WRITE_SECURE_SETTINGS
            sed -i 's|<permission name="android.permission.SUBSTITUTE_NOTIFICATION_APP_NAME"/>|<permission name="android.permission.SUBSTITUTE_NOTIFICATION_APP_NAME"/>\n        <permission name="android.permission.WRITE_SECURE_SETTINGS"/>|g' "${2}"
            ;;
        vendor/lib64/libgf_ca.so)
            sed -i 's|/system/etc/firmware|/vendor/firmware\x0\x0\x0\x0|g' "${2}"
            ;;
        vendor/lib64/libfm-hci.so)
            "${PATCHELF}" --remove-needed "android.hidl.base@1.0.so" "${2}"
            ;;
        vendor/lib64/vendor.silead.hardware.fingerprintext@1.0.so)
            "${PATCHELF}" --remove-needed "libhidlbase.so" "${2}"
            sed -i "s/libhidltransport.so/libhidlbase-v32.so\x00/" "${2}"
            ;;
        vendor/lib64/com.fingerprints.extension@1.0.so)
            "${PATCHELF}" --remove-needed "libhidlbase.so" "${2}"
            sed -i "s/libhidltransport.so/libhidlbase-v32.so\x00/" "${2}"
            ;;
        system/lib/libcameraservice.so)
            "${PATCHELF}" --add-needed "libmedia_jni_shim.so" "${2}"
            ;;
        system/lib64/libcameraservice.so)
            "${PATCHELF}" --add-needed "libcameraservice_shim.so" "${2}"
            ;;
        system/lib64/android.system.net.netd@1.1.so)
            "${PATCHELF}" --add-needed "libnetd_shim.so" "${2}"
            ;;
        vendor/lib64/vendor.qti.hardware.data.latency@1.0.so)
            "${PATCHELF}" --add-needed "liblatency_shim.so" "${2}"
            ;;
        vendor/lib64/libwvhidl.so)
            "${PATCHELF}" --add-needed "libwvhidl_shim.so" "${2}"
            ;;
        vendor/lib64/vendor.qti.hardware.fm@1.0.so)
            "${PATCHELF}" --add-needed "libfm_shim.so" "${2}"
            ;;
        system/lib64/android.hardware.drm@1.4.so)
            "${PATCHELF}" --add-needed "libdrm_shim.so" "${2}"
            ;;
        apex/com.android.media.swcodec/lib64/libcodec2_hidl@1.0.so)
            "${PATCHELF}" --add-needed "libcodec2_hidl_shim.so" "${2}"
            ;;
        system/lib64/android.hardware.usb.gadget@1.0.so)
            "${PATCHELF}" --add-needed "libgadget_shim.so" "${2}"
            ;;
        vendor/etc/init/qcrild.rc)
            sed -i '4d;11d' "${2}"
            ;;
        vendor/etc/init/dataqti.rc)
            sed -i '19d' "${2}"
            ;;
        system/lib64/libc++.so)
            "${PATCHELF}" --add-needed "libc++_shim.so" "${2}"
            ;;
    esac
}

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    return
fi

set -e

# Required!
export DEVICE=sakura
export DEVICE_COMMON=msm8953-common
export VENDOR=xiaomi

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "$HELPER" ]; then
    echo "Unable to find helper script at $HELPER"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}"/proprietary-files-qc.txt "${SRC}" \
        "${KANG}" --section "${SECTION}"

DEVICE_BLOB_ROOT="${ANDROID_ROOT}"/vendor/"${VENDOR}"/"${DEVICE_COMMON}"/proprietary

# Ims
"${PATCHELF}" --add-needed "lib-imsvt.so" "${DEVICE_BLOB_ROOT}"/system_ext/lib64/lib-imsvideocodec.so

"${MY_DIR}/setup-makefiles.sh"
