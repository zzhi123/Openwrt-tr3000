#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

set -euo pipefail

# Keep the clean system on the same LAN subnet used by this router.
# Use a targeted replacement so an upstream layout change makes the build fail
# instead of silently producing firmware with an unexpected management address.
config_generate="package/base-files/files/bin/config_generate"
grep -q 'lan) ipad=${ipaddr:-"192.168.1.1"} ;;' "$config_generate" || {
    echo "Unable to find the official default LAN address definition" >&2
    exit 1
}
cp "$config_generate" "${config_generate}.tmp"
sed 's/lan) ipad=${ipaddr:-"192.168.1.1"} ;;/lan) ipad=${ipaddr:-"192.168.6.1"} ;;/' \
    "$config_generate" > "${config_generate}.tmp"
mv "${config_generate}.tmp" "$config_generate"

# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate

# Keep the first official ImmortalWrt build free of source-level customizations.
