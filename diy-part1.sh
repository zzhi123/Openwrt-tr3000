#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
# echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
#echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default

# Add OpenClash
rm -rf package/luci-app-openclash /tmp/OpenClash

git clone --depth 1 \
  --filter=blob:none \
  --sparse \
  --branch master \
  https://github.com/vernesong/OpenClash.git \
  /tmp/OpenClash

git -C /tmp/OpenClash sparse-checkout set luci-app-openclash

cp -a /tmp/OpenClash/luci-app-openclash package/

rm -rf /tmp/OpenClash
