#!/bin/bash

# Terminal Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}----------------------------${NC}"
echo -e "${CYAN}RapStuff Auto Sync (Xun)    ${NC}"
echo -e "${CYAN}----------------------------${NC}\n"

# ---------------------------------------------------------
# PHASE 0: Auto-Detect Branch for android_device_xiaomi_xun
# ---------------------------------------------------------
XUN_URL="https://github.com/RapStuff/android_device_xiaomi_xun.git"
echo -e "${YELLOW}[*] Detecting available branches for android_device_xiaomi_xun...${NC}"

# Fetch the list of branches directly from GitHub
mapfile -t AVAILABLE_BRANCHES < <(git ls-remote --heads "$XUN_URL" | awk -F'refs/heads/' '{print $2}')

if [ ${#AVAILABLE_BRANCHES[@]} -eq 0 ]; then
    echo -e "${RED}[!] Failed to fetch branches or repository is empty. Using default (lineage-23.1).${NC}"
    XUN_BRANCH="lineage-23.1"
else
    echo -e "\n${CYAN}Available branches:${NC}"
    for i in "${!AVAILABLE_BRANCHES[@]}"; do
        echo "$((i+1))) ${AVAILABLE_BRANCHES[$i]}"
    done
    
    echo -n -e "\n${YELLOW}Enter your choice number (1-${#AVAILABLE_BRANCHES[@]}): ${NC}"
    read -r branch_choice < /dev/tty
    echo -e "\n"
    
    # Validate numeric input
    if [[ "$branch_choice" =~ ^[0-9]+$ ]] && [ "$branch_choice" -ge 1 ] && [ "$branch_choice" -le "${#AVAILABLE_BRANCHES[@]}" ]; then
        idx=$((branch_choice-1))
        XUN_BRANCH="${AVAILABLE_BRANCHES[$idx]}"
        echo -e "${GREEN}[+] Selected branch: $XUN_BRANCH${NC}\n"
    else
        XUN_BRANCH="lineage-23.1"
        echo -e "${RED}[!] Invalid input. Using default branch: $XUN_BRANCH${NC}\n"
    fi
fi

# ---------------------------------------------------------
# PHASE 1: Repository List -> "URL|BRANCH|TARGET_PATH"
# ---------------------------------------------------------
REPOS=(
    # QCOM & Dolby Trees
    "https://github.com/Xiaomi-Redmi-Pad-SE-Resources/android_hardware_qcom-caf_common.git|lineage-23.1|hardware/qcom-caf/common"
    "https://github.com/roms-experimental/android_packages_apps_DolbyAtmos.git|lineage-23.1|packages/apps/DolbyAtmos"
    
    # QCOM Audio, Display, & Data
    "https://github.com/Xiaomi-Redmi-Pad-SE-Resources/android_device_qcom_sepolicy_vndr.git|lineage-23.1-caf-sm6225|device/qcom/sepolicy_vndr/sm6225"
    "https://github.com/Xiaomi-Redmi-Pad-SE-Resources/android_vendor_qcom_opensource_agm.git|lineage-23.1-caf-sm6225|hardware/qcom-caf/sm6225/audio/agm"
    "https://github.com/LineageOS/android_vendor_qcom_opensource_audioreach-graphservices.git|lineage-23.1-caf-sm8550|hardware/qcom-caf/sm6225/audio/graphservices"
    "https://github.com/Xiaomi-Redmi-Pad-SE-Resources/android_vendor_qcom_opensource_arpal-lx.git|lineage-23.1-caf-sm6225|hardware/qcom-caf/sm6225/audio/pal"
    "https://github.com/Xiaomi-Redmi-Pad-SE-Resources/android_hardware_qcom_audio-ar.git|lineage-23.1-caf-sm6225|hardware/qcom-caf/sm6225/audio/primary-hal"
    "https://github.com/Xiaomi-Redmi-Pad-SE-Resources/android_vendor_qcom_opensource_data-ipa-cfg-mgr.git|lineage-23.1-caf-sm6225|hardware/qcom-caf/sm6225/data-ipa-cfg-mgr"
    "https://github.com/LineageOS/android_vendor_qcom_opensource_dataipa.git|lineage-23.1-caf-sm8550|hardware/qcom-caf/sm6225/dataipa"
    "https://github.com/Xiaomi-Redmi-Pad-SE-Resources/hardware_qcom_display.git|lineage-23.1-caf-sm6225|hardware/qcom-caf/sm6225/display"

    # RapStuff Trees (Xiaomi & Xun)
    "https://github.com/RapStuff/android_hardware_xiaomi.git|lineage-23.1|hardware/xiaomi"
    "https://github.com/RapStuff/android_device_xiaomi_sm6225-common.git|lineage-23.1|device/xiaomi/sm6225-common"
    "https://github.com/RapStuff/android_vendor_xiaomi_sm6225-common.git|lineage-23.1|vendor/xiaomi/sm6225-common"
    "https://github.com/RapStuff/android_device_xiaomi_xun.git|${XUN_BRANCH}|device/xiaomi/xun"
    "https://github.com/RapStuff/android_vendor_xiaomi_xun.git|lineage-23.1|vendor/xiaomi/xun"
    "https://github.com/RapStuff/android_device_xiaomi_xun-kernel.git|lineage-23.1|device/xiaomi/xun-kernel"
)

# ---------------------------------------------------------
# PHASE 2: Detect existing folders & Wipe confirmation
# ---------------------------------------------------------
FOUND_DIRS=()
for entry in "${REPOS[@]}"; do
    IFS="|" read -r url branch path <<< "$entry"
    if [ -d "$path" ]; then
        FOUND_DIRS+=("$path")
    fi
done

if [ ${#FOUND_DIRS[@]} -gt 0 ]; then
    echo -e "${YELLOW}[!] Existing directories found:${NC}"
    for dir in "${FOUND_DIRS[@]}"; do
        echo -e "    - $dir"
    done
    echo ""
    
    # Read from /dev/tty for direct 'curl | bash' support
    echo -n -e "${YELLOW}Wipe all existing directories above? (y/n): ${NC}"
    read -n 1 -r confirm < /dev/tty
    echo -e "\n"

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${RED}[-] Wiping directories...${NC}"
        for target in "${FOUND_DIRS[@]}"; do
            rm -rf "$target"
            echo -e "    Deleted: $target"
        done
        echo -e "${GREEN}[+] Wipe complete.${NC}\n"
    else
        echo -e "${YELLOW}[i] Wipe skipped. Existing folders will not be cloned again.${NC}\n"
    fi
fi

# ---------------------------------------------------------
# PHASE 3: Git Clone execution
# ---------------------------------------------------------
echo -e "${CYAN}--- Starting Git Clone ---${NC}"
for entry in "${REPOS[@]}"; do
    IFS="|" read -r url branch path <<< "$entry"
    
    if [ -d "$path" ]; then
        echo -e "${YELLOW}[*] Skipped: $path already exists.${NC}"
    else
        echo -e "\n${GREEN}[+] Cloning [$branch] into $path...${NC}"
        git clone --depth=1 -b "$branch" "$url" "$path"
    fi
done

# ---------------------------------------------------------
# PHASE 4: Create Linkfiles (Symlinks)
# ---------------------------------------------------------
echo -e "\n${CYAN}--- Creating Linkfiles (Symlinks) ---${NC}"

create_linkfile() {
    local src_file="$PWD/hardware/qcom-caf/common/$1"
    local dest_file="$PWD/$2"
    local dest_dir=$(dirname "$dest_file")

    if [ -f "$src_file" ]; then
        mkdir -p "$dest_dir"
        ln -sf "$src_file" "$dest_file"
        echo -e "${GREEN}[+] Linked:${NC} $dest_file -> $src_file"
    else
        echo -e "${RED}[!] Source missing:${NC} $src_file"
    fi
}

create_linkfile "os_pickup_aosp.mk" "hardware/qcom/Android.mk"
create_linkfile "os_pickup_sepolicy_vndr.mk" "device/qcom/sepolicy_vndr/SEPolicy.mk"
create_linkfile "os_pickup_qssi.bp" "hardware/qcom-caf/msm8953/Android.bp"
create_linkfile "os_pickup.bp" "hardware/qcom-caf/msm8998/Android.bp"
create_linkfile "os_pickup_qssi.bp" "hardware/qcom-caf/sdm660/Android.bp"
create_linkfile "os_pickup_qssi.bp" "hardware/qcom-caf/sdm845/Android.bp"
create_linkfile "os_pickup_qssi.bp" "hardware/qcom-caf/sm6225/Android.bp"
create_linkfile "os_pickup_qssi.bp" "hardware/qcom-caf/sm8150/Android.bp"
create_linkfile "os_pickup_qssi.bp" "hardware/qcom-caf/sm8250/Android.bp"
create_linkfile "os_pickup_qssi.bp" "hardware/qcom-caf/sm8350/Android.bp"
create_linkfile "os_pickup_qssi.bp" "hardware/qcom-caf/sm8450/Android.bp"
create_linkfile "os_pickup_qssi.bp" "hardware/qcom-caf/sm8550/Android.bp"
create_linkfile "os_pickup_qssi.bp" "hardware/qcom-caf/sm8650/Android.bp"
create_linkfile "os_pickup_qssi.bp" "hardware/qcom-caf/sm8750/Android.bp"

echo -e "\n${CYAN}------------------------------------${NC}"
echo -e "${GREEN}[+] Sync & Setup completed successfully!${NC}"
echo -e "${CYAN}------------------------------------${NC}"
