---
layout: post
title:  "Automate all the things: u-boot mmc and automated testing"
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

> *_NOTE_* this post is being updated as I figure stuff out.

# References 

\[1] [tbot](https://tbot.tools/)
