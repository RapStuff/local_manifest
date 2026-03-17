#!/bin/bash

# Terminal color codes for output formatting
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Repository configuration: "URL|BRANCH|TARGET_PATH"
REPOS=(
    "https://github.com/rapstuff/device_xiaomi_sweet.git|16|device/xiaomi/sweet"
    "https://github.com/rapstuff/device_xiaomi_sm6150-common.git|16|device/xiaomi/sm6150-common"
    "https://github.com/rapstuff/device_xiaomi_miuicamera-sweet.git|16|device/xiaomi/miuicamera-sweet"
    "https://github.com/rapstuff/vendor_xiaomi_sweet.git|16|vendor/xiaomi/sweet"
    "https://github.com/rapstuff/vendor_xiaomi_sm6150-common.git|16|vendor/xiaomi/sm6150-common"
    "https://github.com/rapstuff/vendor_xiaomi_miuicamera-sweet.git|16|vendor/xiaomi/miuicamera-sweet"
    "https://github.com/rapstuff/kernel_xiaomi_sweet.git|16.0|kernel/xiaomi/sm6150"
    "https://github.com/rapstuff/android_hardware_xiaomi.git|lineage-23.1|hardware/xiaomi"
)

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}      Android Repository Synchronization Utility    ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# ---------------------------------------------------------
# Phase 1: Bulk Cleanup Detection
# ---------------------------------------------------------
FOUND_DIRS=()
for entry in "${REPOS[@]}"; do
    IFS="|" read -r url branch path <<< "$entry"
    if [ -d "$path" ]; then
        FOUND_DIRS+=("$path")
    fi
done

if [ ${#FOUND_DIRS[@]} -gt 0 ]; then
    echo -e "${YELLOW}[!] Detected ${#FOUND_DIRS[@]} existing target directories:${NC}"
    for dir in "${FOUND_DIRS[@]}"; do
        echo -e "    - $dir"
    done
    echo ""
    # Defaults to 'No' (N) for safety
    read -p "Do you want to PERMANENTLY DELETE all listed directories before cloning? (y/N): " clean_all

    if [[ "$clean_all" =~ ^[Yy]$ ]]; then
        echo -e "\n${RED}[-] Initiating bulk deletion...${NC}"
        for target in "${FOUND_DIRS[@]}"; do
            rm -rf "$target"
            echo -e "    Deleted: $target"
        done
        echo -e "${GREEN}[+] Bulk cleanup completed successfully.${NC}\n"
    else
        echo -e "\n${YELLOW}[i] Bulk cleanup bypassed. Proceeding to individual repository operations...${NC}\n"
    fi
fi

# ---------------------------------------------------------
# Phase 2: Synchronization / Cloning
# ---------------------------------------------------------
echo -e "${BLUE}--- Processing Repositories ---${NC}"
for entry in "${REPOS[@]}"; do
    IFS="|" read -r url branch path <<< "$entry"
    
    if [ -d "$path" ]; then
        echo -e "\n${YELLOW}[!] Directory exists:${NC} $path"
        echo -n -e "    Select action ( ${GREEN}[u]pdate${NC} | ${RED}[d]elete & re-clone${NC} | ${NC}[s]kip${NC} ): "
        read -n 1 action
        echo -e ""

        case $action in
            [Uu]* )
                echo -e "    [*] Updating $path..."
                # Added error handling: only run git commands if cd is successful
                if cd "$path"; then
                    git fetch --all --quiet
                    git reset --hard "origin/$branch" --quiet
                    cd - > /dev/null || exit
                    echo -e "    ${GREEN}[+] Update completed.${NC}"
                else
                    echo -e "    ${RED}[-] Failed to access directory. Skipping.${NC}"
                fi
                ;;
            [Dd]* )
                echo -e "    [*] Removing and re-cloning..."
                rm -rf "$path"
                git clone --depth=1 --quiet -b "$branch" "$url" "$path"
                echo -e "    ${GREEN}[+] Re-clone completed.${NC}"
                ;;
            * )
                echo -e "    [*] Skipped."
                ;;
        esac
    else
        echo -e "\n${RED}[?] Directory not found:${NC} $path"
        echo -e "    [*] Cloning branch [$branch]..."
        git clone --depth=1 --quiet -b "$branch" "$url" "$path"
        echo -e "    ${GREEN}[+] Clone completed.${NC}"
    fi
done

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${GREEN}[+] All target repositories have been successfully processed.${NC}"
echo -e "${BLUE}====================================================${NC}"
