---
layout: post
title:  "Wannabe Linux Kernel Developer Diary - Entry 1"
date:   2022-09-09 19:21:00 -0300
categories: kernel-dev
---

# Wannabe Linux Kernel Developer Diary - Entry 1

So, I want to become a Kernel Developer. Ambitious, right? Well, it is.

FOSS (Free Open Source Software) development is usually hard enough. For me, finding something that I could work on was pretty difficult, but that didn't stop me. Sometimes you go after bugs, sometimes they come to you.

This is what happened when I opened this PR on pip: [pip #6203](https://github.com/pypa/pip/pull/6203). In most projects, contributing is fairly straightforward: you go on GitHub, you open an issue or check whether there's any issue available for you to work on, and then you open a PR. Maintainers comment on that, you make changes, and if they're happy enough it gets merged to main.

Well, Linux is not this way!

The barrier to entry is way higher, so I'm making this diary to document my journey through the kernel. I hope that this helps other people willing to start contributing to the kernel as well.

---

## But why contribute to the Linux kernel?

The world runs on Linux. I mean, I like Windows and macOS, they are great. But everybody uses Linux directly or indirectly: if you have an Android phone, you are a Linux user; if you have a favorite website, chances are it runs on Linux as well.

Ever since I was a kid, I always liked operating systems. I've always wanted to understand how they're able make that bunch of silicon and other metals and that bunch of electrical pulses be able to run programs. So I started digging deeper and began to understand how kernels worked, starting with Windows and then moving to macOS and Linux.

I found myself in Linux when I started using bash while working as a Python developer. With some more knowledgeable colleagues as mentors, I started to dig a little more into how the kernel worked and which tools were available at my disposal.

Working mosly with Kubernetes made me understand a little more about how it worked as well, since most of the Kubernetes features rely heavily on Linux: containers are basically cgroups and namespaces, kube-proxy is basically iptables, that kind of stuff.

Now I'm mostly learning eBPF, which is just another tool in the Linux toolbox for improving network connectivity, observability and security. The cloud native community has been hyping it and it is something really interesting.

---

## Tips on how to start

These are a few tips that I've gotten from fellow Linux contributors.

1. Find something to study and focus on that.

    The kernel is extensive, has millions of lines of code and a lot of drivers for different kinds of hardwares. I bet your smart lights, your Alexa and your TV are probably running on Linux, so they need to have the appropriate drivers. Understanding the whole kernel is impossible, not even Linus knows everything. So find something to focus on.

    I've decided to focus on two things: bpf – a new and really interesting technology that gives Linux superpowers –, and cgroups – the technology behind containers that powers Kubernetes.

2. Find a subsystem and its respective mailing list

    Now that you have something that you want to work on, don't rush things! Take some good amount of time checking what people are doing in the desired subsystem. You can find the mailing lists here: [Mailing lists](http://vger.kernel.org/vger-lists.html).

    I highly recommend checking the archives as well. This is the one for bpf: [bpf mailing list](https://lore.kernel.org/bpf/)

3. Subscribing to the list

    I've used Gmail to subscribe. This is not ideal, unfortunately, since Gmail blocks clients such as mutt that help a lot to check patches on the mailing list. But anyways, you can do it. You need to send an email to majordomo@vger.kernel.org [as plain text](https://www.lifewire.com/how-to-send-a-message-in-plain-text-from-gmail-1171963), **without a subject line**, with the content:


    subscribe subsystem


    For example, for bpf, you write:


    subscribe bpf


    Before doing that, I advise you to create a filter, since you'll receive lots of emails. After that, you'll receive an email confirming your subscription and you'll need to send a reply as plain text with the auth token on the instructions.

    Spend a few days or weeks checking the patches and the conversations that happen on the list.

4. Cloning and compiling the kernel

    I advise you to do this step on a virtual machine.

    Follow this tutorial made by folks at USP (Universidade de São Paulo) on how to clone and compile the kernel. [Tutorial](https://flusp.ime.usp.br/kernel/Kernel-compilation-and-installation/)

    A big mistake I made when I first compiled the kernel: I didn't fine tune the config and enabled a bunch of modules that weren't necessary. Properly creating a config is essential for reducing the build time and size of the compiled kernel!

5. Check more resources down below

## More resources

Kernel Documentation, which is extensive. Here's a doc on how to contribute to the kernel: [HOWTO](https://www.kernel.org/doc/html/v4.16/process/howto.html)

LWN.net, where you can find news from the source: [LWN](https://lwn.net)

Kernel Newbies Project: [Kernel Newbies](https://kernelnewbies.org)

FLUSP - FLOSS at USP: [FLUSP](https://flusp.ime.usp.br)

Linux Foundation Training on Linux Kernel Development: [Linux Foundation](https://training.linuxfoundation.org/training/a-beginners-guide-to-linux-kernel-development-lfd103/)

Linux Device Drivers book [LDD3](https://lwn.net/Kernel/LDD3/)

Special thanks to @isinyaaa for reviewing this text and giving me a bunch of tips.
