# firmware-timing

hypervisor-fw serves GRUB's EFI block reads one 512 B sector per virtio request.

`./run.sh`: time from VM start to the first kernel line, stock Ubuntu jammy raw image, cloud-hypervisor v53.
`fw-fixed` is [ealmloff/rust-hypervisor-firmware@one-request-per-efi-read](https://github.com/ealmloff/rust-hypervisor-firmware/tree/one-request-per-efi-read); `fw-stock` is upstream [rust-hypervisor-firmware](https://github.com/cloud-hypervisor/rust-hypervisor-firmware) at that branch's merge base with `main`.

Needs `/dev/kvm`, `curl`, `qemu-img`, `rustup`.
