---
layout: post
title: "My journey on kernel dev so far"
date: 2024-02-28 13:51:54 -0300
categories: kernel-dev
tags: linux kernel development emacs
---

Back in September 2022, I wrote this blogpost [1] about how to start learning about kernel development. A year and a few months later,
I'm still learning a lot.

Here I'll talk about some things that helped (and some others that didn't help at all).

## Test on weird hardware

Finding opportunities to contribute and to study is hard. However, Linux can run everywhere, but not perfectly. It's up to you to make 
Linux better. So testing on the weirdest hardware is crucial. 

I found two great opportunities to learn when I started, the first one was a bug on xhci-pci-renesas triggered by an obscure Chinese
chip and the other was getting ethernet to work on my Orange Pi One Plus. I also want to start learning a little bit about Linux on 
RISCV, so I should be testing Allwinner D1 soon.

These are probably the best ways to find work to do.

## Make your own dotfiles

Dotfiles are cool. I have my own dotfiles scripts to ease my life, especially when changing computers, setting new VMs, etc. 
My dotfiles for kernel dev are here on [4] and my dotfiles for my Mac on [5].

## Yocto is not ideal for kernel development

For embedded kernel development, I started using Yocto because I thought it was easy. Big mistake: 

Yocto adds a layer of complexity that you don't need if you're just compiling, hacking and testing the kernel. It hides the complexity 
of kernel compilation and customization in a way that is difficult to work with sometimes. 

If you're doing embedded kernel development, try making your own suite of tools, repos and scripts [2]. This way, you'll learn a lot and
you'll create better workflows for development.

Also, read Bootlin's embedded Linux training to understand more about it [3].

## Emacs (and Doom) is perfect

I used to be a VIM user, but switching to emacs was the greatest thing I did. I understand that UNIX philosophy is writing software that 
does one thing really well, and vi/vim does text editing really well. However, you can do everything on emacs, and you can do a lot of
things that are required for kernel devs: 

- You can read and send emails on emacs (plain text, yay)
- You can use irc on emacs
- You can use your terminal on emacs
- You can code on emacs

I don't really recommend using vanilla emacs as a newcomer, but I definitely think that Doom should be a middle ground and 
gateway into learning real emacs.

Doom, for me, was simply perfect. It's not as bloaty as VSCode, I can run it on a terminal, it's easy to configure, it leverages
emacs customizable environment but with a lot of abstractions to make it easy to use. And it also features evil mode :). 

## You're still learning, even if someone finishes your work before you do

I've spend a good amount of hours debugging the Orange Pi One Plus PHY support and then someone came up with a patch that added support
for what I was debugging. If that happens to you, don't be mad: you still learned a lot. Debugging is a very important skill that you can
improve by testing stuff.

## A good processor matters a lot

I used to work on a Ryzen 5 gaming PC that I recently sold to someone (I wasn't so much into gaming anyways). Kernel compilation and 
Yocto builds would take up to 45 minutes. Now that I've switched to the MacBook Pro M3 Pro (running Debian on Apple's hypervisor framework), ditched Yocto in favor of my own build scripts, used the correct defconfig, kernel compilation takes about 6 minutes or so!

That makes my workflow way more productive! 

Well, these are a few tips from my kernel dev journey so far. I hope these are as useful to newcomers as they were for me.

## Links

[1] https://blog.retpolanne.com/kernel-dev/2022/09/09/wannabe-kernel-dev-entry-1.html

[2] https://github.com/retpolanne/embedded-linux-workspace

[3] https://bootlin.com/training/embedded-linux/

[4] https://github.com/retpolanne/embedded-linux-workspace/tree/master/dotfiles-kerneldev

[5] https://github.com/retpolanne/dotfiles/tree/personal-mbp
