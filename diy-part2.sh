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

# Replace the older OpenClash package from the ImmortalWrt LuCI feed with the
# latest upstream package on every build. This keeps only the LuCI package
# source in the firmware; the Mihomo core remains user-managed.
rm -rf package/feeds/luci/luci-app-openclash package/OpenClash
for attempt in 1 2 3; do
    rm -rf package/OpenClash
    if timeout 300 git clone --branch master --single-branch --depth 1 \
        --filter=blob:none --sparse \
        https://github.com/vernesong/OpenClash.git package/OpenClash && \
        timeout 300 git -C package/OpenClash sparse-checkout set \
        luci-app-openclash; then
        break
    fi
    [ "$attempt" -lt 3 ] || {
        echo "Unable to download the latest OpenClash source" >&2
        exit 1
    }
done
test -f package/OpenClash/luci-app-openclash/Makefile
echo "OpenClash source: $(git -C package/OpenClash rev-parse HEAD)"
grep -E '^(PKG_VERSION|PKG_RELEASE):=' \
    package/OpenClash/luci-app-openclash/Makefile || true

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
