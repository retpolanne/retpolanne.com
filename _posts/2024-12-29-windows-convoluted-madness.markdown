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
vmType: "vz"
rosetta:
  # Enable Rosetta for Linux.
  # Hint: try `softwareupdate --install-rosetta` if Lima gets stuck at `Installing rosetta...`
  enabled: true
  # Register rosetta to /proc/sys/fs/binfmt_misc
  binfmt: true
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
# Bookworm debian src
sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources

# rather annoying, but needed
sudo dpkg --add-architecture i386
sudo dpkg --add-architecture amd64

sudo apt update

# Staging gives us amd64
sudo apt install --install-recommends winehq-staging
```

4. If you're on your shiny Apple Silicon, do this: 

```sh
# Install docker as per https://docs.docker.com/engine/install/debian/

# then: 
# https://github.com/tonistiigi/binfmt
sudo docker run --privileged --rm tonistiigi/binfmt --install x86_64,i386
# Uninstall other emulators so we can just use rosetta
sudo docker run --privileged --rm tonistiigi/binfmt --uninstall qemu-x86_64
sudo docker run --privileged --rm tonistiigi/binfmt --uninstall qemu-i386
```

This last step uses [binfmt_misc](https://docs.kernel.org/admin-guide/binfmt-misc.html) that allows us
to bind an executable with a file type, in a way that we can tell it to emulate whatever we need with qemu/wine behind. 

Quite interesting, that's pretty much how Docker for desktop amd64 emulation works as well on Apple Silicon.

I found out that I can install wine amd64 actually:

```sh
sudo apt install --install-recommends winehq-staging:amd64
```

If you want to use rosetta for i386:

```sh
# A handy list of magics here 
# https://gitlab.com/pantacor/pv-platforms/wifi-connect/-/blob/master/files/opt/binfmt-misc/qemu-binfmt-conf.sh
sudo /usr/sbin/update-binfmts --install rosetta-i386 /mnt/lima-rosetta/rosetta \
 --magic "\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x03\x00" \
 --mask "\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff" \
 --credentials yes --preserve no
```

Too bad... rosetta hates i386 :( 

See ya next time.
