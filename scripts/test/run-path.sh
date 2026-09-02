#!/usr/bin/env bash
# Boot each documented install path in a VM and prove it reaches a login prompt.
#
#   ./run-path.sh standard          one path
#   ./run-path.sh --all             every path
#   ARCH_ISO=/path/to.iso ./run-path.sh btrfs
#
# Pass 1 installs by running the path's payload unattended in the live ISO.
# Pass 2 boots the resulting disk with no ISO and asserts a login prompt.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="${WORK_DIR:-$HERE/.work}"
CACHE="$HERE/.cache"
PATHS=(standard lvm luks-lvm btrfs btrfs-luks)
ENCRYPTED=" luks-lvm btrfs-luks "
LUKS_PASS=archtestluks

DISK_SIZE="${DISK_SIZE:-40G}"
MEMORY="${MEMORY:-4096}"
INSTALL_TIMEOUT="${INSTALL_TIMEOUT:-2400}"
BOOT_TIMEOUT="${BOOT_TIMEOUT:-300}"
MIRROR="${ARCH_MIRROR:-https://geo.mirror.pkgbuild.com/iso/latest}"

c()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
ok() { printf '\033[1;32m PASS\033[0m %s\n' "$*"; }
no() { printf '\033[1;31m FAIL\033[0m %s\n' "$*"; }
die(){ printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

need() { command -v "$1" >/dev/null 2>&1 || die "missing '$1' — install $2"; }
need qemu-system-x86_64 qemu-base
need qemu-img           qemu-base
need bsdtar             libarchive
need python3            python
need curl               curl

OVMF_CODE=""
for f in /usr/share/edk2/x64/OVMF_CODE.4m.fd /usr/share/edk2/x64/OVMF_CODE.fd \
         /usr/share/OVMF/OVMF_CODE.fd /usr/share/edk2-ovmf/x64/OVMF_CODE.fd; do
    [ -f "$f" ] && { OVMF_CODE="$f"; break; }
done
[ -n "$OVMF_CODE" ] || die "UEFI firmware not found — install edk2-ovmf"
OVMF_VARS="$(dirname "$OVMF_CODE")/$(basename "${OVMF_CODE/CODE/VARS}")"
[ -f "$OVMF_VARS" ] || die "OVMF_VARS not found next to $OVMF_CODE"

[ -w /dev/kvm ] 2>/dev/null && ACCEL="-machine q35,accel=kvm -cpu host" \
                           || { ACCEL="-machine q35 -cpu qemu64"; c "no KVM — falling back to slow TCG emulation"; }

mkdir -p "$WORK" "$CACHE"

# ---- ISO ----------------------------------------------------------------
get_iso() {
    if [ -n "${ARCH_ISO:-}" ]; then
        [ -f "$ARCH_ISO" ] || die "ARCH_ISO=$ARCH_ISO does not exist"
        ISO="$ARCH_ISO"; return
    fi
    ISO="$(ls -1t "$CACHE"/archlinux-*.iso 2>/dev/null | head -1 || true)"
    if [ -z "$ISO" ]; then
        c "downloading the current Arch ISO (~1.2GB, cached in $CACHE)"
        local name; name="$(curl -fsSL "$MIRROR/" | grep -oE 'archlinux-[0-9.]+-x86_64\.iso' | head -1)"
        [ -n "$name" ] || die "could not determine the latest ISO name from $MIRROR"
        curl -fL --progress-bar -o "$CACHE/$name.part" "$MIRROR/$name"
        mv "$CACHE/$name.part" "$CACHE/$name"
        ISO="$CACHE/$name"
    fi
    c "ISO: $ISO"
}

prepare_boot_files() {
    KERNEL="$WORK/vmlinuz-linux"; INITRD="$WORK/initramfs-linux.img"
    if [ ! -f "$KERNEL" ] || [ "$ISO" -nt "$KERNEL" ]; then
        c "extracting kernel and initramfs from the ISO"
        bsdtar -xOf "$ISO" arch/boot/x86_64/vmlinuz-linux      > "$KERNEL"
        bsdtar -xOf "$ISO" arch/boot/x86_64/initramfs-linux.img > "$INITRD"
    fi
    [ -s "$KERNEL" ] && [ -s "$INITRD" ] || die "failed to extract boot files from the ISO"
    ISO_LABEL="$(blkid -s LABEL -o value "$ISO" 2>/dev/null || true)"
    [ -n "$ISO_LABEL" ] || ISO_LABEL="ARCH_$(date +%Y%m)"
    c "ISO label: $ISO_LABEL"
}

# ---- one path -----------------------------------------------------------
run_one() {
    local p="$1"
    [ -f "$HERE/payloads/$p.sh" ] || die "unknown path '$p' (have: ${PATHS[*]})"

    local disk="$WORK/$p.qcow2" vars="$WORK/$p-VARS.fd"
    local ilog="$WORK/$p-install.log" blog="$WORK/$p-boot.log"
    rm -f "$disk" "$vars" "$ilog" "$blog"
    qemu-img create -f qcow2 "$disk" "$DISK_SIZE" >/dev/null
    cp "$OVMF_VARS" "$vars"

    # serve payloads/ and lib/ to the guest; slirp maps host loopback to 10.0.2.2
    local port; port="$(python3 -c 'import socket;s=socket.socket();s.bind(("127.0.0.1",0));print(s.getsockname()[1]);s.close()')"
    python3 -m http.server "$port" --bind 127.0.0.1 --directory "$HERE" >/dev/null 2>&1 &
    local http=$!
    trap 'kill '"$http"' 2>/dev/null || true' RETURN
    sleep 1

    c "[$p] pass 1 — installing (timeout ${INSTALL_TIMEOUT}s, log: $ilog)"
    local append="archisobasedir=arch archisodevice=/dev/disk/by-label/$ISO_LABEL"
    append+=" cow_spacesize=2G script=http://10.0.2.2:$port/payloads/$p.sh"
    append+=" console=ttyS0,115200 systemd.show_status=false"

    set +e
    timeout "$INSTALL_TIMEOUT" qemu-system-x86_64 $ACCEL \
        -m "$MEMORY" -smp "$(nproc)" \
        -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE" \
        -drive "if=pflash,format=raw,file=$vars" \
        -drive "file=$disk,if=virtio,format=qcow2" \
        -drive "file=$ISO,media=cdrom,readonly=on" \
        -kernel "$KERNEL" -initrd "$INITRD" -append "$append" \
        -netdev user,id=n0 -device virtio-net-pci,netdev=n0 \
        -display none -serial "file:$ilog" -no-reboot
    local rc=$?
    set -e
    kill $http 2>/dev/null || true

    if [ $rc -eq 124 ]; then
        no "[$p] install timed out after ${INSTALL_TIMEOUT}s"; tail -30 "$ilog"; return 1
    fi
    if grep -q 'ARCHTEST: ERROR' "$ilog"; then
        no "[$p] install reported an error"; grep -n 'ARCHTEST' "$ilog" | tail -20; return 1
    fi
    if ! grep -q 'ARCHTEST: INSTALL COMPLETE' "$ilog"; then
        no "[$p] install never completed"; tail -30 "$ilog"; return 1
    fi
    c "[$p] pass 1 complete"

    local pass=()
    [[ "$ENCRYPTED" == *" $p "* ]] && pass=(--passphrase "$LUKS_PASS")
    # NOTE: do NOT reset $vars here. grub-install wrote the UEFI boot entry into this
    # NVRAM image during pass 1; overwriting it leaves the firmware with nothing to boot.
    c "[$p] pass 2 — booting the installed system"
    if python3 "$HERE/lib/boot-check.py" --disk "$disk" \
            --ovmf-code "$OVMF_CODE" --ovmf-vars "$vars" \
            --timeout "$BOOT_TIMEOUT" --log "$blog" "${pass[@]}" >/dev/null 2>&1; then
        ok "[$p] installs and boots to a login prompt"; return 0
    else
        no "[$p] installed but did not reach a login prompt"; tail -40 "$blog" 2>/dev/null; return 1
    fi
}

# ---- main ---------------------------------------------------------------
[ $# -ge 1 ] || { echo "usage: $0 <${PATHS[*]}|--all>"; exit 2; }
if [ "$1" = "--all" ]; then TARGETS=("${PATHS[@]}"); else TARGETS=("$@"); fi

get_iso
prepare_boot_files

declare -a FAILED=()
for p in "${TARGETS[@]}"; do
    run_one "$p" || FAILED+=("$p")
    echo
done

echo "────────────────────────────────────────"
if [ ${#FAILED[@]} -eq 0 ]; then
    ok "all paths passed: ${TARGETS[*]}"; exit 0
else
    no "failed: ${FAILED[*]}"; exit 1
fi
