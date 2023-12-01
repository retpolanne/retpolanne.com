---
layout: post
title: "Renesas Journey: Renesas strikes back"
date: 2023-11-27 18:54:01 -0300
categories: kernel-dev
tags: renesas
---

Things are going pretty well right now and I was encouraged on going back to my Renesas kernel module exploration by my 
awesome girlfriend, @madu.jar.

What do we want to prove: that the kernel module erases the ROM even when it's good to be loaded. We need to make it erase and redownload the ROM *only* if loading the module fails.

This is the plan: 

1. Setup a Yocto build for the Raspberry Pi CM4 (which has an amazing compute board with PCI express so I can easily test
the usb board.
    1.1. This Yocto build's Kernel config must have xhci and xhci-renesas enabled as modules, not as built-ins
    1.2. xhci-renesas and xhci must be blocklisted so I can enable these at any time
    1.3. we also need bpftrace support on the Yocto build
2. I have a brand new board using Renesas upd720201 chip, I need to extract its firmware before even starting it up
3. Make the change to not redownload the firmware
4. Run the bpftrace program that I made to track some xhci-pci-renesas module calls with the xhci-pci-renesas loaded *but not xhci-pci*. Then load xhci-pci and see what happens.
5. Redump the eeprom
6. Undo the change 
7. Run step 3 again
8. Redump the eeprom


# Yocto for raspberry pi - a story in commits

- [First commit](https://github.com/retpolanne/renesas-journey-rpicm4/commit/5482d3381cd1a535e52c3e668d00a896c68ef950): a skeleton for meta-raspberrypi and poky for the CM4

- I've been playing with the layers because getting recipes for bpftrace was hard - I finally found one [4]
    - `bitbake core-image-minimal`

- After we have a stable enough build, we can use `devtool deploy-target` to deploy changes made. We have openssh enabled btw.
    - `devtool deploy-target recipename root@raspberrypi4-64`

- Need to change the kconfig
    - set `CONFIG_USB_XHCI_PCI_RENESAS=m` and `CONFIG_USB_XHCI_PCI=m` and `CONFIG_UPROBE_EVENTS=y`
    - the documentation for menuconfig doesn't seem to work for this recipe. We can try to use devtool, which is quite handy
    - `devtool modify virtual/kernel` [1]
    - `devtool menuconfig linux-raspberrypi`
    - `bitbake -c savedefconfig virtual/kernel`
    - `devtool build linux-raspberrypi`

This bricked the board :c 
    - `devtool deploy-target linux-raspberrypi root@raspberrypi4-64 -s`

Sometimes my board just bricks and nothing shows up. This enables more log from boot [5]

I decided to add U-boot as well to the board, just in case I brick it again. It did brick again :c 

For some reason bpftrace was built with a different clang?

```sh
root@raspberrypi4-64:~# find / -name "*libclang.so*"
/usr/lib/libclang.so.14.0.6
root@raspberrypi4-64:~# ln -s /usr/lib/libclang.so.14.0.6 /usr/lib/libclang.so.13
```

This solved the issue I guess.

Trying to boot the board with the PCIe board in it made u-boot get stuck on "Starting Kernel".

Had to go back to the stock rpi firmware for PCIe to work.

Also added `loglevel=7` to /boot/cmdline to enable debug logs and `#define DEBUG` on the renesas module.

# Dumping the eeprom

I've got a board from AliExpress [2]. It has a D720201 chip from Renesas and a RC25Q4OE EEPROM.

Thankfully, this ROM is less exotic than the other one:

```
sudo ./flashrom --programmer ch341a_spi -r dump-newrenesas

flashrom 1.4.0-devel (git:) on Linux 6.4.4-arch1-1 (x86_64)
flashrom is free software, get the source code at https://flashrom.org

Using clock_gettime for delay loops (clk_id: 1, resolution: 1ns).
Found Eon flash chip "EN25F40" (512 kB, SPI) on ch341a_spi.
===
This flash part has status UNTESTED for operations: WP
The test status of this chip may have been updated in the latest development
version of flashrom. If you are running the latest development version,
please email a report to flashrom@flashrom.org if any of the above operations
work correctly for you with this flash chip. Please include the flashrom log
file for all operations you tested (see the man page for details), and mention
which mainboard or programmer you tested in the subject line.
Thanks for your help!
Reading flash... done.
```

# CM4 flashing

More info on [3].

For some reason I couldn't find the device on Linux. On Mac, I used `./rpiboot -d msd`

# Tracing the renesas board

With everything set-up, let's trace everything.

1. `modprobe xhci-pci-renesas`
2. `bpftrace renesas-bpftrace.bt`
3. `dmesg`
4. `modprobe xhci-pci`

And I saw this error:

```
[   55.671549] xhci_hcd 0000:01:00.0: failed to load firmware renesas_usb_fw.mem, fallback to ROM
```

Which meant that the board won't even try to download the firmware, so let's add a good firmware. I copied it from `/lib/firmware/renesas_usb_fw.mem` from my Arch machine.

## Digging into code

Before we load the kernel module, we see that 
```
setpci -v -s 01:00.0 f6.w
0000:01:00.0 @f6 = 8000
```

# Future work

- Check how to use devtool for faster development on the board (e.g. how to deploy kernel modules)

- Using yocto was quite annoying for this task, so I'm creating a new article where I'll be using kworkflow and raspbian.

# References

\[1] [Using devtool to modify recipes in Yocto](https://wiki.koansoftware.com/index.php/Using_devtool_to_modify_recipes_in_Yocto)
\[2] [USB 3.1 PCI Express AliExpress](https://pt.aliexpress.com/item/1005004250588136.html)
\[3] [How to flash Raspberry Pi OS onto the Compute Module 4 eMMC with usbboot](https://www.jeffgeerling.com/blog/2020/how-flash-raspberry-pi-os-compute-module-4-emmc-usbboot)
\[4] [bpftrace](https://layers.openembedded.org/layerindex/recipe/120241/)
\[5] [Modifying the bootloader configuration](https://www.raspberrypi.com/documentation/computers/compute-module.html#modifying-the-bootloader-configuration)
