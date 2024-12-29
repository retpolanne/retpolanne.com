---
layout: post
title: "Windows Convoluted Madness – how to use Wine in debian and X11 and mac and..."
date: 2024-12-29 20:14:55 -0300
categories: windows
tags: debian x11 windows
---

I'm currently trying to run Windows applications on Debian and it's so hard already.
Why is Windows so convoluted? 

Anyways, what I'm doing: 

1. Install XQuartz on your Mac _and reboot_!!! 

2. I'm using Lima to provision my VMs, make sure to add this block to the instance
yaml:

```yaml
ssh:
  forwardX11: true
  forwardX11Trusted: true
```

3. Then comes the debian x11 stuff: 

```sh
sudo apt install xauth
# Trust your current display
xauth generate $DISPLAY . trusted 

# Test - exit session then try again if you see an error
sudo apt install x11-apps
xeyes
```

4. And wine stuff: 

```sh
# https://gitlab.winehq.org/wine/wine/-/wikis/Debian-Ubuntu
sudo apt install gpg
sudo mkdir -pm755 /etc/apt/keyrings
wget -O - https://dl.winehq.org/wine-builds/winehq.key | sudo gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key -
# Bullseye debian src
sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bullseye/winehq-bullseye.sources

# rather annoying, but needed
sudo dpkg --add-architecture i386

sudo apt update

sudo apt install --install-recommends winehq-stable
```

4. If you're on your shiny Apple Silicon, do this: 

```sh
# Install docker as per https://docs.docker.com/engine/install/debian/

# then: 
# https://github.com/tonistiigi/binfmt
sudo docker run --privileged --rm tonistiigi/binfmt --install x86_64,i386
```

This last step uses [binfmt_misc](https://docs.kernel.org/admin-guide/binfmt-misc.html) that allows us
to bind an executable with a file type, in a way that we can tell it to emulate whatever we need with qemu/wine behind. 

Quite interesting, that's pretty much how Docker for desktop amd64 emulation works as well on Apple Silicon.

See ya next time.
