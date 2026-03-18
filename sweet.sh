#!/bin/bash

# Terminal Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}----------------------${NC}"
echo -e "${CYAN}RapStuff Auto Sync    ${NC}"
echo -e "${CYAN}-------${NC}\n"

# ---------------------------------------------------------
# PHASE 0: Auto-Detect Branch for device_xiaomi_sweet
# ---------------------------------------------------------
SWEET_URL="https://github.com/rapstuff/device_xiaomi_sweet.git"
echo -e "${YELLOW}[*] Detecting available branches for device_xiaomi_sweet...${NC}"

# Fetch the list of branches directly from GitHub
mapfile -t AVAILABLE_BRANCHES < <(git ls-remote --heads "$SWEET_URL" | awk -F'refs/heads/' '{print $2}')

if [ ${#AVAILABLE_BRANCHES[@]} -eq 0 ]; then
    echo -e "${RED}[!] Failed to fetch branches or repository is empty. Using default (16-AviumUI).${NC}"
    SWEET_BRANCH="16-AviumUI"
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
        SWEET_BRANCH="${AVAILABLE_BRANCHES[$idx]}"
        echo -e "${GREEN}[+] Selected branch: $SWEET_BRANCH${NC}\n"
    else
        SWEET_BRANCH="16-AviumUI"
        echo -e "${RED}[!] Invalid input. Using default branch: $SWEET_BRANCH${NC}\n"
    fi
fi

# ---------------------------------------------------------
# Repository List: "URL|BRANCH|TARGET_PATH"
# ---------------------------------------------------------
REPOS=(
    "https://github.com/rapstuff/device_xiaomi_sweet.git|${SWEET_BRANCH}|device/xiaomi/sweet"
    "https://github.com/rapstuff/device_xiaomi_sm6150-common.git|16|device/xiaomi/sm6150-common"
    "https://github.com/rapstuff/device_xiaomi_miuicamera-sweet.git|16|device/xiaomi/miuicamera-sweet"
    "https://github.com/rapstuff/vendor_xiaomi_sweet.git|16|vendor/xiaomi/sweet"
    "https://github.com/rapstuff/vendor_xiaomi_sm6150-common.git|16|vendor/xiaomi/sm6150-common"
    "https://github.com/rapstuff/vendor_xiaomi_miuicamera-sweet.git|16|vendor/xiaomi/miuicamera-sweet"
    "https://github.com/rapstuff/kernel_xiaomi_sweet.git|16.0|kernel/xiaomi/sm6150"
    "https://github.com/rapstuff/android_hardware_xiaomi.git|lineage-23.1|hardware/xiaomi"
    "https://github.com/Cilok-LAB/android_hardware_dolby.git|lineage-23.1|hardware/dolby"
    "https://github.com/SoulEye-sweet/packages_apps_ViPER4AndroidFX.git|bq2|packages/apps/ViPER4AndroidFX"
)

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
        git clone --depth=1 -b "$branch" "$url" "$path"
    fi
done

# ---------------------------------------------------------
# PHASE 4: KernelSU-Next Integration
# ---------------------------------------------------------
KERNEL_DIR="kernel/xiaomi/sm6150"

echo -e "\n${CYAN}--- KernelSU Integration ---${NC}"
if [ -d "$KERNEL_DIR" ]; then
    echo -n -e "${YELLOW}Do you want to integrate KernelSU-Next (hookless)? (y/n): ${NC}"
    read -n 1 -r ksu_confirm < /dev/tty
    echo -e "\n"

    if [[ "$ksu_confirm" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}[+] Integrating KernelSU-Next into $KERNEL_DIR...${NC}"
        pushd "$KERNEL_DIR" > /dev/null || exit
        curl -LSs "https://raw.githubusercontent.com/Sorayukii/KernelSU-Next/stable/kernel/setup.sh" | bash -s hookless
        popd > /dev/null || exit
        echo -e "${GREEN}[+] KernelSU-Next integration complete.${NC}"
    else
        echo -e "${YELLOW}[i] KernelSU-Next integration skipped.${NC}"
    fi
else
    echo -e "${RED}[!] Kernel directory ($KERNEL_DIR) not found. Skipping KernelSU-Next integration.${NC}"
fi

echo -e "\n${CYAN}-------${NC}"
echo -e "${GREEN}[+] Sync completed successfully!${NC}"
echo -e "${CYAN}---------------------${NC}"
