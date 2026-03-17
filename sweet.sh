#!/bin/bash

# Terminal Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Repository List: "URL|BRANCH|TARGET_PATH"
REPOS=(
    "https://github.com/rapstuff/device_xiaomi_sweet.git|16-AviumUI|device/xiaomi/sweet"
    "https://github.com/rapstuff/device_xiaomi_sm6150-common.git|16|device/xiaomi/sm6150-common"
    "https://github.com/rapstuff/device_xiaomi_miuicamera-sweet.git|16|device/xiaomi/miuicamera-sweet"
    "https://github.com/rapstuff/vendor_xiaomi_sweet.git|16|vendor/xiaomi/sweet"
    "https://github.com/rapstuff/vendor_xiaomi_sm6150-common.git|16|vendor/xiaomi/sm6150-common"
    "https://github.com/rapstuff/vendor_xiaomi_miuicamera-sweet.git|16|vendor/xiaomi/miuicamera-sweet"
    "https://github.com/rapstuff/kernel_xiaomi_sweet.git|16.0|kernel/xiaomi/sm6150"
    "https://github.com/rapstuff/android_hardware_xiaomi.git|lineage-23.1|hardware/xiaomi"
    "https://github.com/Cilok-LAB/android_hardware_dolby.git|lineage-23.1|hardware/dolby"
)

echo -e "${CYAN}----------------------${NC}"
echo -e "${CYAN}RapStuff Auto Sync    ${NC}"
echo -e "${CYAN}-------${NC}\n"

# ---------------------------------------------------------
# PHASE 1: Detect existing folders
# ---------------------------------------------------------
FOUND_DIRS=()
for entry in "${REPOS[@]}"; do
    IFS="|" read -r url branch path <<< "$entry"
    if [ -d "$path" ]; then
        FOUND_DIRS+=("$path")
    fi
done

# ---------------------------------------------------------
# PHASE 2: One-time wipe confirmation
# ---------------------------------------------------------
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
        # Standard clone to show native progress
        git clone --depth=1 -b "$branch" "$url" "$path"
    fi
done

echo -e "\n${CYAN}-------${NC}"
echo -e "${GREEN}[+] Sync completed successfully!${NC}"
echo -e "${CYAN}---------------------${NC}"
