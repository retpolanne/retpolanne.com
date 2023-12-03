---
layout: post
title: "Renesas Journey: rpi cm4"
date: 2023-11-30 23:56:01 -0300
categories: kernel-dev
tags: renesas
---
I'll be using Raspbian, QEMU, virtio pci passthrough and kworkflow for my kernel dev environment on the Raspberry Pi CM4.

Installed packages:

```sh
sudo apt install git bc bison flex libssl-dev make debootstrap qemu-system-arm
```

Followed my debootstrap script from the first post, changing amd64 to arm64.

```sh
#!/bin/bash

qemu-img create debootstrap.img 1g
mkfs.ext2 debootstrap.img
mkdir tmp-mount
sudo mount -o loop debootstrap.img tmp-mount
sudo debootstrap --arch arm64 bookworm tmp-mount
sudo umount tmp-mount
rmdir tmp-mount
```

I can't seem to find the vfio_pci driver on Raspbian, this is how I check the kconfig:

```sh
sudo modprobe configs
zcat /proc/config.gz
```

I have to recompile the kernel for the CM4 following this tutorial [1], enable `CONFIG_VFIO` and use pci passthrough on QEMU.

For the QEMU kernel, I did the following: 

```sh
make defconfig
make kvm_guest.config
```

And added the following configs:

```sh
CONFIG_UPROBE_EVENTS=y
CONFIG_KPROBES=y
CONFIG_USB_XHCI_HCD=y
# CONFIG_USB_XHCI_DBGCAP is not set
CONFIG_USB_XHCI_PCI=y
CONFIG_USB_XHCI_PCI_RENESAS=y
CONFIG_USB_XHCI_PLATFORM=y
```

Can't compile XHCI_PCI as modules because we're testing using QEMU.

I should also compile my host kernel with XHCI_PCI as module and blacklist it, so it doesn't initialize the pci device. 

```
CONFIG_USB_XHCI_PCI=n
```

To make a initramfs:
```sh
mkinitramfs -o ramdisk.img 6.1.0-rpi4-rpi-v8
```

It... doesn't boot?

```
retpolanne@navi:~/linux $ gdb -q vmlinux
Reading symbols from vmlinux...
(gdb) show architecture
The target architecture is set to "auto" (currently "aarch64").
(gdb) set architecture armv8-a
The target architecture is set to "arm".
(gdb) target remote :1234
Remote debugging using :1234
0x40000000 in ?? ()
(gdb) 
```

In the end, I had to change the serial device to ttyAMA0 instead of ttyS0 and it showed up stuff.

```sh
qemu-system-aarch64 \
    -M virt \
    -m 1G \
    -append "root=/dev/sda console=ttyAMA0" \
    -hda debootstrap.img \
    -kernel linux/arch/arm64/boot/Image \
    -initrd ramdisk.img \
    -serial stdio \
    -display none \
    -cpu cortex-a72
```

However, /dev/sda is missing. Need to enable something in the kernel.

[2]
```
Thanks for the link. This is great. I have now hdd recognized. I had everything else included apart from "Enable SYM53C8XX Version 2 SCSI Support". Once I included it, /dev/sda is available.
```

I tried this and it didn't work. 

```
(initramfs) ls /dev/disk/by-uuid/21e3fd4e-278f-4e27-a3fa-abf88ed5156f 
/dev/disk/by-uuid/21e3fd4e-278f-4e27-a3fa-abf88ed5156f
NAME      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
mtdblock0  31:0    0  128M  0 disk 
vda       254:0    0    1G  0 disk 
(initramfs) blkid
/dev/vda: UUID="21e3fd4e-278f-4e27-a3fa-abf88ed5156f" BLOCK_SIZE="4096" TYPE="ext2"
```

We're not using either sda or hda, but vda.

```sh
qemu-system-aarch64 \
    -M virt \
    -m 1G \
    -append "root=/dev/vda console=ttyAMA0" \
    -hda debootstrap.img \
    -kernel linux/arch/arm64/boot/Image \
    -initrd ramdisk.img \
    -serial stdio \
    -display none \
    -cpu cortex-a72
```

QEMU seems incredibly slow, let's use an accelerator!

```sh
qemu-system-aarch64 -accel help
Accelerators supported in QEMU binary:
kvm
tcg
sudo adduser retpolanne kvm
# Exit your shell and open it again
```

Accelerated QEMU: 

