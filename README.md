<a id="中文"></a>

**简体中文** · [English ↓](#english)

# kernel_samsung_sm8650

> 面向骁龙 8 Gen 3（SM8650）三星 Galaxy S24 全系的自定义 Android GKI 内核。

![SoC](https://img.shields.io/badge/SoC-Snapdragon_8_Gen_3-0a7bbb)
![Android](https://img.shields.io/badge/Android-14-3ddc84)
![Kernel](https://img.shields.io/badge/Linux-6.1.172-f6a500)
![KMI](https://img.shields.io/badge/KMI-android14--7-9aa0a6)
![Root](https://img.shields.io/badge/Root-ReSukiSU%20%2B%20SUSFS-c2185b)
![License](https://img.shields.io/badge/License-GPL--2.0-2962ff)

基于三星 `pineapple` GKI（android14-6.1）的自定义内核，面向 **Galaxy S24 / S24+ / S24 Ultra**，搭载 Android 14、Linux 6.1.172（KMI generation 7），并前向合并至最新 6.1.x LTS。

> **定位**：本树主要面向 **Samsung 设备**，也只在 Samsung 机型上测试与发布。因为合并了上游 LTS，它理论上也能跑在同 SoC 的其他设备上，但这一点不作保证。

构建是 **mode-driven** 的：git 树是干净基线，**不**提交任何 KSU / SUSFS / Wild 补丁；`build/build.sh` 在编译期抓取并应用它们，因此同一份基线既能产出内置 root 版、也能产出纯净版，且便于对上游持续前向合并。

---

## ✨ 特性亮点

> 三仓（sm8550 / sm8650 / sm8750）共享同一套特性集，下面这些是开箱即得的核心能力。

- 🔓 **内置 Root** — ReSukiSU（KernelSU）直接编译进内核（`resukisu` 模式），刷完即 root；另有 `lkm` 纯净模式，root 留到刷入时再注入。
- 🫥 **SUSFS 隐藏** — 把 root、挂载、路径从各类检测中隐藏起来。
- 🧩 **KPM 内核模块** — 支持 SukiSU KPM（管理器里的"核心"）。
- 📡 **Baseband-guard** — LSM 级保护 modem / vbmeta / dtbo，任何 root 用户都改不动。
- 🔔 **Re:Kernel** — 内置，提供前后台 / 网络事件通知，便于省电与后台管控。
- ⚡ **Wild 全套性能补丁** — F2FS/ext4 调优、内存与调度优化、唤醒/功耗优化、日志降噪一整套。
- 🎮 **NTSync** — Windows NT 风格同步原语，跑 Wine / Proton 游戏更顺。
- 📦 **Droidspaces 容器** — SYSVIPC / 命名空间 / netfilter 开关，可在 Android 里跑 Linux 容器、chroot。
- 💾 **NTFS3 读写** — OTG 上的 NTFS 盘可读写（含 LZX/XPRESS 压缩）。
- 🗜️ **zram lz4 + BBR** — zram 默认换 lz4，TCP 默认 FQ + BBR。
- 📁 **完整 tmpfs** — POSIX ACL / XATTR / INODE64 全开。
- 🕸️ **完整 ipset** — 内置整套 IP set（bitmap/hash/list），便于防火墙/分流方案。
- 🕵️ **IPv6 NAT 隐藏** — 构建期抹掉 `/proc/config.gz` 里的痕迹，绕过基于配置的 root 检测。
- 🛡️ **三星安全栈禁用** — 关闭 UH / RKP / KDP / DEFEX / INTEGRITY / FIVE / KNOX_NCM 等反 root 机制（三仓中清单最完整）。
- 🚀 **ccache 加速** — 增量编译提速约 60–80%。

---

## 📱 支持设备

| 设备 | 型号 |
|---|---|
| Galaxy S24 | SM-S921 |
| Galaxy S24+ | SM-S926 |
| Galaxy S24 Ultra | SM-S928 |

S24 全家桶都跑这同一份 SM8650 GKI 内核，只是 `ro.product.device` codename 各不相同。打包时 **`do.devicecheck=0`**：不校验 codename，**按需刷入**即可。

---

## 🌿 分支与模式

| 模式 | 说明 |
|---|---|
| `resukisu`（默认） | 内置 ReSukiSU + SUSFS + KPM + 全套特性。 |
| `lkm` | 纯净内核，不含 KSU/SUSFS/KPM；root 在刷入时由管理器给 `init_boot` 打补丁注入。 |

> `lkm` 模式产出的 `Image` 是真正干净的（零 `ksu_` 字符串）；KernelSU 管理器在刷入时打补丁，运行时用 kprobes/kallsyms 注入未改动的 vmlinux。

---

## 🧩 完整特性一览

| 特性 | resukisu | lkm | 来源 |
|---|:---:|:---:|---|
| ReSukiSU（KernelSU） | 内置 | 刷入时注入 | [ReSukiSU/ReSukiSU](https://github.com/ReSukiSU/ReSukiSU) |
| SUSFS | ✅ | ❌¹ | [ShirkNeko/susfs4ksu](https://github.com/ShirkNeko/susfs4ksu)（`gki-android14-6.1`） |
| KPM（SukiSU 补丁模块） | ✅ | ❌² | 内置 `build/patch_linux` |
| Baseband-guard | ✅ | ✅ | [vc-teahouse/Baseband-guard](https://github.com/vc-teahouse/Baseband-guard) |
| Re:Kernel | ✅ | ✅ | 内置 `build/features/rekernel` |
| Wild 性能补丁 | ✅ | ✅ | [WildKernels/kernel_patches](https://github.com/WildKernels/kernel_patches) |
| NTSync（Wine/Proton） | ✅ | ✅ | Linux mainline ³ |
| Droidspaces（容器） | ✅ | ✅ | mainline 配置 + KABI 补丁 ³ |
| Unicode 绕过修复 | ✅ | ✅ | WildKernels |
| NTFS3（+LZX/XPRESS） | ✅ | ✅ | mainline |
| zram 默认 lz4 | ✅ | ✅ | config |
| FQ + BBR | ✅ | ✅ | config |
| 完整 tmpfs（ACL/XATTR/INODE64） | ✅ | ✅ | config |
| 完整 ipset | ✅ | ✅ | config |
| IPv6 NAT 隐藏 | ✅ | ✅ | 内置 `config_data` 钩子 |
| 三星安全栈禁用 | ✅ | ✅ | 构建期 `scripts/config` 覆盖 |

¹ `lkm` 模式关闭 SUSFS：`fs/susfs.c` 引用了仅在 `CONFIG_KSU=y` 时才链接的 `ksu_*` 符号。
² `KPM` 依赖 KSU，纯 `lkm` 内核无法启用。
³ 标 mainline/upstream 的特性源自 Linux 上游，并非 Wild 首创；构建时我们从 [WildKernels/kernel_patches](https://github.com/WildKernels/kernel_patches) 取**已适配到本 GKI 版本**的 backport，省去自行回合的工作。真正属于 Wild 的是上面「Wild 性能补丁」那一行（其自有的性能/降噪调优集）。

---

## 🚀 编译

```bash
# resukisu（默认）：内置 ReSukiSU + SUSFS + KPM + 全套特性
build/build.sh
build/build.sh resukisu

# lkm：纯净内核（KSU 刷入时注入）
build/build.sh lkm

# 额外打包 AnyKernel3 zip
PACK=1 build/build.sh
```

前置：

- 三星 `clang-r510928` prebuilts。把 `TOOLCHAIN_DIR` 指向其 `.../kernel_platform/prebuilts`（与 sm8750 共用）：

  ```bash
  TOOLCHAIN_DIR=../toolchain_samsung_sm8750/kernel_platform/prebuilts build/build.sh
  ```
- 首次编译需联网（抓取 ReSukiSU / SUSFS / Wild / Baseband-guard 等源）。
- ccache 存在时自动启用（增量提速明显）。

产物：

```
out/arch/arm64/boot/Image                 # 内核镜像（resukisu 模式经 patch_linux 打上 KPM）
../SM8650_<tag>_<版本>_<MMDD>.zip          # PACK=1 时
```

版本号形如 `6.1.172-android14-7-YuccaA-abogki<9位随机>-4k`。

---

## ⚙️ 构建开关（环境变量）

构建是 mode-driven 的：特性默认全开，只有 `resukisu` / `lkm` 这一个参数决定 KSU / SUSFS / KPM 是否编入。

| 变量 | 默认 | 作用 |
|---|---|---|
| `TOOLCHAIN_DIR` | `../toolchain_samsung_sm8750/kernel_platform/prebuilts` | clang-r510928 prebuilts 目录 |
| `JOBS` | `nproc` | 并行编译任务数 |
| `PACK` | `0` | 设 `1` 打包 AnyKernel3 zip（需 `ANYKERNEL_DIR`） |
| `ANYKERNEL_DIR` | `../AnyKernel3_s24` | AnyKernel3 模板目录 |
| `BUILD_NUM` | 随机 | 固定版本号里的 `abogki` 编号 |
| `SUSFS_PIN` | 见脚本 | 覆盖 susfs4ksu 的 commit |
| `WILD_PIN` | `5a5d5d8` | 覆盖 WildKernels/kernel_patches 的 commit |
| `CCACHE_DIR` / `CCACHE_MAXSIZE` | `.ccache` / `2G` | ccache 缓存目录与上限 |

---

## 🔐 安全与硬化

- `resukisu` 构建会**禁用**三星 Knox 安全栈（UH / RKP / KDP / KDP_CRED / KDP_NS / DEFEX / INTEGRITY / FIVE / KNOX_NCM / SKB_TRACER）以及 `MODULE_SIG*`、`TRIM_UNUSED_KSYMS`，否则它们会对抗内核级 root 或挡住模块导出符号。仅在编译**非 root** 内核时才应重新启用。
- SUSFS / Unicode 修复 / IPv6 NAT 隐藏共同压制常见的 root 检测面。

---

## 📦 刷入

从任意 S24 机型的 Recovery（TWRP/OrangeFox）刷入 zip；或用 magiskboot 把裸 `Image` 塞进 stock `boot.img`。zip 不校验 codename，S921/S926/S928 通用。DTB/dtbo 取自设备现有分区，本树不重新生成。

---

## 📜 血统与许可

GPL-2.0。本树派生自：

- **三星** 为 Galaxy S24（SM8650）发布的开源内核（`pineapple`，android14-6.1）—— 全部三星驱动/HAL 版权归三星所有，GPL-2.0。
- **ReSukiSU / KernelSU**、**SukiSU KPM**、**SUSFS**（ShirkNeko）、**WildKernels** 补丁集、**Baseband-guard**（vc-teahouse）、**Re:Kernel** —— 各自遵循其许可。

本仓库自身的贡献是 mode-driven 构建系统与特性集成。这是一个**不点 Fork 按钮的下游树**，每个组件仍受其自身许可约束。

---
---

<a id="english"></a>

[简体中文 ↑](#中文) · **English**

# kernel_samsung_sm8650

> Custom Android GKI kernel for the Snapdragon 8 Gen 3 (SM8650) Samsung Galaxy S24 family.

A custom kernel for **Galaxy S24 / S24+ / S24 Ultra**, running Android 14 on Linux 6.1.172 (KMI generation 7), based on Samsung's `pineapple` GKI (android14-6.1) and merged forward to the latest 6.1.x LTS.

> **Scope:** primarily for **Samsung devices**, and tested/released on Samsung models only. Because it merges upstream LTS it can in principle run on other same-SoC devices too, but that is not guaranteed.

The build is **mode-driven**: the git tree is a clean base with **no** KSU / SUSFS / Wild patches committed; `build/build.sh` fetches and applies them at build time, so one base produces either variant and stays easy to forward-merge against upstream.

## ✨ Highlights

> All three trees (sm8550 / sm8650 / sm8750) share one feature set — available out of the box.

- 🔓 **Built-in root** — ReSukiSU (KernelSU) compiled in (`resukisu`); or a clean `lkm` mode where root is injected at flash time.
- 🫥 **SUSFS hiding** · 🧩 **KPM** · 📡 **Baseband-guard** · 🔔 **Re:Kernel**
- ⚡ **Full Wild performance patch set** — F2FS/ext4 tuning, mm & scheduler tweaks, wakeup/power optimizations, logspam silencing.
- 🎮 **NTSync** (Wine/Proton) · 📦 **Droidspaces** (Linux containers) · 💾 **NTFS3** (+LZX/XPRESS)
- 🗜️ **zram lz4 + FQ/BBR** · 📁 **Full tmpfs** (ACL/XATTR/INODE64) · 🕸️ **Full ipset suite**
- 🕵️ **IPv6 NAT hidden** from `/proc/config.gz` · 🛡️ **Samsung security stack disabled** (most complete list of the three) · 🚀 **ccache**

## 📱 Supported devices

| Device | Model |
|---|---|
| Galaxy S24 | SM-S921 |
| Galaxy S24+ | SM-S926 |
| Galaxy S24 Ultra | SM-S928 |

The whole S24 family runs this one SM8650 GKI kernel; only the `ro.product.device` codename differs. Packaging sets **`do.devicecheck=0`** — no codename gating, flash by choice.

## 🌿 Modes

- `resukisu` (default): built-in ReSukiSU + SUSFS + KPM + full set.
- `lkm`: pure kernel (no KSU/SUSFS/KPM); root injected at flash time via the manager patching `init_boot`. The `Image` is genuinely vanilla (zero `ksu_` strings).

## 🧩 Feature matrix

| Feature | resukisu | lkm | Source |
|---|:---:|:---:|---|
| ReSukiSU (KernelSU) | built-in | flash-time | ReSukiSU/ReSukiSU |
| SUSFS | ✅ | ❌¹ | ShirkNeko/susfs4ksu (`gki-android14-6.1`) |
| KPM | ✅ | ❌² | bundled `build/patch_linux` |
| Baseband-guard | ✅ | ✅ | vc-teahouse/Baseband-guard |
| Re:Kernel | ✅ | ✅ | vendored `build/features/rekernel` |
| Wild perf patches | ✅ | ✅ | WildKernels/kernel_patches |
| NTSync | ✅ | ✅ | Linux mainline ³ |
| Droidspaces | ✅ | ✅ | mainline configs + KABI shim ³ |
| Unicode bypass fix | ✅ | ✅ | WildKernels |
| NTFS3 (+LZX/XPRESS) | ✅ | ✅ | mainline |
| zram default lz4 / FQ+BBR | ✅ | ✅ | config |
| Full tmpfs (ACL/XATTR/INODE64) | ✅ | ✅ | config |
| Full ipset suite | ✅ | ✅ | config |
| IPv6 NAT hidden | ✅ | ✅ | in-tree `config_data` hook |
| Samsung security stack disabled | ✅ | ✅ | `scripts/config` overrides |

¹ SUSFS is off in `lkm`: `fs/susfs.c` references `ksu_*` symbols that only link with `CONFIG_KSU=y`.
² `KPM` depends on KSU.
³ Features marked mainline/upstream originate in upstream Linux, not Wild. At build time we fetch versions **already backported to this GKI tree** from [WildKernels/kernel_patches](https://github.com/WildKernels/kernel_patches) to avoid re-doing the backport. What is genuinely Wild's is the "Wild perf patches" row (their curated performance/logspam set).

## 🚀 Build

```bash
build/build.sh            # resukisu (default)
build/build.sh lkm        # pure kernel
PACK=1 build/build.sh     # also pack an AnyKernel3 zip
# point at the shared clang-r510928 prebuilts:
TOOLCHAIN_DIR=../toolchain_samsung_sm8750/kernel_platform/prebuilts build/build.sh
```

Output: `out/arch/arm64/boot/Image` (KPM-patched in resukisu) and, with `PACK=1`, `../SM8650_<tag>_<ver>_<MMDD>.zip`. Release string: `6.1.172-android14-7-YuccaA-abogki<random>-4k`. Requires the Samsung `clang-r510928` prebuilts and network on first build; ccache is used automatically when present.

## ⚙️ Build switches

Mode-driven — features are all on; the single `resukisu`/`lkm` arg gates KSU/SUSFS/KPM. Env: `TOOLCHAIN_DIR`, `JOBS`, `PACK`, `ANYKERNEL_DIR`, `BUILD_NUM`, `SUSFS_PIN`, `WILD_PIN`, `CCACHE_DIR`, `CCACHE_MAXSIZE`.

## 🔐 Security & hardening

`resukisu` builds disable Samsung's Knox stack (UH / RKP / KDP / KDP_CRED / KDP_NS / DEFEX / INTEGRITY / FIVE / KNOX_NCM / SKB_TRACER) plus `MODULE_SIG*` and `TRIM_UNUSED_KSYMS`. Re-enable only for a non-rooted build. SUSFS / Unicode fix / IPv6-NAT hiding reduce the common root-detection surface.

## 📦 Flashing

Flash the zip from any S24 recovery (TWRP/OrangeFox), or drop the raw `Image` into your stock `boot.img` with magiskboot. No codename gating — one zip for SM-S921/S926/S928. DTB/dtbo come from existing partitions.

## 📜 Lineage & license

GPL-2.0, derived from Samsung's open-source Galaxy S24 (SM8650) kernel (`pineapple`, android14-6.1) plus ReSukiSU/KernelSU, SukiSU KPM, SUSFS (ShirkNeko), WildKernels, Baseband-guard (vc-teahouse) and Re:Kernel — each under its own license. This repo's own contribution is the mode-driven build system and feature integration.
