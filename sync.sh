#!/bin/bash
set -uo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

print_usage() {
    cat <<EOF
Usage: $(basename "$0") [sweet|xun|kj7]

Run from your Android ROM source root directory.
Pass a device codename as an argument, or omit it to pick interactively.
EOF
}

check_dependencies() {
    local missing=()
    local cmd
    for cmd in git curl awk; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}[!] Missing required command(s): ${missing[*]}${NC}"
        exit 1
    fi
}

select_device() {
    local arg="${1:-}"
    case "$arg" in
        -h|--help)
            print_usage
            exit 0
            ;;
        sweet|xun|kj7)
            DEVICE="$arg"
            return
            ;;
        "")
            ;;
        *)
            echo -e "${RED}[!] Unknown device: $arg${NC}"
            print_usage
            exit 1
            ;;
    esac

    local devices=("sweet" "xun" "kj7")
    local labels=(
        "sweet - Xiaomi Redmi Note 10 Pro"
        "xun   - Xiaomi Redmi Pad SE"
        "kj7   - TECNO Spark 20 Pro+"
    )
    local choice

    echo -e "${CYAN}Available devices:${NC}"
    for i in "${!labels[@]}"; do
        echo "$((i + 1))) ${labels[$i]}"
    done

    echo -n -e "\n${YELLOW}Select device (1-${#devices[@]}): ${NC}"
    # Read from /dev/tty so interactive prompts work when piped via curl | bash.
    read -r choice < /dev/tty
    echo ""

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#devices[@]}" ]; then
        DEVICE="${devices[$((choice - 1))]}"
        echo -e "${GREEN}[+] Selected device: $DEVICE${NC}\n"
    else
        echo -e "${RED}[!] Invalid selection.${NC}"
        exit 1
    fi
}

