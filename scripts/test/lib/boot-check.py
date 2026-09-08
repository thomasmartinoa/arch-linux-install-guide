#!/usr/bin/env python3
"""Pass 2: boot the installed disk and assert it reaches a login prompt.

For encrypted paths, waits for the LUKS passphrase prompt and types the passphrase.
Exits 0 only if `login:` appears on the serial console within the timeout.
"""
import argparse, os, re, subprocess, sys, time

LOGIN   = re.compile(rb"(archtest login:|login:)", re.I)
PASSPHR = re.compile(rb"(enter passphrase|a password is required)", re.I)
PANIC   = re.compile(rb"(Kernel panic|Failed to mount|emergency mode|"
                     rb"You are in emergency shell|Entering emergency mode)", re.I)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--disk", required=True)
    ap.add_argument("--ovmf-code", required=True)
    ap.add_argument("--ovmf-vars", required=True)
    ap.add_argument("--passphrase", default=None, help="send when LUKS prompts")
    ap.add_argument("--timeout", type=int, default=300)
    ap.add_argument("--log", required=True)
    ap.add_argument("--memory", default="2048")
    a = ap.parse_args()

    cmd = [
        "qemu-system-x86_64",
        "-machine", "q35" + (",accel=kvm" if os.access("/dev/kvm", os.W_OK) else ""),
        "-cpu", "host" if os.access("/dev/kvm", os.W_OK) else "qemu64",
        "-m", a.memory, "-smp", "2",
        "-drive", f"if=pflash,format=raw,readonly=on,file={a.ovmf_code}",
        "-drive", f"if=pflash,format=raw,file={a.ovmf_vars}",
        "-drive", f"file={a.disk},if=virtio,format=qcow2",
        "-netdev", "user,id=n0", "-device", "virtio-net-pci,netdev=n0",
        "-display", "none", "-serial", "stdio", "-no-reboot",
    ]

    print(f"[pass2] booting installed system (timeout {a.timeout}s)", flush=True)
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, bufsize=0)

    deadline = time.time() + a.timeout
    buf, sent_pass, result = b"", False, 1
    try:
        with open(a.log, "wb") as logf:
            os.set_blocking(proc.stdout.fileno(), False)
            while time.time() < deadline:
                if proc.poll() is not None:
                    chunk = proc.stdout.read() or b""
                    buf += chunk; logf.write(chunk); logf.flush()
                    print("[pass2] FAIL: qemu exited before a login prompt", flush=True)
                    break
                chunk = proc.stdout.read(4096)
                if not chunk:
                    time.sleep(0.2); continue
                buf += chunk
                logf.write(chunk); logf.flush()
                sys.stdout.buffer.write(chunk); sys.stdout.flush()

                tail = buf[-4096:]
                if a.passphrase and not sent_pass and PASSPHR.search(tail):
                    print("\n[pass2] LUKS prompt seen — sending passphrase", flush=True)
                    time.sleep(1)
                    proc.stdin.write(a.passphrase.encode() + b"\n"); proc.stdin.flush()
                    sent_pass = True
                    buf = b""            # don't re-match the same prompt
                    continue
                if PANIC.search(tail):
                    print("\n[pass2] FAIL: kernel panic / emergency mode", flush=True)
                    break
                if LOGIN.search(tail):
                    print("\n[pass2] PASS: reached login prompt", flush=True)
                    result = 0
                    break
            else:
                print(f"\n[pass2] FAIL: timed out after {a.timeout}s", flush=True)

        if a.passphrase and not sent_pass and result == 0:
            print("[pass2] FAIL: encrypted path never asked for a passphrase", flush=True)
            result = 1
    finally:
        proc.kill()
        try:
            proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            pass
    return result


if __name__ == "__main__":
    sys.exit(main())
