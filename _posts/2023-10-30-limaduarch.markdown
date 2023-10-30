---
layout: post
title: "Lima DuArch - Arch Linux ARM on Mac M1 using Lima"
date: 2023-10-30 18:30:55 -0300
categories: virtualization
tags: qemu virtualization lima
---

Although I'm quite fond of my MacBook Air M1 and the sleek design of the macOS, I love to work with the freedom Linux
can offer. Linux is not my daily driver, but it powers so much stuff for me. Without Linux, there wouldn't be containers 
on my Mac, for example. Not only I like to work with Linux, but often times **I have to work with Linux**, e.g. if I'm doing 
kernel dev or yocto baking. If I could combine the sleek design of the Mac with the power of Linux, I will definitely have 
a better time with my projects :). 

I didn't want to install Asahi Linux on my Mac because I don't really want to switch to Linux as my daily driver. So, I decided 
to use VMs instead. 

About a year ago, Docker for Mac had a change in licensing, so I couldn't use it on my work laptop anymore. The other option was
colima [1], which runs on top of Lima (Linux Virtual Machines) [2]. Lima is really interesting because it's a wrapper for 
complicated stuff such as QEMU, featuring some automations based on cloud-init [3] for SSH support. 

With Lima, spinning up a VM running Arch Linux ARM on the Mac M1 is as easy as:

```sh
limactl create https://raw.githubusercontent.com/retpolanne/qemu-archlinux-arm/main/archlinux-lima.yaml
```

Behind the scenes, things are not so pretty though. 

## Arch Boxes and Arch Linux ARM

[4] contains my fork of the arch-boxes repo in a branch for aarch64. The commits look ugly, sorry, but basically I've added 
Arch Linux ARM support to the arch-boxes and used the existing pipeline to bake this images. 

I had to make plenty of changes, such as changing the pacman repos, packaging my own cloud-init (since it wasn't available on 
the Arch Linux ARM repo) and installing from that package. 

I've also added a runner that is a qemu VM running arch that I created solely for this purpose. I explain how to do this on [5].

The cloud-init package fork is on [6]. I basically removed netplan due to it not being fully supported on ARM (depends on haskell
[7]).

After sorting out all the scripts, I was left with a qcow image for Arch Linux ARM with cloud-init installed :) 

Enjoy! 


## References

\[1] [colima](https://github.com/abiosoft/colima)
\[2] [lima](https://github.com/lima-vm/lima)
\[3] [cloud-init](https://cloud-init.readthedocs.io/en/latest/index.html)
\[4] [arch-boxes aarch64](https://gitlab.archlinux.org/retpolanne/arch-boxes/-/tree/aarch64?ref_type=heads)
\[5] [qemu-archlinux-arm](https://github.com/retpolanne/qemu-archlinux-arm)
\[6] [cloud-init aarch64](https://gitlab.archlinux.org/retpolanne/cloud-init)
\[7] [The state of GHC on ARM](https://www.haskell.org/ghc/blog/20200515-ghc-on-arm.html)