select_branch() {
    local repo_url="$1"
    local default_branch="$2"
    local repo_label="$3"
    local branches=()
    local choice

    echo -e "${YELLOW}[*] Detecting available branches for ${repo_label}...${NC}"
    mapfile -t branches < <(git ls-remote --heads "$repo_url" | awk -F'refs/heads/' '{print $2}')

    if [ ${#branches[@]} -eq 0 ]; then
        echo -e "${RED}[!] Failed to fetch branches. Using default ($default_branch).${NC}\n"
        SELECTED_BRANCH="$default_branch"
        return
    fi

    echo -e "\n${CYAN}Available branches for ${repo_label}:${NC}"
    for i in "${!branches[@]}"; do
        echo "$((i + 1))) ${branches[$i]}"
    done

    echo -n -e "\n${YELLOW}Enter your choice number (1-${#branches[@]}): ${NC}"
    read -r choice < /dev/tty
    echo ""

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#branches[@]}" ]; then
        SELECTED_BRANCH="${branches[$((choice - 1))]}"
        echo -e "${GREEN}[+] Selected branch: $SELECTED_BRANCH${NC}\n"
    else
        SELECTED_BRANCH="$default_branch"
        echo -e "${RED}[!] Invalid input. Using default branch: $SELECTED_BRANCH${NC}\n"
    fi
}

load_device_repos() {
    local branch
    REPOS=()

    case "$DEVICE" in
        sweet)
            select_branch "https://github.com/RapStuff/device_xiaomi_sweet.git" "16-AviumUI" "device_xiaomi_sweet"
            branch="$SELECTED_BRANCH"
            REPOS=(
                "https://github.com/RapStuff/device_xiaomi_sweet.git|${branch}|device/xiaomi/sweet"
                "https://github.com/RapStuff/device_xiaomi_sm6150-common.git|16|device/xiaomi/sm6150-common"
                "https://github.com/RapStuff/device_xiaomi_miuicamera-sweet.git|16|device/xiaomi/miuicamera-sweet"
                "https://github.com/RapStuff/vendor_xiaomi_sweet.git|16|vendor/xiaomi/sweet"
                "https://github.com/RapStuff/vendor_xiaomi_sm6150-common.git|16|vendor/xiaomi/sm6150-common"
                "https://github.com/RapStuff/vendor_xiaomi_miuicamera-sweet.git|16|vendor/xiaomi/miuicamera-sweet"
                "https://github.com/RapStuff/kernel_xiaomi_sweet.git|16.0|kernel/xiaomi/sm6150"
                "https://github.com/RapStuff/android_hardware_xiaomi.git|lineage-23.1|hardware/xiaomi"
                "https://github.com/Cilok-LAB/android_hardware_dolby.git|lineage-23.1|hardware/dolby"
                "https://github.com/SoulEye-sweet/packages_apps_ViPER4AndroidFX.git|bq2|packages/apps/ViPER4AndroidFX"
            )
            ;;
        xun)
            select_branch "https://github.com/RapStuff/android_vendor_xiaomi_xun.git" "16.0" "android_vendor_xiaomi_xun"
            branch="$SELECTED_BRANCH"
            REPOS=(
                "https://github.com/Xiaomi-Redmi-Pad-SE-Resources/android_hardware_qcom-caf_common.git|lineage-23.1|hardware/qcom-caf/common"
                "https://github.com/roms-experimental/android_packages_apps_DolbyAtmos.git|lineage-23.1|packages/apps/DolbyAtmos"
                "https://github.com/Xiaomi-Redmi-Pad-SE-Resources/android_device_qcom_sepolicy_vndr.git|lineage-23.1-caf-sm6225|device/qcom/sepolicy_vndr/sm6225"
                "https://github.com/Xiaomi-Redmi-Pad-SE-Resources/android_vendor_qcom_opensource_agm.git|lineage-23.1-caf-sm6225|hardware/qcom-caf/sm6225/audio/agm"
                "https://github.com/LineageOS/android_vendor_qcom_opensource_audioreach-graphservices.git|lineage-23.1-caf-sm8550|hardware/qcom-caf/sm6225/audio/graphservices"
                "https://github.com/Xiaomi-Redmi-Pad-SE-Resources/android_vendor_qcom_opensource_arpal-lx.git|lineage-23.1-caf-sm6225|hardware/qcom-caf/sm6225/audio/pal"
                "https://github.com/Xiaomi-Redmi-Pad-SE-Resources/android_hardware_qcom_audio-ar.git|lineage-23.1-caf-sm6225|hardware/qcom-caf/sm6225/audio/primary-hal"
                "https://github.com/Xiaomi-Redmi-Pad-SE-Resources/android_vendor_qcom_opensource_data-ipa-cfg-mgr.git|lineage-23.1-caf-sm6225|hardware/qcom-caf/sm6225/data-ipa-cfg-mgr"
                "https://github.com/LineageOS/android_vendor_qcom_opensource_dataipa.git|lineage-23.1-caf-sm8550|hardware/qcom-caf/sm6225/dataipa"
                "https://github.com/Xiaomi-Redmi-Pad-SE-Resources/hardware_qcom_display.git|lineage-23.1-caf-sm6225|hardware/qcom-caf/sm6225/display"
                "https://github.com/Xiaomi-Redmi-Pad-SE-Resources/android_device_xiaomi_sepolicy.git|lineage-22.2|device/xiaomi/sepolicy"
                "https://github.com/roms-experimental/android_hardware_xiaomi.git|lineage-23.1|hardware/xiaomi"
                "https://github.com/RapStuff/android_device_xiaomi_sm6225-common.git|16.0|device/xiaomi/sm6225-common"
                "https://github.com/RapStuff/android_vendor_xiaomi_sm6225-common.git|lineage-22.2|vendor/xiaomi/sm6225-common"
                "https://github.com/RapStuff/android_device_xiaomi_xun.git|16.0|device/xiaomi/xun"
                "https://github.com/RapStuff/android_vendor_xiaomi_xun.git|${branch}|vendor/xiaomi/xun"
                "https://github.com/RapStuff/android_device_xiaomi_xun-kernel.git|16.0|device/xiaomi/xun-kernel"
            )
            ;;
        kj7)
            local mtk_branch
            select_branch "https://github.com/RapStuff/android_device_tecno_kj7.git" "lineage-24.0" "android_device_tecno_kj7"
            branch="$SELECTED_BRANCH"
            select_branch "https://github.com/LineageOS/android_hardware_mediatek.git" "lineage-24.0" "android_hardware_mediatek"
            mtk_branch="$SELECTED_BRANCH"
            REPOS=(
                "https://github.com/RapStuff/android_device_tecno_kj7.git|${branch}|device/tecno/kj7"
                "https://github.com/RapStuff/android_vendor_tecno_kj7.git|lineage-24.0|vendor/tecno/kj7"
                "https://github.com/RapStuff/android_device_tecno_kj7-kernel.git|lineage-24.0|device/tecno/TECNO-KJ7-kernel"
                "https://github.com/RapStuff/android_device_leica_kj7.git|main|vendor/tecno/leicacamera"
                "https://github.com/LineageOS/android_hardware_mediatek.git|${mtk_branch}|hardware/mediatek"
            )
            ;;
    esac
}

