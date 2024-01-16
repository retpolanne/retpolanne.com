---
layout: post
title: "Orange Pi One Plus PHYnal Explanation"
date: 2023-12-15 18:58:45 -0300
categories: embedded-systems
tags: kernel-dev
---

After I've submitted the patch for the Orange Pi One Plus PHY, Andre Przywara made a few comments which were very insightful. The thread is in [1]

## Metal

According to Andre, Orange Pi One Plus uses two regulators for Ethernet: 3.3V (powered by the PMIC's ALDO2 rail) and a 
discrete 2.5V regulator, enabled by GPIO PD6, for the voltage level on the MDIO lines. There's also a reset line for the PHY held by a pull-up resistor, that is not described on the device tree.

## What is PHY after all?

Andre also sent me an amazing explanation about what is PHY. 

Let's take TTL - transistor-transistor logic, which we use in UART. 5V-0V logic works well for it, albeit quite slow. Let's imagine a big cable, 2 meters long, connected to the same UART and using the same TTL logic - that won't work, right? So we need PHYs. 

The MAC (which is the Ethernet device inside the SoC, in our case the Allwinner H6) generated the signal with correct timing and logic level (2.5V in our case) and PHY does the "linking", it talks to whatever is in the physical layer - fiber, coax, twisted pair copper cable, whatever.

## RGMII

What is MII? According to [2], it's a standard interface to connect Ethernet MAC block to a PHY chip. The standard is IEEE 802.3u (remember that from our DT's mdio node?)

 &mdio {
 	ext_rgmii_phy: ethernet-phy@1 {
		compatible = "ethernet-phy-ieee802.3-c22";
 		reg = <1>;
 	};
 };

There's a device called pinmux (pin multiplexer) that defines which signal gets connected to which pin. 

> This post is a work in progress and I'll update it as soon as I get more interesting stuff going on.

## FEL USB Boot

It's possible to boot the Orange Pi without an SD card by using FEL USB Boot!

```sh
git clone https://github.com/linux-sunxi/sunxi-tools
cd sunxi-tools
make
```

And then, on the bitbake workspace

```sh
cd tmp/deploy/images/orange-pi-one-plus/ 
# Booting only u-boot
sudo ~/Dev/sunxi-tools/sunxi-fel -v uboot u-boot-sunxi-with-spl.bin
```

## References

\[1] [arm64: dts: allwinner: Orange Pi One Plus PHY support](https://patchwork.kernel.org/project/linux-arm-kernel/patch/20231212122835.10850-2-retpolanne@posteo.net/)

\[2] [Media-independent interface](https://en.wikipedia.org/wiki/Media-independent_interface)
