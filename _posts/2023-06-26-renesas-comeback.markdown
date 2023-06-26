---
layout: post
title:  "Kernel Dev - The Renesas Comeback"
date:   2023-06-26 08:41:21 -0300
categories: kernel-dev renesas
tags: kernel-dev renesas
---

The Renesas journey isn't over yet! I'm willing to go lower, thanks to Rene Treffer and their awesome writeup on the upd720201 external ROM. [1]

Basically, I figured out that my card has an exotic, non-standard, flash chip: PUYA P25Q40H. Datasheet available at [2]. 

I got inspired and decided to buy a BIOS programmer just for the lulz, but I guess I kind of isolated where the problem with this card is: the EEPROM must be too slow. 

So my plan for the driver is the following: 

1. Write a benchmark function: it enables the register for External ROM firmware download, then downloads a single byte from the firmware and calculates (maybe using jiffies?) how long it takes for the register to turn to the expected condition.
2. Be deterministic and set an arbitrary timeout based on this benchmark 
3. Add a config (disabled by default) to include dynamic timeout based on the benchmark

> *_NOTE_* this post is being updated as I figure stuff out.

# References 

\[1] [USB 3.0 uPD720201 working](https://github.com/geerlingguy/raspberry-pi-pcie-devices/issues/103)

\[2] [P25Q40H Datasheet (PDF)](https://pdf1.alldatasheet.com/datasheet-pdf/view/1150759/PUYA/P25Q40H.html)
