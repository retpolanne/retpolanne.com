---
layout: post
title:  "Embedded systems from ground up: PHYnal Fantasy"
date:   2023-07-07 18:47:00 -0300
categories: hardware embedded
tags: hardware embedded yocto networking
---

On my last post about embedded systems and the Orange Pi One Plus, I mentioned that I was having trouble with ethernet. This is all documented on [1] and [2] but I wanted to document this in my blog as well.  

Basically, ethernet doesn't seem to work out of the box on the Orange Pi One Plus and on the upstream u-boot and I want to understand why. 

One thing I found out from the device dts: 

```
        reg_gmac_3v3: gmac-3v3 {
                compatible = "regulator-fixed";
                regulator-name = "vcc-gmac-3v3";
                regulator-min-microvolt = <3300000>;
                regulator-max-microvolt = <3300000>;
                startup-delay-us = <100000>;
                enable-active-high;
                gpio = <&pio 3 6 GPIO_ACTIVE_HIGH>; /* PD6 */
                vin-supply = <&reg_aldo2>;
        };
```

This is the definition of the voltage regulator for PHY. I still don't really understand what PHY is, but it is important for making ethernet work. This line: 

```
gpio = <&pio 3 6 GPIO_ACTIVE_HIGH>; /* PD6 */
```

is something that made me try a lot of things before reading the datasheet (always read the datasheet!). I saw this GPIO and thought "hey, let me short pin 3 and 6 and it will work". After some tries, it did, but I couldn't replicate, 
so I believe I just glitched the board. 

The datasheets and all the stuff related to this board is on a Google Drive [3]. Looking at the Allwinner H6 datasheet, I saw that the `GPIO3_6` (or PD6) was not accessible through the header, but it was accessible through u-boot.

I gave it a try, after a few reboots and with this config: 

```
u-boot config:

CONFIG_SPL_SPI_SUNXI=y
CONFIG_SUN8I_EMAC=y

tfa config:
SUNXI_SETUP_REGULATORS=1
```

I was able to get eth0 (and for some reason it only shows up after a lot of restarts). And then, on the shell:

```
gpio set pd6
```

After that, the LED on ethernet started blinking! However, the dhcp command failed... it worked once, I don't know how, but it fails consistently now. 

The Orange Pi One Plus has an interesting schematic that shows exactly this pinout. It's very hard to read and understand, but I'll make sense out of it soon:

![Orange Pi RGMII schematics](/assets/img/opischematics.png)

The EMAC section of the Allwinner H6 datasheet seems to match this pinout

![Allwinner H6 Datasheet](/assets/img/allwinner.png)

From the Realtek RTL8211E datasheet, I could figure out that MII is 100mbps while RGMII is gigabit. Interesting!

![Realtek RTL8211E datasheet](/assets/img/realtek.png)

Okay, so, when we enable the PD6 pin, what are we enabling on RGMII? To try to make sense, I made this spreadsheet:

![PHY pins](/assets/img/phypins.png)

Quite surprising why they use PD6 for voltage regulation. Strange, actually. I don't understand why.

LOL, the quick way to enable eth0 is to do a `mii dump` and let u-boot crash and restart.

I'm quite tired now, I'll leave this link in Chinese here \[4] (ps.: I should definitely continue studying Chinese!) which has some information about the LicheeZero u-boot ethernet. I believe they both have the same processor, so maybe its config
should have some clue. I need to rest now.

### Pinmux

After playing a lot with SPL and figuring out that SPL memory is too small, I decided to go back to playing with GPIO. One thing I found on u-boot is 

```
=> pinmux status PD6
PD6       : gpio input 
```

I noticed that PD6 wasn't on the pinout for `ext_rgmii_pins` in arch/arm/dts/sun50i-h6.dtsi and PD6 was showing on pinmux as disabled! After I added it, there was a function linked to it, but Ethernet still didn't work...

