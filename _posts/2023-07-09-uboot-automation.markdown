---
layout: post
title:  "Automate all the things: u-boot automated testing"
date:   2023-07-09 19:07:00 -0300
categories: hardware embedded test-automation
tags: hardware embedded yocto test-automation
---

I've spent the whole week trying to get ethernet to work on my Orange Pi One Plus (spoiler: it still doesn't work). My current pipeline is: 

1. Make changes to u-boot, commit, generate a patch, copy to meta-sunxi

2. Clean bitbake state for the bootloader and run bitbake

3. dd the deploy images to the sd-card

4. Put on the sdcard and turn on the board

This definitely involves a lot of mechanical steps which are getting quite annoying. For each defconfig changes, I need to do all of those things. 

My idea was to: 

1. Get the u-boot image using tftp and keep it on RAM

2. Take the u-boot image from RAM and use the mmc command to reflash the sd card

3. Put it on a script that runs every time u-boot starts

4. If tftp fails, do nothing (it's important to add some kind of print if a new image is loaded, to signal in case tftp fails)

Of course, the issue I'm having involves ethernet, so that is not going to work, buuuut I can try with my STM32 later. 

I also wanted to run tests on the board. Thankfully, there's a tool for that: tbot! [1] 

That looks so cool, I wonder if I can later make my own CI for u-boot using the boards I have :).

## tbot and testing ethernet

I decided to use tbot while I was developing the fix for ethernet on the Orange Pi One Plus. The tool is nice, and can integrate with Pytest.

First thing I did, following the documentation, was to create a config.py file. [2]

```py
import tbot
import time
from tbot.machine import board, connector

class OrangePi(
    connector.ConsoleConnector,
    board.Board
):
    baudrate = 115200
    serial_port = "/dev/ttyUSB0"

    def connect(self, mach):
        return mach.open_channel("picocom", "-b", str(self.baudrate), self.serial_port)


class OrangePiUBoot(
    board.Connector,
    board.PowerControl,
    board.UBootAutobootIntercept,
    board.UBootShell
):
    prompt = "=> "

    def poweron(self):
        time.sleep(1)
        self.ch.sendline("reset")

    def poweroff(self):
        pass


def register_machines(ctx):
    ctx.register(OrangePi, tbot.role.Board)
    ctx.register(OrangePiUBoot, tbot.role.BoardUBoot)
```

I need to refactor this a little bit, but OrangePi is the generic board that controls the connection to picocom and serial port. This is required to read logs from serial 
or send stuff to the u-boot shell. 

OrangePiUBoot is a little more specific to u-boot. It has board.UBootAutobootIntercept that sends a keyboard input when a message shows up on the logs (usually the default autoboot log message from u-boot). `prompt` will stop sending this keyboard input one it detects this prompt. 

board.PowerControl has two functions that can be implemented for poweron and poweroff procedures. For now, I just implement poweron with a reset command from u-boot, but I really want to use `uhubctl` [3] to control turning usb power on and off (but I need to figure out if there's any usb hub sold in Brazil that has vbus control). 

I also have a conftest.py on my repo for allowing pytest to work.

This is where I implement the tests [4] - I commented out regulator tests because I'm not focusing on it anymore:

```py
import tbot
import time


@tbot.testcase
def test_uboot_mdio_contains_phy() -> None:
    with tbot.ctx.request(tbot.role.BoardUBoot) as ub:
        mdio = ub.exec0("mdio", "list")
        assert "RealTek RTL8211E" in mdio

@tbot.testcase
def test_uboot_dhcp() -> None:
    with tbot.ctx.request(tbot.role.BoardUBoot) as ub:
        ub.exec0("setenv", "autoload", "no")
        ub.exec0("dhcp")

@tbot.testcase
def test_uboot_pinmux_pd6() -> None:
    with tbot.ctx.request(tbot.role.BoardUBoot) as ub:
        pinmux = ub.exec0("pinmux", "status", "PD6")
        assert "gpio output" in pinmux
```

The tests are quite simple: the first one checks whether Realtek PHY is in use. The second one runs dhcp and checks if the command returns a zero exit code.
The last one checks if the PD6 GPIO pin (that controls ethernet power) is in use. 

> *_NOTE_* this post is being updated as I figure stuff out.

# References 

\[1] [tbot](https://tbot.tools/)

\[2] [config.py](https://github.com/retpolanne/orange-pi-one-plus-image/blob/master/config/orange_pi_test_config.py)

\[3] [uhubctl](https://github.com/mvp/uhubctl)

\[4] [interactive.py](https://github.com/retpolanne/orange-pi-one-plus-image/blob/master/tc/interactive.py)
