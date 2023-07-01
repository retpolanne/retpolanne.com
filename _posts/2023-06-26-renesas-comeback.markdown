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

I sent some emils to Rene and he mentioned that maybe that shouldn't be ideal. Then I got proof it wasn't

## Back to bpftrace

So, I was curious to see how firmware download was called, and it seems the code splits it into DWORDs, then each DWORD from the firmware is downloaded to the ROM. This is the code: 

```c
    for (i = 0; i < fw->size / 4; i++) {
        err = renesas_fw_download_image(pdev, fw_data, i, false);
        if (err) {
            dev_err(&pdev->dev,
                "Firmware Download Step %zd failed at position %zd bytes with (%d).",
                i, i * 4, err);
            return err;
        }
    }
```

So, I changed the bpftrace program [3] to print the iterator that was passed to `renesas_fw_download_image`. 

I really thought that there was a problem with the EEPROM, but turns out the first 33 DWORDs are downloaded without retries! But when it comes to the 34th DWORD onwards, things get SLOW! Seconds slow. BTW – here I changed RENESAS_RETRY to `30000` (default is 10000).

```
Renesas download image has been called with iterator i=33
Reading the config register f7 from PCI 1912:0014 - content 84f8b100
Writing the config register fc from PCI 1912:0014 - content e4251764
Writing the config register f7 from PCI 1912:0014 - content 0002
Renesas download image has been called with iterator i=34
Reading the config register f7 from PCI 1912:0014 - content 84f8b100
Reading the config register f7 from PCI 1912:0014 - content 84f8b300
# Thousands of logs later...
Reading the config register f7 from PCI 1912:0014 - content 84f8b300
Writing the config register f8 from PCI 1912:0014 - content 5c591724
Writing the config register f7 from PCI 1912:0014 - content 0001
```

So, F7, which is the `RENESAS_ROM_STATUS_MSB` register, first contains some trash (which is interesting, you'll understand why later). Then, a single byte changes and the module keeps retrying: `84f8b100` turns into `84f8b300`. After thousands of reads, it finally writes the content of the 34th DWORD from the firmware to DATA0 (register F8 – `RENESAS_DATA0`). And finally, F7 turns into `0001b`.

This behaviour is defined here – `status_reg` is `RENESAS_ROM_STATUS_MSB`, which is F7:

```c
    /* step+1. Read "Set DATAX" and confirm it is cleared. */
    for (i = 0; i < RENESAS_RETRY; i++) {
        err = pci_read_config_byte(dev, status_reg, &fw_status);
        if (err) {
            dev_err(&dev->dev, "Read Status failed: %d\n",
                pcibios_err_to_errno(err));
            return pcibios_err_to_errno(err);
        }
        if (!(fw_status & BIT(data0_or_data1)))
            break;

        udelay(RENESAS_DELAY);
    }
    if (i == RENESAS_RETRY) {
        dev_err(&dev->dev, "Timeout for Set DATAX step: %zd\n", step);
        return -ETIMEDOUT;
    }
```

Now that I'm writing about it, I don't really understand why it gets stuck on this retry loop. 

Judging by the code logic:

```
Reading the config register f7 from PCI 1912:0014 - content 84f8b100
# This is happening after the loop??? I'm missing something...
Writing the config register fc from PCI 1912:0014 - content e4251764
# This last line is writing to the F7 register, whaaaat
Writing the config register f7 from PCI 1912:0014 - content 0002
```

```c
    /* step+3. Set "Set DATAX". */
    err = pci_write_config_byte(dev, status_reg, BIT(data0_or_data1));
    if (err) {
        dev_err(&dev->dev, "Write config for DATAX failed: %d\n",
            pcibios_err_to_errno(err));
        return pcibios_err_to_errno(err);
    }
```

So, maybe I don't really understand this code (or it doesn't really match the "uPD720201/uPD720202 User's Manual: Hardware"_, section 7.1).

I also added a `#define DEBUG 1` on the kernel module so I can see all the `dev_dbg` messages.

