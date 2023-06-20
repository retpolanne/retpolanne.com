---
layout: post
title: "Wannabe Linux Lernel Developer Diary - Entry 2"
date: 2022-09-21 20:01:10 -0300
categories: kernel-dev
---

# Wannabe Linux Kernel Developer Diary - Entry 2

First of all, I would like to thank everybody who hyped my post: the ones who liked it on Linkedin, the folks from FLUSP and LKCAMP, everybody who reviewed the first entry, sent me feedbacks, etc. You folks are AMAZING, and it really motivated me into continuing this journey. I can't believe how much I've learned about the kernel throughout these weeks. You motivated me so much. Thank you so much! 

And thanks to the Linux folks who work at my employer. I think I'm in the right path to become a full-time kernel developer at some point :)

\#careergoals

This is the second entry of my Wannabe Linux Kernel Developer Diary – the first one can be found [here]({% post_url 2022-09-09-wannabe-kernel-dev-entry-1 %}). I think this one will become more like a log and less like an inspiring post. 

## What have I navigated through recently?

Most of the links that I'm going to add here are raw notes that I've been keeping in case I come across the same issues again. 
They exist mostly for making stuff "googleable". 

I wrote a post about how to setup your QEMU for kernel development. Using QEMU is amazing for testing the kernel. For now I'm just using it as just another VM, but QEMU has a bunch of tools to help you test and debug the kernel. Read about it [here]({% post_url 2022-09-09-qemu-pain %}).

I also tried to run the bpf selftests and, after a bunch of failures, I was able to make them work :) . Read about it [here]({% post_url 2022-09-10-bpf-dev %})

I also learned something about naming on the DCO (Developer Certificate of Origin) while researching if I could use my preferred name for contributions. Turns out I was able to beat the anxiety and started to change my preferred name on my employer's systems. More about naming [here]({% post_url 2022-09-19-naming-issues %})

And, last but not least, I created a repo with all the tools and resources that a beginner kernel dev like me may need: [awesome-kerneldev](https://github.com/retpolanne/awesome-kerneldev).

## Looking for work

So, I've spent a considerable amount of time lurking on the bpf mailing list. The discussions there are interesting and by checking the lists I was able to understand more or less what folks are working on and what is the mailing etiquette that you must have. Also, seeing the patches made me understand more about bits of the code that I wouldn't understand if I just stared at it. 

One interesting patch was made by a coworker, where they propose an overwritable ring buffer for bpf. The patch is described [here](https://lore.kernel.org/bpf/20220906195656.33021-1-flaniel@linux.microsoft.com/). I won't really explain the patch (I don't understand it 100%), but I love how easy it is to understand the concept behind it. In case you're interested, you can check about circular buffers on the [kernel documentation](https://www.kernel.org/doc/html/latest/core-api/circular-buffers.html).

Aside from that, I found places where I can find possible bugs to work on.

- [bcc](https://github.com/iovisor/bcc/issues), which is a repo for a bpf compiler. Since bpf depends a lot on the kernel, bugs may show up there.

- [libbpf](https://github.com/libbpf/libbpf), which is actually a mirror of tools/lib/bpf and where some oss-fuzz bugs show up. I researched one of these bugs [here]({% post_url 2022-09-17-bpf-ossfuzz %}) 

- [KSPP Linux](https://github.com/KSPP/linux/issues), which is the Kernel Self Protection Project, and has a bunch of issues related to security and hardening.

- [syzcaller](https://syzkaller.appspot.com/upstream), a bot by Google that runs a Kernel CI and reports bugs. 

## Motivation and limits

One important thing about this journey is respecting my limits and keeping myself motivated. For now, even though I'm really focused on bpf, sometimes I sidetrack into architecture (especially now that I have a new toy – a M1 MacBook Air), security, compilers, etc. That sometimes means that I have to fight with myself to narrow my focus on a single thing. And it takes time to start working and understanding a specific subsystem. 

My recommendation is: KISS (Keep it simple, stupid). Don't try to grasp the whole picture. And be patient. Trust your process. 

I've been surfing through this learning curve that is developing to the kernel, and at the rate I'm currently at, I should be working on my first patches in no time. 

It's also important to remind myself to rest. Aside from kernel development, I'm studying Spanish and Mandarin (mostly because of the chinese kernel community). Sometimes I'm not in the mood for doing anything, so I don't push myself so hard. I just rest and try my best not to turn on the computer. 

Taking small bytes of knowledge everyday also help me a lot. When I'm too tired or when I don't have plenty of time available, I try to check new small patches on the bpf list and try to understand them in a couple of minutes. That way, I'm also studying small bytes of code everyday. 

Thanks for being part of this journey! See you next time. 
