---
layout: post
title:  "SerialIO Experiments Anne"
date:   2023-07-02 10:40:00 -0300
categories: hardware serial
tags: hardware serial uart
---

I love Serial IO and UART ports. I mean, they are so basic: send bits at a specific rate, connect tx and 
rx, read bits at a specific rate and then BAM, you have a TTY, you have logs. 

However, if timing (or voltage) is not precise, things take a turn to the worse. 

I'm currently thinking about a project where I use the COM port of my motherboard to send the serial logs 
to an FPGA, which receives these logs and renders them on a display. I kind of like doing things headless 
while I'm on my Mac and I usually prefer to do things via SSH, but I also want to have the feedback of the 
serial port. 

In order to test things before the FPGA arrives, I wanted to use a 5V USB to TTL to read the logs from my 
12V COM port. Nothing fried lol.

It worked, but not consistently... and this is so annoying.

## Analyzing stuff with a Logic Analyzer

Checking some signals in the logic analyzer, I saw the inverse measurement is 50khz for some bits. Some others
are showing 25khz. 

Things were looking wrong... I've increased the capture to 24MS/s and the bits from the 115200 baud rate were 
showing... but still had framing errors. 

So! I decided to invert the signal and AAAAAAASUS! 

It was inverted all along... how do I invert this signal to my USB to TTL? It was probably working sometimes
because of USB-C or something. 

Seems like my CP2102 doesn't support inverting the signal, so I'm buying an FTDI.

# TODO PICS

- Weird Logs
- Good logs
- COM pinout
- ASUS

> *_NOTE_* this post is being updated as I figure stuff out. Expect TODOs here and there.

# References 
