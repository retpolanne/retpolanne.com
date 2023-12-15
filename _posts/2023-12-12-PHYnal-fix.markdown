---
layout: post
title: "Orange Pi PHYnal Fix"
date: 2023-12-12 08:53:16 -0300
categories: embedded
tags: orangepi phy
---

I decided to get back into fixing the Orange Pi One Plus ethernet. 

My workflow is as follows: 

```sh
devtool modify virtual/kernel
devtool build linux-mainline
bitbake core-image-minimal
bmaptool copy --bmap orange-pi-one-plus/tmp/deploy/images/orange-pi-one-plus/core-image-minimal-orange-pi-one-plus.rootfs.wic.bmap orange-pi-one-plus/tmp/deploy/images/orange-pi-one-plus/core-image-minimal-orange-pi-one-plus.rootfs.wic.gz /tmp/opi
```

I removed this change [1] from meta-sunxi so that u-boot reports no ethernet and add the line

```
CORE_IMAGE_EXTRA_INSTALL += " kernel-modules"
```

So that the `dwmac-sun8i` kernel module starts. 

Without my change:

```
Configuring network interfaces... [    5.992589] dwmac-sun8i 5020000.ethernet eth0: Register MEM_TYPE_PAGE_POOL RxQ-0
[    6.000823] dwmac-sun8i 5020000.ethernet eth0: __stmmac_open: Cannot attach to PHY (error: -19)

ifconfig
lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
```

The ethernet LED blinks, but there's not PHY attached to it. 

It's also important to note that I reverted changes in U-boot, so there's no early ethernet :)

```
Net:   No ethernet found.
```

After my changes:

```
Configuring network interfaces... [    6.060020] dwmac-sun8i 5020000.ethernet eth0: Register MEM_TYPE_PAGE_POOL RxQ-0
[    6.069460] dwmac-sun8i 5020000.ethernet eth0: PHY [stmmac-0:01] driver [RTL8211E Gigabit Ethernet] (irq=POLL)
[    6.079547] dwmac-sun8i 5020000.ethernet eth0: No Safety Features support found
[    6.086879] dwmac-sun8i 5020000.ethernet eth0: No MAC Management Counters available
[    6.094553] dwmac-sun8i 5020000.ethernet eth0: PTP not supported by HW
[    6.101594] dwmac-sun8i 5020000.ethernet eth0: configuring for phy/rgmii-id link mode
```

## Formatting patch and sending email

```sh
git format-patch HEAD~1
./scripts/checkpatch.pl 0001-ARM64-dts-sunxi-Add-compatible-properties-to-Realtek.patch
# Send to myself
git send-email --to "Anne Macedo <retpolanne@posteo.net>" 0001-arm64-dts-allwinner-Orange-Pi-One-Plus-PHY-support.patch
```

## Lessons learned on PHYs and voltage regulators

Andre Przywara, who reviewed my patch, kindly explained a whole lot of things that I'm going to include on the next posts. See ya!

## References

\[1] [add u-boot ethernet support to orange pi one plus (h6) #389](https://github.com/linux-sunxi/meta-sunxi/pull/389/files)
