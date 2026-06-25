#!/usr/bin/env bash
# install.sh — Installs Harmony-Music on a connected Android device via ADB.
#
# Usage:
#   ./install.sh                  # auto-detects device ABI and installs
#   ./install.sh --apk <file>     # installs a specific APK
#   ./install.sh --check          # just checks if the device is connected

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Defaults
APK_FILE=""
CHECK_ONLY=false

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --apk)
      APK_FILE="$2"
      shift 2
      ;;
    --check)
      CHECK_ONLY=true
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [--apk <file>] [--check]"
      echo "  --apk <file>   Install a specific APK instead of auto-detecting"
      echo "  --check        Only check device connection and ABI"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown argument: $1${NC}"
      exit 1
      ;;
  esac
done

# Check adb
if ! command -v adb &> /dev/null; then
  echo -e "${RED}Error: adb not found.${NC}"
  echo "Install Android Platform Tools: https://developer.android.com/studio/releases/platform-tools"
  exit 1
fi

# Check device
echo -e "${CYAN}Checking for connected devices...${NC}"
DEVICES=$(adb devices | grep -E "device$" | awk '{print $1}')

if [[ -z "$DEVICES" ]]; then
  echo -e "${RED}No device connected.${NC}"
  echo "Connect a device with USB debugging enabled, then try again."
  exit 1
fi

DEVICE_COUNT=$(echo "$DEVICES" | wc -l)
echo -e "${GREEN}Found $DEVICE_COUNT device(s):${NC}"
echo "$DEVICES" | sed 's/^/  /'

# Check ABI if we need to auto-detect
if [[ -z "$APK_FILE" ]]; then
  echo ""
  echo -e "${CYAN}Detecting device ABI...${NC}"
  ABI=$(adb shell getprop ro.product.cpu.abi)
  echo "  ABI: $ABI"

  # Map ABI to APK file
  case "$ABI" in
    arm64-v8a)
      APK_FILE="Harmony-Music-v1.12.2-arm64-v8a.apk"
      ;;
    armeabi-v7a)
      APK_FILE="Harmony-Music-v1.12.2-armeabi-v7a.apk"
      ;;
    x86_64)
      APK_FILE="Harmony-Music-v1.12.2-x86_64.apk"
      ;;
    *)
      echo -e "${YELLOW}Unknown ABI '$ABI', falling back to universal APK${NC}"
      APK_FILE="Harmony-Music-v1.12.2-universal-release.apk"
      ;;
  esac
fi

# Resolve APK path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APK_PATH="$SCRIPT_DIR/$APK_FILE"

if [[ ! -f "$APK_PATH" ]]; then
  echo -e "${RED}APK not found: $APK_PATH${NC}"
  echo "Available APKs in this directory:"
  ls "$SCRIPT_DIR"/*.apk 2>/dev/null | sed 's/^/  /' || echo "  (none)"
  exit 1
fi

echo ""
echo -e "${CYAN}APK to install:${NC}"
echo "  $APK_FILE ($(du -h "$APK_PATH" | awk '{print $1}'))"

if [[ "$CHECK_ONLY" == true ]]; then
  echo ""
  echo -e "${GREEN}Device check passed.${NC}"
  exit 0
fi

# Confirm
echo ""
read -p "Install on connected device? [y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# Install
echo ""
echo -e "${CYAN}Installing...${NC}"
adb install -r "$APK_PATH"

echo ""
echo -e "${GREEN}✓ Installed successfully.${NC}"
echo ""
echo "Launching app..."
adb shell am start -n com.anandnet.harmonymusic/.MainActivity 2>/dev/null || echo "(launch command may have failed, try opening the app manually)"

echo ""
echo "Done. If something went wrong, run: adb logcat | grep -i harmony"
