#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"; mkdir -p cache; cd cache
N=${N:-3}
FIX_REPO=https://github.com/ealmloff/rust-hypervisor-firmware
FIX_BRANCH=one-request-per-efi-read

[ -x cloud-hypervisor ] || { curl -sSfL -o cloud-hypervisor https://github.com/cloud-hypervisor/cloud-hypervisor/releases/download/v53.0/cloud-hypervisor-static; chmod +x cloud-hypervisor; }
[ -f jammy.raw ] || { curl -sSfL -o jammy.img https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img; qemu-img convert -O raw jammy.img jammy.raw; rm jammy.img; }
[ -f fw-stock ] && [ -f fw-fixed ] || {
  [ -d rhf ] || git clone -q https://github.com/cloud-hypervisor/rust-hypervisor-firmware rhf
  build() {
    (cd rhf && cargo build -q --release --target x86_64-unknown-none.json -Zbuild-std=core -Zbuild-std-features=compiler-builtins-mem)
    cp rhf/target/x86_64-unknown-none/release/hypervisor-fw "$1"
  }
  git -C rhf fetch -q origin main && git -C rhf fetch -q "$FIX_REPO" "$FIX_BRANCH"
  git -C rhf checkout -qf "$(git -C rhf merge-base origin/main FETCH_HEAD)" && build fw-stock
  git -C rhf checkout -qf FETCH_HEAD && build fw-fixed
}

boot() {
  local t0 pid
  : > serial.log
  t0=$(date +%s.%N)
  ./cloud-hypervisor --kernel "$1" --disk path=jammy.raw --cpus boot=1 --memory size=1G --serial file=serial.log --console off >/dev/null 2>&1 &
  pid=$!
  until grep -aq "Linux version" serial.log; do sleep 0.02; done
  printf '%.2f' "$(echo "$(date +%s.%N) - $t0" | bc)"
  kill "$pid"; wait "$pid" 2>/dev/null || true
}

for fw in fw-stock fw-fixed; do
  printf '%-9s' "$fw"
  for i in $(seq "$N"); do printf ' %ss' "$(boot $fw)"; done
  echo
done