If I set PD6 to output and then back to input, the LEDs die... but it clearly says on the datasheet that this pin is input. Is it undocumented (since it's not even referenced on RGMII but on GMII instead)? 

PD6 is only defined on the `reg_gmac_3v3` block... why doesn't it enable stuff?

After carefully checking the Allwinner H6 datasheet and the Realtek, I noticed that, on the Realtek Datasheet, RXER is Output while on Allwinner it's Input! That explains why I need to enable it to output to make the port go alive?

I also noticed that it's only RXER for RMII, but for RGMII it's null! So that makes sense. Since it's not used, it's being used for some kind of voltage regulation. 

I've noticed that PD7 and others also make the LED turn on, but dhcp doesn't work and I see `sun8i_emac_eth_start: Timeout`.

Enabling PD7 and PD8 makes dhcp start! But I get no IP :(. 

After almost losing hope, I found this: `CONFIG_MACPWR`. [5] IT TURNED ETHERNET ON!!!!! I still get weird PHY errors, and I keep getting:

```
Net:   Could not get PHY for ethernet@5020000: addr 1
No ethernet found.
```

Changed the phy-mode on `arch/arm/dts/sun50i-h6-orangepi-one-plus.dts` to `rgmii` instead of `rgmii-id`. Still getting the error. It seems that `CONFIG_MACPWR` turned the PHY error pretty consistent :(

I also see these errors on dhcp:

```
=> dhcp 
mdio_register: non unique device name 'ethernet@5020000'
Could not get PHY for ethernet@5020000: addr 1
```

I wonder if I'm hitting this regression? [6]

### Back to DM

I've read in a couple of patches that we should focus on DM for loading stuff, so I'm trying to make the regulator-fixed work. The regulator-fixed was the part of the dts file that had the PD6 GPIO definition. 
I wonder if that regulator will in fact enable GPIO, but things are looking so strange. 

After I added `regulator-boot-on;` to arch/arm/dts/sun50i-h6-orangepi-one-plus.dts and crash-rebooted the device with `mii dump`, the Ethernet LED turned on :) at least one, the orange one didn't turn on...

I found out that there's a command that I can enable on u-boot using `CONFIG_CMD_REGULATOR`. Nice!

I tried to enable the regulator: 

```
=> regulator enable         
First, set the regulator device!
=> regulator dev vcc-gmac-3v3
dev: vcc-gmac-3v3 @ gmac-3v3
=> regulator enable          
=> dhcp
BOOTP broadcast 1
BOOTP broadcast 2
BOOTP broadcast 3
BOOTP broadcast 4
```

Yay! It's not getting an IP tho, but this may be for reasons.

## it's PHYnally over! 

I've made it! Patch is sent! 

The first thing I did was to focus on why ethernet initialization was so flaky (I would see the "Could not get PHY for ethernet@xxxxx" from time to time after reset. 
And also, I read that some TX and RX values that impacted dhcp from running
were fixed by the Realtek PHY driver, but I could never use it and driver initialization would always fallback to Generic PHY... strange! 

The code that printed this error was under `drivers/net/phy/phy.c` and I read it and added some print-debugs here and there.
 
The fun stuff is here:

```c
struct phy_device *phy_connect(struct mii_dev *bus, int addr,
			       struct udevice *dev,
			       phy_interface_t interface)
{
	struct phy_device *phydev = NULL;
	uint mask = (addr >= 0) ? (1 << addr) : 0xffffffff;

#ifdef CONFIG_PHY_FIXED
	phydev = phy_connect_fixed(bus, dev);
#endif

#ifdef CONFIG_PHY_NCSI
	if (!phydev && interface == PHY_INTERFACE_MODE_NCSI)
		phydev = phy_device_create(bus, 0, PHY_NCSI_ID, false);
#endif

#ifdef CONFIG_PHY_ETHERNET_ID
	if (!phydev)
		phydev = phy_connect_phy_id(bus, dev, addr);
#endif

#ifdef CONFIG_PHY_XILINX_GMII2RGMII
	if (!phydev)
		phydev = phy_connect_gmii2rgmii(bus, dev);
#endif

	if (!phydev)
		phydev = phy_find_by_mask(bus, mask);

	if (phydev)
		phy_connect_dev(phydev, dev, interface);
	else
		printf("Could not get PHY for %s: addr %d\n", bus->name, addr);
	return phydev;
}
```

I set this config `CONFIG_PHY_ETHERNET_ID` and I thought that it was going to work, but nah... but looking at the `phy_connect_phy_id`, it looks on the dts for which phy it should use. That's very cool, but it's not working for me. It should!

After some print-debugs, I figured out where things returned and it was in this function under `drivers/core/ofnode.c`.

```c
int ofnode_read_eth_phy_id(ofnode node, u16 *vendor, u16 *device)
{
	const char *list, *end;
	int len;

	list = ofnode_get_property(node, "compatible", &len);

	if (!list)
		return -ENOENT;

	end = list + len;
	while (list < end) {
		len = strlen(list);

		if (len >= strlen("ethernet-phy-idVVVV.DDDD")) {
			char *s = strstr(list, "ethernet-phy-id");

			/*
			 * check if the string is something like
			 * ethernet-phy-idVVVV.DDDD
			 */
			if (s && s[19] == '.') {
				s += strlen("ethernet-phy-id");
				*vendor = simple_strtol(s, NULL, 16);
				s += 5;
				*device = simple_strtol(s, NULL, 16);

				return 0;
			}
		}
		list += (len + 1);
	}

	return -ENOENT;
}
```

From what I understood, it lists all the compatible properties and try to match which driver is compatible with each compatible blog. Pay close attention to the format: 

```
ethernet-phy-idVVVV.DDDD
```

What we had on the Orange Pi One Plus dts was this: 

```
ethernet-phy-ieee802.3-c22
```

After searching for the VID.PID for the Realtek driver, I added this to the dts's PHY compatible line: `ethernet-phy-id001c.c915`. 

Also added these configs: 

```
# EMAC driver, needed for doing MAC stuff on sunxi
CONFIG_SUN8I_EMAC=y
# Load realtek phy driver
CONFIG_PHY_REALTEK=y
# Explained above
CONFIG_PHY_ETHERNET_ID=y
# This one is tricky: remember PD6? There are two ways to enable it: use this config
# or use a regulator.
# I still haven't figured out how to probe the regulator on u-boot, so I'm using this one.
CONFIG_MACPWR="PD6"
```

After sending the image to the SD-Card and turning the board on... I see eth0 being loaded... and mdio reports REALTEK PHY DRIVER! AND DHCP WORKS!!!

![DHCP Works!](/assets/img/orangepidhcp.jpg)

I'm so happy. Folks from meta-sunxi merged my patch and it was already sent to u-boot (currently waiting for approval).

Next steps: figure out stuff about the regulator, or why it isn't being probed.

This was a nice journey. On another post, I'll explain about tbot or how I did TDD on the u-boot layer.

# References 

\[1] [Ethernet not working on Orange Pi One Plus_](https://github.com/linux-sunxi/meta-sunxi/issues/387)

\[2] [[bug report] sunxi: H6: no ethernet on Orange Pi One Plus](https://lore.kernel.org/u-boot/d0427cea18fad6e36537931962fa5070b084045e.camel@collabora.com/T/#t)

\[3] [Orange Pi One Plus datasheets](https://drive.google.com/drive/folders/1i_jeJRCf0Sr5p62RMo5xodUwTFXELpEi)

\[4] [以太网使用指南](https://licheezero.readthedocs.io/zh/latest/%E9%A9%B1%E5%8A%A8/Ethernet.html#id1)

\[5] [[RFC,02/17] sunxi: remove CONFIG_MACPWR](https://patchwork.ozlabs.org/project/uboot/patch/20221206004549.29015-3-andre.przywara@arm.com/)

\[6] [[PATCH 0/2] sunxi: Fix Ethernet on mostly A20 boards](https://lore.kernel.org/u-boot/20220316005443.16260-1-andre.przywara@arm.com/)

\[7] [[PATCH] sunxi: H6: Enable Ethernet on Orange Pi One Plus](https://lore.kernel.org/u-boot/20230711003957.658805-2-retpolanne@posteo.net/T/#u)
