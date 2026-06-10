#!/usr/bin/env bash
#
# build.sh -- build the Samsung sm8650 (Galaxy S24) GKI kernel.
#
# Usage:
#   build/build.sh [resukisu|lkm]
#
# Modes:
#   resukisu (default)  built-in ReSukiSU + SUSFS + KPM + full feature set
#   lkm                 pure kernel, no KSU/SUSFS/KPM (KSU injected at flash
#                       time by the manager app patching init_boot)
#
# Environment overrides:
#   TOOLCHAIN_DIR  prebuilts dir (default: ../toolchain_samsung_sm8750/kernel_platform/prebuilts)
#   JOBS           parallel jobs (default: nproc)
#   PACK           1 to pack an AnyKernel3 zip (needs ANYKERNEL_DIR)
#   ANYKERNEL_DIR  path to an AnyKernel3 tree (default: ../AnyKernel3_s24)
#   BUILD_NUM      override the random ab<number> build id
#
set -e
MODE="${1:-${MODE:-resukisu}}"
[ "$MODE" = "resukisu" ] || [ "$MODE" = "lkm" ] || { echo "mode must be resukisu|lkm"; exit 1; }

KROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$KROOT"
HERE="$KROOT/build"
OUT="$KROOT/out"
JOBS="${JOBS:-$(nproc)}"
TOOLCHAIN_DIR="${TOOLCHAIN_DIR:-/home/yucca/work/kernel_sm8750/toolchain_samsung_sm8750/kernel_platform/prebuilts}"
CLANG_BIN="$TOOLCHAIN_DIR/clang/host/linux-x86/clang-r510928/bin"
ANYKERNEL_DIR="${ANYKERNEL_DIR:-$KROOT/../AnyKernel3_s24}"
KMI_GEN=7   # android14-6.1 == KMI generation 7