handle_existing_dirs() {
    local found_dirs=()
    local entry url branch path dir confirm target

    for entry in "${REPOS[@]}"; do
        IFS="|" read -r url branch path <<< "$entry"
        if [ -d "$path" ]; then
            found_dirs+=("$path")
        fi
    done

    if [ ${#found_dirs[@]} -eq 0 ]; then
        return
    fi

    echo -e "${YELLOW}[!] Existing directories found:${NC}"
    for dir in "${found_dirs[@]}"; do
        echo -e "    - $dir"
    done
    echo ""

    echo -n -e "${YELLOW}Wipe all existing directories above? (y/n): ${NC}"
    read -n 1 -r confirm < /dev/tty
    echo -e "\n"

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${RED}[-] Wiping directories...${NC}"
        for target in "${found_dirs[@]}"; do
            rm -rf "$target"
            echo -e "    Deleted: $target"
        done
        echo -e "${GREEN}[+] Wipe complete.${NC}\n"
    else
        echo -e "${YELLOW}[i] Wipe skipped. Existing folders will not be cloned again.${NC}\n"
    fi
}

clone_repos() {
    local entry url branch path
    local failed=0

    echo -e "${CYAN}--- Starting Git Clone ---${NC}"
    for entry in "${REPOS[@]}"; do
        IFS="|" read -r url branch path <<< "$entry"

        if [ -d "$path" ]; then
            echo -e "${YELLOW}[*] Skipped: $path already exists.${NC}"
        else
            echo -e "\n${GREEN}[+] Cloning [$branch] into $path...${NC}"
            if ! git clone --depth=1 -b "$branch" "$url" "$path"; then
                echo -e "${RED}[!] Failed to clone $url ($branch) into $path.${NC}"
                failed=1
            fi
        fi
    done

    if [ "$failed" -ne 0 ]; then
        echo -e "\n${RED}[!] One or more repositories failed to clone.${NC}"
        exit 1
    fi
}

setup_ksu_sweet() {
    local kernel_dir="kernel/xiaomi/sm6150"
    local ksu_confirm

    echo -e "\n${CYAN}--- KernelSU Integration ---${NC}"
    if [ ! -d "$kernel_dir" ]; then
        echo -e "${RED}[!] Kernel directory ($kernel_dir) not found. Skipping KernelSU-Next integration.${NC}"
        return
    fi

    echo -n -e "${YELLOW}Do you want to integrate KernelSU-Next (hookless)? (y/n): ${NC}"
    read -n 1 -r ksu_confirm < /dev/tty
    echo -e "\n"

    if [[ "$ksu_confirm" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}[+] Integrating KernelSU-Next into $kernel_dir...${NC}"
        if (
            cd "$kernel_dir" &&
            curl -LSs "https://raw.githubusercontent.com/Sorayukii/KernelSU-Next/stable/kernel/setup.sh" | bash -s hookless
        ); then
            echo -e "${GREEN}[+] KernelSU-Next integration complete.${NC}"
        else
            echo -e "${RED}[!] KernelSU-Next integration failed.${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}[i] KernelSU-Next integration skipped.${NC}"
    fi
}

setup_xun_links() {
    # Android QCOM CAF HALs require top-level pickup makefiles linked from qcom-caf/common.
    local links=(
        "os_pickup_aosp.mk|hardware/qcom/Android.mk"
        "os_pickup_sepolicy_vndr.mk|device/qcom/sepolicy_vndr/SEPolicy.mk"
        "os_pickup_qssi.bp|hardware/qcom-caf/msm8953/Android.bp"
        "os_pickup.bp|hardware/qcom-caf/msm8998/Android.bp"
        "os_pickup_qssi.bp|hardware/qcom-caf/sdm660/Android.bp"
        "os_pickup_qssi.bp|hardware/qcom-caf/sdm845/Android.bp"
        "os_pickup_qssi.bp|hardware/qcom-caf/sm6225/Android.bp"
        "os_pickup_qssi.bp|hardware/qcom-caf/sm8150/Android.bp"
        "os_pickup_qssi.bp|hardware/qcom-caf/sm8250/Android.bp"
        "os_pickup_qssi.bp|hardware/qcom-caf/sm8350/Android.bp"
        "os_pickup_qssi.bp|hardware/qcom-caf/sm8450/Android.bp"
        "os_pickup_qssi.bp|hardware/qcom-caf/sm8550/Android.bp"
        "os_pickup_qssi.bp|hardware/qcom-caf/sm8650/Android.bp"
        "os_pickup_qssi.bp|hardware/qcom-caf/sm8750/Android.bp"
    )
    local entry src_rel dest_rel src_file dest_file dest_dir

    echo -e "\n${CYAN}--- Creating Linkfiles (Symlinks) ---${NC}"
    for entry in "${links[@]}"; do
        IFS="|" read -r src_rel dest_rel <<< "$entry"
        src_file="$PWD/hardware/qcom-caf/common/$src_rel"
        dest_file="$PWD/$dest_rel"
        dest_dir="$(dirname "$dest_file")"

        if [ -f "$src_file" ]; then
            mkdir -p "$dest_dir"
            ln -sf "$src_file" "$dest_file"
            echo -e "${GREEN}[+] Linked:${NC} $dest_file -> $src_file"
        else
            echo -e "${RED}[!] Source missing:${NC} $src_file"
        fi
    done
}

run_post_sync() {
    case "$DEVICE" in
        sweet)
            setup_ksu_sweet
            ;;
        xun)
            setup_xun_links
            ;;
    esac
}

main() {
    check_dependencies

    echo -e "${CYAN}--------------------------${NC}"
    echo -e "${CYAN}RapStuff Auto Sync        ${NC}"
    echo -e "${CYAN}--------------------------${NC}\n"

    select_device "${1:-}"
    load_device_repos
    handle_existing_dirs
    clone_repos
    run_post_sync

    echo -e "\n${CYAN}--------------------------${NC}"
    echo -e "${GREEN}[+] Sync completed successfully!${NC}"
    echo -e "${CYAN}--------------------------${NC}"
}

main "$@"
