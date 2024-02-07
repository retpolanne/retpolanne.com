---
layout: post
title: "Gentoo on the iBook G4"
date: 2024-02-07 15:07:21 -0300
categories: retrocomputing
tags: linux gentoo ibook ppc
---

Lost everything: using an iBook G4 because I sold my M1 MBA lol. 

Getting Gentoo to boot is a little tricky. Preparing a usb boot is okay - just dd the 
Gentoo ppc image to the usb, no need to do any magic. 

To make it boot, I had to put the usb stick on the uppermost usb! If I put it elsewhere, 
on the boot choice screen, it won't boot. 

Now, I'm seeing the error `Invalid memory access` and I'm trying to figure out what might
be the problem - I then figured out I was using a 64 bit image on a 32 bit computer. :facepalm:

Boot options showed up by holding shift while booting grub, after a few seconds. 
