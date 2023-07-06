---
layout: post
title:  "Embedded systems from ground up: Orange Pi"
date:   2023-07-03 08:06:00 -0300
categories: hardware embedded
tags: hardware embedded yocto
---

![orange pi one plus](/assets/img/orangepi.png){:width="50%"}

A few years ago, I bought this Orange Pi One Plus board because I wanted to turn it into an Android TV. There were 
some Android builds for it, but it didn't support Widevine, so Netflix wouldn't be possible. 

Anyways, getting any build for it was tricky back when I didn't have much knowledge on build systems and Linux.

But know I'm way more knowledgeable and adventurous and I decided to build Linux from scratch for it.

Well, not exactly from scratch: thankfully, most of the code for it has been sent upstream and there's a Yocto layer for
these devices [1] and I'm currently building on top of that [2].

I'm currently learning Yocto as I go, but it's pretty straightforward: clone layers as submodules and add them to your
bblayers.conf, other config to local.conf and if you need to overwrite a recipe, you add a `bb_append`. 

## Start here

For my Orange Pi One Plus repo, I've added the `poky` repo, which has the main toolchain and all the other stuff required to build anything with Yocto. All these repos are added as git submodules. 

After `poky` was cloned, I ran:

```sh
source poky/oe-init-build-env orange-pi-one-plus
```

And that created a conf directory under `orange-pi-one-plus` where I keep my bblayers.conf (where I reference all the layers that I want to build) and local.conf. 

Then I added `meta-sunxi` as a submodule and the dependencies: `meta-arm`, which has `u-boot` and `trusted-firmware-a`, and `meta-openembedded`, which has tools such as systemd.

After configuring the layers, it's time to bake your image! 

```sh
bitbake core-image-full-cmdline
```

You can have small images with just a console, or big images with display and wayland! More on that on [3].

This will compile a lot of stuff, but mostly Linux, trusted firmware and u-boot. 

In the end, a few images are generated. You can easily send them to an SD-Card with bmaptool. (There's an sd card image definition on a directory called wic, that has a wks file with instructions on how to partition the sd card). 

```sh
sudo bmaptool copy --bmap orange-pi-one-plus/tmp/deploy/images/orange-pi-one-plus/core-image-full-cmdline-orange-pi-one-plus.rootfs.wic.bmap orange-pi-one-plus/tmp/deploy/images/orange-pi-one-plus/core-image-full-cmdline-orange-pi-one-plus.rootfs.wic.gz /dev/sdX
```

Or if you just need to copy the bootloader: 

```sh
sudo dd if=../orange-pi-one-plus/tmp/deploy/images/orange-pi-one-plus/u-boot-sunxi-with-spl.bin of=/dev/sdb bs=1024 seek=8
```

BTW, I've been tweaking u-boot and arm-trusted-firmware quite a lot, so I needed to copy the git repo from u-boot. More on the tweaks on the Pitfalls section.

```sh
# Cloning the u-boot git repo
bitbake -c unpack virtual/bootloader

# Copy the u-boot git to somewhere else
# I do commits, generate patch files and apply these on a bbappend 
# on meta-sunxi
cp -a orange-pi-one-plus/tmp/work/orange_pi_one_plus-poky-linux/u-boot/1_2023.04-r0/git/ ../u-boot
```

Then, to compile just the tfa and bootloader, I can do this: 

```sh
# Clean the state for tfa
bitbake -ccleansstate trusted-firmware-a
# Clean the state for u-boot
bitbake -ccleansstate virtual/bootloader
# Compile u-boot (will compile tfa as it depends on it)
bitbake virtual/bootloader
```

Now that there's some understanding about the pipeline, let's go to the pitfalls! 

## Pitfalls

### Upstream-Status

The `meta-sunxi` layer applies some patches to u-boot that are not on the upstream using bbappends. However, the patches need the Upstream-Status tag before they can be applied. 

Some of the patch files had it missing, some had it lowercase, and they did not apply, so I changed that. [4] This is also a nice way of testing u-boot patches with Yocto! 

### bl31 Trying to boot from MMC1

After I had the image created and loaded to the SD card, I tried to boot it up. UART was connected to my USB-to-TTL adapter and picocom was running. Aaaand:

```
U-Boot SPL 2023.04-gfd4ed6b (Apr 03 2023 - 20:38:50 +0000)
DRAM: 1024 MiB
Trying to boot from MMC1
```

That was it... nothing else happened. I thought it was a problem with the kernel, but after some research I realized it was a problem with tfa. [5] Thanks to [6], I realized that the correct PLAT wasn't being passed on the 
bl31 make. After fixing it, trusted-firmware loaded! And so did the kernel. More details on [5]

### Ethernet not working

This one is currently ongoing: after I had everything setup, I realized that Ethernet wasn't working. Not only it wasn't loaded on Linux, but it also didn't work on the u-boot layer! 

This is currently being documented on [7] and [8].
 

> *_NOTE_* this post is being updated as I figure stuff out.

# References 

\[1] [meta-sunxi](https://github.com/linux-sunxi/meta-sunxi)

\[2] [orange-pi-one-plus-image](https://github.com/retpolanne/orange-pi-one-plus-image)

\[3] [Yocto Images](https://docs.yoctoproject.org/ref-manual/images.html)

\[4] [Fixes Upstream-Status lines in a few u-boot patches](https://github.com/linux-sunxi/meta-sunxi/commit/441baea0ef74bd5f81392102de782ca81898b83d)

\[5] [Should this generate an SD card image?](https://github.com/linux-sunxi/meta-sunxi/issues/386)

\[6] [U-boot not booting on H64 model B](https://forum.pine64.org/showthread.php?tid=15653)

\[7] [Ethernet not working on Orange Pi One Plus_](https://github.com/linux-sunxi/meta-sunxi/issues/387)

\[8] [[bug report] sunxi: H6: no ethernet on Orange Pi One Plus](https://lore.kernel.org/u-boot/d0427cea18fad6e36537931962fa5070b084045e.camel@collabora.com/T/#t)
