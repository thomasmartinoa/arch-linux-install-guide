#!/bin/bash
# Shared install steps for the VM smoke tests.
#
# MIRRORS: the five docs/03-base-installation/base-install-*.md guides (shared steps)
# Every command here must correspond to a step in that document. If you change one,
# change the other in the same commit — a payload that drifts from the guide tests nothing.

TEST_USER=archtest
TEST_PASS=archtest
TEST_HOST=archtest
LUKS_PASS=archtestluks

log()  { echo "ARCHTEST: --- $* ---"; }
die()  { echo "ARCHTEST: ERROR: $*"; exit 1; }

# Wait for DHCP to settle before touching the network.
wait_net() {
    log "waiting for network"
    for _ in $(seq 1 60); do
        ping -c1 -W2 archlinux.org >/dev/null 2>&1 && { log "network up"; return 0; }
        sleep 2
    done
    die "no network in the live environment"
}

# base-install-*.md Step 2 — note the kernel and editor, which `base` does not provide.
# $1 = path-specific extra packages (Step 6.2 branch), may be empty.
install_base() {
    local extra="${1:-}"
    log "pacstrap (extras: ${extra:-none})"
    pacstrap -K /mnt base linux linux-firmware vim $extra \
        || die "pacstrap failed"
}

# base-install-*.md Step 3
gen_fstab() {
    log "genfstab"
    genfstab -U /mnt >> /mnt/etc/fstab
    echo "ARCHTEST: fstab:"; cat /mnt/etc/fstab
}

# base-install-*.md Step 5 + 6.1 + 6.3 + 7 + 10, run inside the chroot.
configure_system() {
    log "configuring system in chroot"
    arch-chroot /mnt /bin/bash -euo pipefail <<CHROOT
echo "$TEST_HOST" > /etc/hostname
cat > /etc/hosts <<HOSTS
127.0.0.1   localhost
::1         localhost
127.0.1.1   $TEST_HOST.localdomain $TEST_HOST
HOSTS

ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf

echo "root:$TEST_PASS" | chpasswd
useradd -m -G wheel $TEST_USER
echo "$TEST_USER:$TEST_PASS" | chpasswd

# Step 6.1 — common packages
pacman -S --noconfirm --needed base-devel grub efibootmgr dosfstools mtools \
    networkmanager openssh sudo os-prober

# Step 6.3 — sudo for the wheel group
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
visudo -c || exit 1

# Step 10 — services
systemctl enable NetworkManager
systemctl enable sshd
CHROOT
}

# Step 7 + 8 — second kernel, microcode, GPU.
# Installing linux-lts triggers another mkinitcpio run and forces GRUB to generate a second
# set of entries, so this is load-bearing on every flow, not cosmetic.
install_kernels_and_gpu() {
    log "Step 7: LTS kernel + headers"
    arch-chroot /mnt pacman -S --noconfirm --needed linux-headers linux-lts linux-lts-headers \
        || die "kernel/header install failed"

    local uc=amd-ucode
    grep -q GenuineIntel /proc/cpuinfo && uc=intel-ucode
    log "Step 7: microcode ($uc)"
    arch-chroot /mnt pacman -S --noconfirm --needed "$uc" || die "microcode install failed"

    # Step 8. The guest has virtio-gpu, so mesa is the honest analogue here.
    # NVIDIA cannot be meaningfully exercised in QEMU — that needs real hardware.
    log "Step 8: mesa"
    arch-chroot /mnt pacman -S --noconfirm --needed mesa || die "mesa install failed"

    [ -f /mnt/boot/initramfs-linux-lts.img ] \
        || die "no LTS initramfs — the second kernel did not generate one"
    log "LTS initramfs present"
}

# Assert GRUB generated entries for BOTH kernels and is loading CPU microcode.
assert_grub_entries() {
    log "verifying GRUB entries"
    arch-chroot /mnt grep -q 'vmlinuz-linux-lts' /boot/grub/grub.cfg \
        || die "grub.cfg has no LTS kernel entry"
    arch-chroot /mnt grep -qE '(intel|amd)-ucode\.img' /boot/grub/grub.cfg \
        || die "grub.cfg does not load CPU microcode"
    log "GRUB has both kernels and microcode"
}

# base-install-*.md Step 9 — set HOOKS, then rebuild.
# $1 = the full HOOKS value for this path.
set_hooks() {
    local hooks="$1"
    log "HOOKS = $hooks"
    arch-chroot /mnt sed -i "s|^HOOKS=.*|HOOKS=($hooks)|" /etc/mkinitcpio.conf
    arch-chroot /mnt grep '^HOOKS' /etc/mkinitcpio.conf
    arch-chroot /mnt mkinitcpio -P || die "mkinitcpio failed — initramfs would be unbootable"
}

# Assert cryptsetup actually made it into the initramfs. This is the check that catches
# the single worst defect this test suite exists to prevent.
assert_cryptsetup_in_initramfs() {
    log "verifying cryptsetup is in the initramfs"
    arch-chroot /mnt lsinitcpio /boot/initramfs-linux.img | grep -q 'bin/cryptsetup' \
        || die "cryptsetup missing from initramfs — this system would never unlock"
    log "cryptsetup present"
}

# GRUB install + config.
# $1 = --efi-directory value, $2 = extra grub-install args, $3 = GRUB_CMDLINE_LINUX value
install_grub() {
    local efidir="$1" extra="${2:-}" cmdline="${3:-}"
    log "grub-install (efi-directory=$efidir)"
    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory="$efidir" \
        $extra --bootloader-id=GRUB --recheck || die "grub-install failed"

    # console=ttyS0 is TEST-ONLY: it puts a getty on the serial port so the harness can
    # see the login prompt. Do not copy this into the guide.
    arch-chroot /mnt sed -i \
        "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=4 console=tty0 console=ttyS0,115200\"|" \
        /etc/default/grub
    arch-chroot /mnt sed -i "s|^GRUB_TIMEOUT=.*|GRUB_TIMEOUT=1|" /etc/default/grub
    if [ -n "$cmdline" ]; then
        arch-chroot /mnt sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"$cmdline\"|" /etc/default/grub
        arch-chroot /mnt grep '^GRUB_CMDLINE_LINUX=' /etc/default/grub
    fi

    log "grub-mkconfig"
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg || die "grub-mkconfig failed"
}

finish() {
    log "unmounting"
    umount -R /mnt || true
    swapoff -a   || true
    echo "ARCHTEST: INSTALL COMPLETE"
    sync
    sleep 2
    poweroff -f
}
