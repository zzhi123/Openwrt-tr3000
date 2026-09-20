**English** | [中文](https://p3terx.com/archives/build-openwrt-with-github-actions.html)

## TR3000 122M / ImmortalWrt 25.12 branch

The branch 'immortalwrt-official-25.12.2-122m' builds the latest formal
ImmortalWrt 25.12 release currently selected here: source tag 'v25.12.2'.
It adds a small TR3000 legacy profile for the weekdaycare multi-layout U-Boot:

- UBI starts at '0x5c0000' and is '0x7a40000' bytes ('125184 KiB',
  122.25 MiB). The U-Boot layout must be explicitly selected as '122m'
  (or 'mtd_layout_label=122m') before using this image; a 112m/default
  layout is not compatible.
- The first move from the existing 112M system must be done in the
  weekdaycare U-Boot uploader/failsafe after changing and saving the U-Boot
  layout to 122m. Do not upload this image through the old running system's
  LuCI/sysupgrade path: its old board/upgrade handler is a different 112M
  contract. Once this image has booted as 'cudy,tr3000-v1-122m', later
  same-profile upgrades use the normal legacy NAND path.
- The output is the traditional
  'cudy_tr3000-v1-122m-squashfs-sysupgrade.bin'. It is **not** the official
  FIT/'sysupgrade.itb' migration image. The official 25.12 'ubootmod' ITB
  requires its matching BL2/preloader, FIP, UBI environment and boot layout.
- The image keeps the package set from the 24.10 build: LuCI, Argon,
  OpenClash (pinned at 'v0.47.156'), ttyd, OpenSSH SFTP, USB networking,
  'mtd', and 'kmod-mtd-rw'. The last module only unlocks protected MTD
  partitions when deliberately performing a bootloader/FIP operation; it does
  not flash a bootloader by itself. Loading it or writing BL2/FIP is not part
  of an ordinary 122M firmware upgrade and can permanently brick the device.

### Switching to another 25.x release

To build a different formal 25.x release, change the source tag in both
'.github/workflows/openwrt-builder.yml' and '.github/workflows/update-checker.yml',
then update the label in '.github/workflows/openwrt-builder.yml':

```yaml
REPO_BRANCH: v25.12.2       # e.g. v25.12.1 or v25.12.0
FIRMWARE_LABEL: immortalwrt-official-25.12.2-122m
```

Also change the branch name and the dispatch ref in
'.github/workflows/update-checker.yml' if you create a separate branch. Keep
the 122M patch and the 'cudy_tr3000-v1-122m' target unchanged. After changing
versions, the build must be completed and its manifest/image geometry audited
before flashing.

Before changing the U-Boot layout, back up BL2, FIP, Factory, bdinfo, and the
UBI partition. A 122M legacy '.bin' must not be confused with the official FIT
'.itb' migration.

### 中文操作说明

本分支的目标是 **ImmortalWrt 25.12.2 正式版 + weekdaycare 多布局 U-Boot 的
legacy 122M 布局**。这里的 122M 不是官方 `ubootmod` FIT 布局：

版本与布局依据：[ImmortalWrt 25.12.2 官方下载目录](https://downloads.immortalwrt.org/releases/25.12.2/targets/mediatek/filogic/)、[weekdaycare TR3000 构建说明](https://github.com/weekdaycare/immortalwrt-mt7981-cudy-tr3000) 和 [weekdaycare DHCP U-Boot 说明](https://github.com/weekdaycare/bl-mt798x-dhcpd)。

```text
UBI 起点：0x5c0000
UBI 大小：0x7a40000 = 125184 KiB = 122.25 MiB
卷结构：kernel / rootfs / rootfs_data
升级包：cudy_tr3000-v1-122m-squashfs-sysupgrade.bin
```

首次从当前 112M 系统迁移时，必须在 weekdaycare U-Boot 的 failsafe/uploader
中选择并保存 `122m` 布局，再写入本分支的 `.bin`；不能从旧 112M 系统的
LuCI 页面直接刷这个首个迁移镜像。切换前应至少备份完整 NAND，以及
`BL2`、`FIP`、`Factory`、`bdinfo`、`u-boot-env` 和现有 `ubi`。刷写前在
U-Boot 控制台确认 `mtd_layout_label=122m`（或等效的 122m 环境变量），
并确认 `/getmtdlayout` 显示 122m。**不要把官方的
`cudy_tr3000-v1-ubootmod-squashfs-sysupgrade.itb` 给这个 legacy U-Boot。**
仅仅来自同一个 GitHub 仓库并不能证明路由器已经安装了相同的 U-Boot；如果
failsafe 没有列出并能保存 `122m`，应先停止，不要刷这个镜像。

软件包按 24.10.6 分支的选择保留了 LuCI、Argon、ttyd、OpenSSH SFTP、USB
网络驱动和 OpenClash；OpenClash 在 25.12 分支有意更新为当前最新的
`v0.47.156`（24.10.6 是 `v0.47.133`），不是遗漏。如果必须严格复刻旧版
OpenClash，把 `diy-part2.sh` 中的 tag 改为 `v0.47.133` 后重新编译。额外的
`mtd` 与 `kmod-mtd-rw` 只是为你提到的 FIP/MTD 维护命令提供工具；它们不会
自动刷写 U-Boot。不要在普通升级中加载 `mtd-rw` 或写入 BL2/FIP。

ImmortalWrt 25.12 使用 APK 包管理，不能把 24.10 的旧 ipk 文件直接恢复到
新系统；可以恢复配置，但软件包要由本固件或 25.12 的软件源重新安装。

ImmortalWrt 使用完整 tag 名称，而不是把版本写成 `25.1` 或 `25.0`。例如
25.12 系列应写成 `v25.12.0`、`v25.12.1` 或 `v25.12.2`；如果以后出现
新的正式 tag，必须同时修改两个 workflow 的 `REPO_BRANCH`、构建标签以及
（若另建分支）`update-checker.yml` 的 dispatch `ref`。换到不同的主版本时，
还要重新执行 patch 的 `git apply --check`、确认 122M DTS/升级处理器和包
依赖仍适用，不能只改一个版本字符串就直接刷写。

# Actions-OpenWrt

[![LICENSE](https://img.shields.io/github/license/mashape/apistatus.svg?style=flat-square&label=LICENSE)](https://github.com/P3TERX/Actions-OpenWrt/blob/master/LICENSE)
![GitHub Stars](https://img.shields.io/github/stars/P3TERX/Actions-OpenWrt.svg?style=flat-square&label=Stars&logo=github)
![GitHub Forks](https://img.shields.io/github/forks/P3TERX/Actions-OpenWrt.svg?style=flat-square&label=Forks&logo=github)

A template for building OpenWrt with GitHub Actions

## Usage

- Click the [Use this template](https://github.com/P3TERX/Actions-OpenWrt/generate) button to create a new repository.
- Generate `.config` files using [Lean's OpenWrt](https://github.com/coolsnowwolf/lede) source code. ( You can change it through environment variables in the workflow file. )
- Push `.config` file to the GitHub repository.
- Select `Build OpenWrt` on the Actions page.
- Click the `Run workflow` button.
- When the build is complete, click the `Artifacts` button in the upper right corner of the Actions page to download the binaries.

## Tips

- It may take a long time to create a `.config` file and build the OpenWrt firmware. Thus, before create repository to build your own firmware, you may check out if others have already built it which meet your needs by simply [search `Actions-Openwrt` in GitHub](https://github.com/search?q=Actions-openwrt).
- Add some meta info of your built firmware (such as firmware architecture and installed packages) to your repository introduction, this will save others' time.

## Credits

- [Microsoft Azure](https://azure.microsoft.com)
- [GitHub Actions](https://github.com/features/actions)
- [OpenWrt](https://github.com/openwrt/openwrt)
- [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede)
- [Mikubill/transfer](https://github.com/Mikubill/transfer)
- [softprops/action-gh-release](https://github.com/softprops/action-gh-release)
- [Mattraks/delete-workflow-runs](https://github.com/Mattraks/delete-workflow-runs)
- [dev-drprasad/delete-older-releases](https://github.com/dev-drprasad/delete-older-releases)
- [peter-evans/repository-dispatch](https://github.com/peter-evans/repository-dispatch)

## License

[MIT](https://github.com/P3TERX/Actions-OpenWrt/blob/main/LICENSE) © [**P3TERX**](https://p3terx.com)