```sh
qemu-system-aarch64 \
    -M virt,accel=kvm \
    -m 1500M \
    -append "root=/dev/vda console=ttyAMA0" \
    -drive format=raw,media=disk,file=debootstrap.img \
    -kernel linux/arch/arm64/boot/Image \
    -initrd ramdisk.img \
    -serial stdio \
    -display none \
    -cpu host
```

Let's add some networking - bear in mind that I've added the ssh server by chrooting onto debootstrap:

```sh
qemu-system-aarch64 \
    -M virt,accel=kvm \
    -m 1500M \
    -append "root=/dev/vda console=ttyAMA0" \
    -drive format=raw,media=disk,file=debootstrap.img \
    -kernel linux/arch/arm64/boot/Image \
    -initrd ramdisk.img \
    -serial stdio \
    -display none \
    -netdev user,id=net0,hostfwd=tcp::8022-:22 \
    -device virtio-net-pci,netdev=net0 \
    -cpu host
```

Added the following to `/etc/network/interfaces`

```
allow-hotplug enp0s1
iface enp0s1 inet dhcp
```

## Time to debug! 

I plugged in the PCIe card to my board and... it doesn't boot? Why?

[3] gives some insights on a kernel bug regarding the same board I'm using and related to PCIe. 
It's and interesting peek at how kernel devs work. Adding `earlycon` to my cmdline helped to show more logs on the failing state. 

To fix... I believe I compiled the wrong upstream heh. 

Other thing that is strange is that one of my PCIe cards yield a kernel panic. Seems similar to [4], but I couldn't reproduce it anymore.

Anyways, let's get this analysis started: 

Test with the new card I got, uninitialized.

```sh
setpci -v -s 01:00.0 f6.w
0000:01:00.0 @f6 = ffff
```

Test with the old card, uninitialized:

```sh
setpci -v -s 01:00.0 f6.w
0000:01:00.0 @f6 = ffff
```

Can't use vfio_pci :( no IOMMUs.

```sh
root@navi:~# echo "0000:01:00.0" > /sys/bus/pci/drivers/vfio-pci/bind
-bash: echo: write error: Invalid argument
root@navi:~# shopt -s nullglob
for g in $(find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V); do
    echo "IOMMU Group ${g##*/}:"
    for d in $g/devices/*; do
        echo -e "\t$(lspci -nns ${d##*/})"
    done;
done;
IOMMU Group .:
```

```sh
echo "1912 0014" > /sys/bus/pci/drivers/vfio-pci/new_id
echo 0000:01:00.0 > /sys/bus/pci/devices/0000:01:00.0/driver/unbind
echo 1 > /sys/module/vfio/parameters/enable_unsafe_noiommu_mode
echo "0000:01:00.0" > /sys/bus/pci/drivers/vfio-pci/bind
sudo ln -s /dev/vfio/noiommu-0 /dev/vfio/0
```

[4] \[5] is interesting because it explains why No-IOMMU and vfio don't match (due to not having protected DMA or something).

I think I hit a wall because RPI CM4 doesn't support IOMMU and qemu doesn't support no-IOMMU :C

I'll use the RPI CM4 as a worker for kernel testing using OpenOCD and JTAG. See you next time!

# References
\[1] [The Linux kernel](https://www.raspberrypi.com/documentation/computers/linux_kernel.html)

\[2] [Re: [Qemu-devel] QEMU 1.2.0 -hda option not working](https://lists.gnu.org/archive/html/qemu-devel/2012-11/msg00766.html)

\[3] [PCIe regression on Raspberry Pi Compute Module 4 (CM4) breaks booting](https://bugzilla.kernel.org/show_bug.cgi?id=215925)

\[4] [Kernel panic - not syncing: Asynchronous SError Interrupt (brcm_pcie_probe), with Raspberry Pi CM4 + PCIe setups](https://bugzilla.kernel.org/show_bug.cgi?id=217276)

\[5] [[PATCH/RFC,4/5] vfio: No-IOMMU mode support](https://patchwork.kernel.org/project/linux-renesas-soc/patch/1518189456-2873-5-git-send-email-geert+renesas@glider.be/)

\[6] [Getting To Blinky: Virt Edition](https://archive.fosdem.org/2019/schedule/event/vai_getting_to_blinky/attachments/slides/2997/export/events/attachments/vai_getting_to_blinky/slides/2997/Getting_To_Blinky_Virt_Edition_Handouts.pdf)