[ -d "$CLANG_BIN" ] || { echo "ERROR: toolchain not found at $CLANG_BIN
Set TOOLCHAIN_DIR to your Samsung clang-r510928 prebuilts dir."; exit 1; }

echo "=== sm8650 build: MODE=$MODE  JOBS=$JOBS ==="
echo "    $(grep -m1 '^VERSION' Makefile | tr -d ' ') $(grep -m1 '^PATCHLEVEL' Makefile | tr -d ' ') $(grep -m1 '^SUBLEVEL' Makefile | tr -d ' ')"

# ---- toolchain env ----
export PATH="$TOOLCHAIN_DIR/build-tools/linux-x86/bin:$TOOLCHAIN_DIR/build-tools/path/linux-x86:$CLANG_BIN:$TOOLCHAIN_DIR/kernel-build-tools/linux-x86/bin:$PATH"
sysroot="--sysroot=$TOOLCHAIN_DIR/gcc/linux-x86/host/x86_64-linux-glibc2.17-4.8/sysroot"
export LD_LIBRARY_PATH="$TOOLCHAIN_DIR/kernel-build-tools/linux-x86/lib64"
export HOSTCFLAGS="$sysroot -I$TOOLCHAIN_DIR/kernel-build-tools/linux-x86/include"
export HOSTLDFLAGS="$sysroot -L $TOOLCHAIN_DIR/kernel-build-tools/linux-x86/lib64 -fuse-ld=lld --rtlib=compiler-rt"
# ccache (big speedup on rebuilds; no-op if ccache absent). Masquerade a clang
# symlink at the front of PATH so the string-based "CC=clang" routes through
# ccache, which then finds the real clang further down PATH (CLANG_BIN).
# Honours CCACHE_DIR / CCACHE_MAXSIZE exported by the CI (cached across runs).
if command -v ccache >/dev/null 2>&1; then
  export CCACHE_DIR="${CCACHE_DIR:-$KROOT/.ccache}"
  export CCACHE_MAXSIZE="${CCACHE_MAXSIZE:-2G}"
  mkdir -p "$CCACHE_DIR" "$KROOT/.ccache_bin"
  ln -sf "$(command -v ccache)" "$KROOT/.ccache_bin/clang"
  export PATH="$KROOT/.ccache_bin:$PATH"
  echo "    ccache: on (dir=$CCACHE_DIR max=$CCACHE_MAXSIZE)"
fi
MAKE_ARGS="CC=clang ARCH=arm64 LLVM=1 LLVM_IAS=1"

# ---- apply features (mode-aware) ----
MODE="$MODE" CACHE="$KROOT/.build_cache" bash "$HERE/apply_features.sh"

# ---- configure ----
echo "=== configure ==="
make -j"$JOBS" O="$OUT" $MAKE_ARGS pineapple_gki_defconfig >/dev/null
BN="${BUILD_NUM:-$(shuf -i 100000000-999999999 -n 1)}"
rm -f localversion

# common: drop Samsung security stack that conflicts with custom kernels
COMMON_DISABLE="-d UH -d RKP -d KDP -d KDP_CRED -d KDP_NS -d SECURITY_DEFEX -d INTEGRITY -d FIVE \
  -d KNOX_NCM -d SKB_TRACER -d HUGEPAGE_POOL -d TRIM_UNUSED_KSYMS 
  -d MODULE_SIG -d MODULE_SIG_ALL -d MODULE_SIG_FORCE -d MODULE_SIG_PROTECT"
# common features (KSU-independent): NTFS3, zram-lz4, FQ+BBR, NTSync, IPv6 NAT, Re:Kernel, sysvipc/mqueue
COMMON_ENABLE="-e NTFS3_FS -e NTFS3_LZX_XPRESS -e ZRAM_DEF_COMP_LZ4 --set-str ZRAM_DEF_COMP lz4 \
  -e NET_SCH_FQ -e TCP_CONG_ADVANCED -e TCP_CONG_BBR -e DEFAULT_BBR -e NTSYNC -e IP6_NF_NAT -e REKERNEL \
  -e SYSVIPC -e POSIX_MQUEUE -e IPC_NS -e PID_NS -e DEVTMPFS \
  -e NETFILTER_XT_MATCH_ADDRTYPE -e NETFILTER_XT_MATCH_RECENT \
  -e TMPFS -e TMPFS_POSIX_ACL -e TMPFS_XATTR -e TMPFS_INODE64 \
  -e NETFILTER_XT_TARGET_HL \
  -e IP_SET -e IP_SET_BITMAP_IP -e IP_SET_BITMAP_IPMAC -e IP_SET_BITMAP_PORT \
  -e IP_SET_HASH_IP -e IP_SET_HASH_IPMARK -e IP_SET_HASH_IPPORT -e IP_SET_HASH_IPPORTIP \
  -e IP_SET_HASH_IPPORTNET -e IP_SET_HASH_IPMAC -e IP_SET_HASH_MAC -e IP_SET_HASH_NET \
  -e IP_SET_HASH_NETNET -e IP_SET_HASH_NETPORT -e IP_SET_HASH_NETPORTNET \
  -e IP_SET_HASH_NETIFACE -e IP_SET_LIST_SET"

if [ "$MODE" = "resukisu" ]; then
  MODE_CFG="-e KSU -e KSU_SUSFS -e KPM"
else
  MODE_CFG="-d KSU -d KSU_SUSFS -d KPM"
fi

# shellcheck disable=SC2086
./scripts/config --file "$OUT/.config" $COMMON_DISABLE $MODE_CFG $COMMON_ENABLE \
  -d LOCALVERSION_AUTO --set-str LOCALVERSION "-android14-${KMI_GEN}-YuccaA-abogki${BN}-4k"

# baseband_guard LSM
if grep -q '^CONFIG_LSM="' "$OUT/.config" && ! grep -q baseband_guard "$OUT/.config"; then
  sed -i 's/^\(CONFIG_LSM="[^"]*\)"$/\1,baseband_guard"/' "$OUT/.config"
fi
make -j"$JOBS" O="$OUT" $MAKE_ARGS olddefconfig >/dev/null

echo "=== config summary ==="
for c in KSU KSU_SUSFS KPM NTFS3_FS ZRAM_DEF_COMP_LZ4 TCP_CONG_BBR NTSYNC IP6_NF_NAT REKERNEL POSIX_MQUEUE; do
  printf '    %-20s %s\n' "$c" "$(grep -q "^CONFIG_$c=y" "$OUT/.config" && echo y || echo n)"
done
printf '    %-20s %s\n' "baseband_guard" "$(grep -q baseband_guard "$OUT/.config" && echo y || echo n)"

# ---- build (retry once: kbuild fixdep occasionally races on a parallel build) ----
echo "=== build Image ==="
if ! make -j"$JOBS" O="$OUT" $MAKE_ARGS Image; then
  echo "=== first pass failed; retrying incrementally (fixdep race guard) ==="
  make -j"$JOBS" O="$OUT" $MAKE_ARGS Image
fi
IMG="$OUT/arch/arm64/boot/Image"
REL="$(cat "$OUT/include/config/kernel.release")"
echo "    Image: $(stat -c%s "$IMG") bytes   release: $REL"

# ---- KPM (resukisu only) ----
# patch_linux is the SukiSU KPM ("核心") patcher: it rewrites Image -> oImage
# with KPM support. Robust handling (mirrors the sm8550 tree): ensure the
# patcher is executable (survives a lost exec bit), don't swallow its output,
# and abort loudly if it fails or doesn't change the Image -- never publish an
# un-patched Image as if KPM were applied.
if [ "$MODE" = "resukisu" ]; then
  echo "=== KPM patch_linux ==="
  [ -f "$HERE/patch_linux" ] || { echo "[!] patch_linux missing at $HERE/patch_linux (needed for KPM)"; exit 1; }
  kpm_pre="$(stat -c%s "$IMG")"
  ( cd "$(dirname "$IMG")" \
      && cp -f "$HERE/patch_linux" ./patch_linux \
      && chmod +x ./patch_linux \
      && ./patch_linux \
      && mv -f oImage Image \
      && rm -f ./patch_linux ) || { echo "[!] KPM patch_linux failed"; exit 1; }
  kpm_post="$(stat -c%s "$IMG")"
  echo "    KPM-patched Image: $kpm_post bytes (was $kpm_pre)"
  [ "$kpm_post" != "$kpm_pre" ] || { echo "[!] KPM patch did not change the Image ($kpm_pre bytes) -- NOT applied"; exit 1; }
fi

# ---- pack (optional) ----
if [ "${PACK:-0}" = "1" ]; then
  [ -d "$ANYKERNEL_DIR" ] || { echo "ANYKERNEL_DIR not found: $ANYKERNEL_DIR"; exit 1; }
  tag="resukisu"; [ "$MODE" = "lkm" ] && tag="LKM"
  ZIP="$KROOT/../SM8650_${tag}_${REL%%-*}_$(date +%m%d).zip"
  rm -f "$ANYKERNEL_DIR"/*.zip "$ANYKERNEL_DIR"/zImage "$ANYKERNEL_DIR"/Image
  cp -f "$IMG" "$ANYKERNEL_DIR/zImage"
  # The Snapdragon S24 family (SM-S921/S926/S928) all run this one SM8650 GKI
  # kernel but expose different ro.product.device codenames; flash by user
  # choice rather than gating on them. Disable the AnyKernel device check.
  ak="$ANYKERNEL_DIR/anykernel.sh"
  [ -f "$ak" ] && sed -i 's/^do\.devicecheck=1/do.devicecheck=0/' "$ak"
  [ -f "$ak" ] && echo "    AnyKernel devicecheck: $(grep -m1 '^do.devicecheck=' "$ak")"
  rm -f "$ZIP"
  ( cd "$ANYKERNEL_DIR" && zip -r9 "$ZIP" . -x '*.git*' '*.zip' >/dev/null )
  echo "=== packed: $ZIP ($(du -h "$ZIP" | cut -f1)) ==="
fi
echo "=== DONE ($MODE): $REL ==="
