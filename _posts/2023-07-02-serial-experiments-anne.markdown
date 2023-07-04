---
layout: post
title:  "Serial Experiments Anne - Part 1"
date:   2023-07-02 10:40:00 -0300
categories: hardware serial
tags: hardware serial uart
---

![IDK who made this but I love it](/assets/img/lain.jpg){:width="50%"}

I love Serial IO and UART ports. I mean, they are so basic: send bits at a specific rate, connect tx and 
rx, read bits at a specific rate and then BAM, you have a TTY, you have logs. 

However, if timing (or voltage) is not precise, things take a turn to the worse. 

I'm currently thinking about a project where I use the COM port of my motherboard to send the serial logs 
to an FPGA, which receives these logs and renders them on a display. I kind of like doing things headless 
while I'm on my Mac and I usually prefer to do things via SSH, but I also want to have the feedback of the 
serial port. 

In order to test things before the FPGA arrives, I wanted to use a 5V USB to TTL to read the logs from my 
12V COM port. Nothing fried lol.

![COM Port Pinout](/assets/img/comport.jpg){:width="50%"}

It worked, but not consistently... and this is so annoying.

![Mambo mambo jambo!](/assets/img/mambojambo.jpg){:width="50%"}

BTW, I needed to add a serial console to the kernel command line. More here [2].

```
console=ttyS0,115200
```

This will allow you to have a serial TTY on /dev/ttyS0 at a baud rate 115200.

## Analyzing stuff with a Logic Analyzer

Checking some signals in the logic analyzer, I saw the inverse measurement is 50khz for some bits. Some others
are showing 25khz. 

![50khz](/assets/img/50khz.png){:width="80%"}

Things were looking wrong... I've increased the capture to 24MS/s and the bits from the 115200 baud rate were 
showing... but still had framing errors. 

So! I decided to invert the signal and AAAAAAASUS! 

![AAAASUS](/assets/img/asus.png){:width="80%"}

It was inverted all along... how do I invert this signal to my USB to TTL? It was probably working sometimes
because of USB-C or something. 

Seems like my CP2102 doesn't support inverting the signal, so I'm buying an FTDI. 

I bought an FTDI... it didn't change anything. I could actually invert the bits on the FTDI, but for some reason I couldn't
reprogram it with `FT_Prog`. 

What actually happens is this: 

![TTL to RS232 voltage](/assets/img/ttl-to-rs232.png){:width="50%"}

The COM port on my motherboard runs on RS232 – where it idles in +12V and every bit is -12V. TTL, on the other hand, idles on 0V and 
every bit is 5V. That's why the signal was inverted!

After spending a long time trying to understand it, and discussing with folks from the Hardware Hacking group, 
I decided to buy a MAX232.

![MAX232 Pinout](/assets/img/max232.png){:width="50%"}

This chip translates RS232 to TTL logic, inverting the signal! 

![RS232 to TTL conversion](/assets/img/max232-circuit.jpg){:width="70%"}

After beating my head a lot, things got quite easy. Datasheet is on [1]. 

Basically, if I want to translate RS232 to TTL, this is the logic: 

```
COM Port Tx (RS232) -> MAX232 R2IN pin -> MA232 R2OUT pin -> FTDI Rx
```

And the TTL Rx to RS232 - which I didn't bother so much:

```
FTDI Tx -> MAX232 T2IN -> MAX232 T2OUT pin -> COM Port Rx (RS232)
```

> The COM Rx pin is the NSIN (pin 2) and COM Tx pin is the NSOUT (pin 3).

I plugged it all and the logic was still wrong... what am I missing?

Okay! So, it idles at 5V... where does it get this voltage? Air? No! VCC! 

So I plugged the FTDI VCC to the MAX232 VCC and VOILÁ! Serial Logs!

![Breadboard](/assets/img/breadboard.jpg){:width="50%"}

## Next steps

As I mentioned, now I have the circuit for translating RS232 to TTL. Next time, I'll need to find out how to program the FPGA to:

1. Be able to receive signal from UART
2. Turn this signal into pixels 
3. Send these pixels to the LCD

But we'll talk about it next time :).

# References 

\[1] [MAX232 Datasheet](https://www.ti.com/lit/ds/symlink/max232.pdf?ts=1688476756394&ref_url=https%253A%252F%252Fwww.ti.com%252Fproduct%252FMAX232)

\[2] [Linux Serial Console](https://www.kernel.org/doc/html/v5.9/admin-guide/serial-console.html)