```
# renesas_xhci_check_request_fw -> renesas_check_rom
[  291.497544] xhci_hcd 0000:06:00.0: External ROM exists

# renesas_xhci_check_request_fw -> renesas_check_rom_state
[  291.497551] xhci_hcd 0000:06:00.0: Found ROM version: 2026
[  291.497558] xhci_hcd 0000:06:00.0: ROM exists
[  291.497560] xhci_hcd 0000:06:00.0: Unknown ROM status ...

# renesas_xhci_check_request_fw -> renesas_fw_check_running
[  291.497569] xhci_hcd 0000:06:00.0: FW is not ready/loaded yet.
# From this point, I believe that the module could not detect that
# there's a valid firmware running on the card

# renesas_xhci_check_request_fw -> renesas_load_fw -> renesas_check_rom
[  291.497985] xhci_hcd 0000:06:00.0: External ROM exists

# renesas_xhci_check_request_fw -> renesas_load_fw -> renesas_rom_erase
[  291.497996] xhci_hcd 0000:06:00.0: Performing ROM Erase...
[  291.523737] xhci_hcd 0000:06:00.0: ROM Erase... Done success

# renesas_xhci_check_request_fw -> renesas_load_fw -> renesas_setup_rom
[  319.410895] xhci_hcd 0000:06:00.0: Download to external ROM TO: 0
[  319.410904] xhci_hcd 0000:06:00.0: ROM load failed, falling back on FW load

# renesas_xhci_check_request_fw -> renesas_load_fw -> renesas_fw_download -> renesas_fw_download_image
[  319.552909] xhci_hcd 0000:06:00.0: Timeout for Set DATAX step: 2
[  319.552914] xhci_hcd 0000:06:00.0: Firmware Download Step 2 failed at position 8 bytes with (-110).
[  319.552918] xhci_hcd 0000:06:00.0: firmware failed to download (-110).
[  319.552927] xhci_hcd: probe of 0000:06:00.0 failed with error -110
```

I have to dig deeper into this code again. But, we found an interesting solution. There's this thing in the code:

```c
static int renesas_load_fw(struct pci_dev *pdev, const struct firmware *fw)
{
    int err = 0;
    bool rom;

    /* Check if the device has external ROM */
    rom = renesas_check_rom(pdev);
    if (rom) {
        /* perform chip erase first */
        renesas_rom_erase(pdev);

        /* lets try loading fw on ROM first */
        rom = renesas_setup_rom(pdev, fw);
        if (!rom) {
            dev_dbg(&pdev->dev,
                "ROM load failed, falling back on FW load\n");
        } else {
            dev_dbg(&pdev->dev,
                "ROM load success\n");
            goto exit;
        }
    }

    err = renesas_fw_download(pdev, fw);

exit:
    if (err)
        dev_err(&pdev->dev, "firmware failed to download (%d).", err);
    return err;
}
```

So, talking to Rene, he thought it would be better to remove the `renesas_rom_erase` and the `renesas_setup_rom` step. Thing is: if your card is stable, the first module load after boot would screw it up. 

1. I increased the timeout to allow fw download to go through
2. I removed this branch of code where the ROM gets erased 
3. Rebooted the machine and loaded the module: module load is blazingly fast and USB-C is working

That led us to craft a patch where we remove this part of the code. It was NAKed, but I explained the situation and asked for better approaches. Rene understands a lot more about how the firmware is downloaded and how it works to the BIOS level, and he helped me argue with the maintainers about this. 

I'm currently waiting for responses on the patch, but I believe I'll study the code a little more to understand if I'm missing something obvious. My questions are: 

1. Why is the ROM erase being called on my board? According to Vinod, one of the maintainers, it shouldn't happen like this. 
2. I still didn't fully understand the fw_download function. Need to check if it matches with the manual. 
3. Why does step 34 (the 34th DWORD) takes so long to load? Why so specific? 

I'll discuss the first question on the next post! 

# References 

\[1] [USB 3.0 uPD720201 working](https://github.com/geerlingguy/raspberry-pi-pcie-devices/issues/103)

\[2] [P25Q40H Datasheet (PDF)](https://pdf1.alldatasheet.com/datasheet-pdf/view/1150759/PUYA/P25Q40H.html)

\[3] [renesas-pci-trace.bt](https://github.com/retpolanne/kernel-workspace/blob/main/bpf/renesas-pci-trace.bt)

\[4] [xhci-pci-renesas.c](https://elixir.bootlin.com/linux/latest/source/drivers/usb/host/xhci-pci-renesas.c)

\[5] [[PATCH] usb: host: xhci: remove renesas rom wiping](https://lore.kernel.org/linux-usb/20230626204910.728-3-retpolanne@posteo.net/T/#u)
