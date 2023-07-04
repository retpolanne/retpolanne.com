---
layout: post
title:  "Embedded systems from ground up: OpenVPN using OrangePi"
date:   2023-07-03 08:06:00 -0300
categories: hardware embedded
tags: hardware embedded yocto ansible
---

I have a problem: sometimes I'm on the flow doing something in my local network (such as SSHing to my Linux box for kernel dev) and 
then I have to be on the go (medical appointments, laser hair removal, etc) and I want to bring my iPad or my Mac so I can continue 
working. Currently, in order to be able to access my network, I enable DNAT to my local machine and with SSH open and pray so that 
no one tries to hack me. 

Then yesterday I had an idea: why don't I build a OpenVPN?

I have a spare OrangePi One Plus, which I barely used because I didn't know so much about Linux compilation and because the sdk was 
a little cumbersome. But now I can try to use it! 

## The project

Here are the requirements of the project: 

1. I should be using Yocto to build the Linux image.
2. I need systemd, python, openssh (with the currently loaded ssh pub key from my Mac), ufw, avahi and bash on my image.
3. UFW should only allow inbound to OpenVPN (outbound can be anything). Administration and SSH should only be done locally.
4. OpenVPN setup should be done through Ansible.

> *_NOTE_* this post is being updated as I figure stuff out. Expect TODOs here and there.

# References 
