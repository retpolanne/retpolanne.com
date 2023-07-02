---
layout: post
title:  "Kernel Dev - The Return of Renesas"
date:   2023-07-01 14:52:21 -0300
categories: kernel-dev renesas
tags: kernel-dev renesas
---
After a back and forth with my colleague Rene, and after a lot of troubleshooting, I believe I was able to 
isolate the problem with the XHCI Renesas kernel module. 

So, remember Vinod told me the kernel module shouldn't erase the ROM? Well, I found out why this was failing. 

This is the code that checks whether to erase the ROM and redownload the firmware:

```c
int renesas_xhci_check_request_fw(struct pci_dev *pdev,
                  const struct pci_device_id *id)
{
    struct xhci_driver_data *driver_data =
            (struct xhci_driver_data *)id->driver_data;
    const char *fw_name = driver_data->firmware;
    const struct firmware *fw;
    bool has_rom;
    int err;

    /* Check if device has ROM and loaded, if so skip everything */
    has_rom = renesas_check_rom(pdev);
    if (has_rom) {
        err = renesas_check_rom_state(pdev);
        if (!err)
            return 0;
        else if (err != -ENOENT)
            has_rom = false;
    }
```

I know, step-34 was a weird problem, but I don't really care so much about it. It was quite easy to flash
the ROM using flashrom to my card anyways. We're going to focus on this: 

```c
static int renesas_check_rom_state(struct pci_dev *pdev)
{
    u16 rom_state;
    u32 version;
    int err;

    /* check FW version */
    err = pci_read_config_dword(pdev, RENESAS_FW_VERSION, &version);
    if (err)
        return pcibios_err_to_errno(err);

    version &= RENESAS_FW_VERSION_FIELD;
    version = version >> RENESAS_FW_VERSION_OFFSET;
    dev_dbg(&pdev->dev, "Found ROM version: %x\n", version);

    /*
     * Test if ROM is present and loaded, if so we can skip everything
     */
    err = pci_read_config_word(pdev, RENESAS_ROM_STATUS, &rom_state);
    if (err)
        return pcibios_err_to_errno(err);

    if (rom_state & RENESAS_ROM_STATUS_ROM_EXISTS) {
        /* ROM exists */
        dev_dbg(&pdev->dev, "ROM exists\n");

        /* Check the "Result Code" Bits (6:4) and act accordingly */
        switch (rom_state & RENESAS_ROM_STATUS_RESULT) {
        case RENESAS_ROM_STATUS_SUCCESS:
            return 0;

        case RENESAS_ROM_STATUS_NO_RESULT: /* No result yet */
            dev_dbg(&pdev->dev, "Unknown ROM status ...\n");
            return -ENOENT;

        case RENESAS_ROM_STATUS_ERROR: /* Error State */
        default: /* All other states are marked as "Reserved states" */
            dev_err(&pdev->dev, "Invalid ROM..");
            break;
        }
    }

    return -EIO;
}
```

It reads the `RENESAS_ROM_STATUS` register (F6), then checks whether it is 000b (Invalid, no result yet), 
001b (Success) and 010b (error). It also seems to do it backwards? So 10 would be success and 01 would be failure for big endian readers. **This is a Read Only register that is only updated after FW Download Enable is set to 0b**. It's all documentated on the Renesas Manual, section 3.2.6.8.

My dmesg after I added the `rom_state` var to `dev_dbg`. 

```
[Fri Jun 30 13:19:28 2023] xhci_hcd 0000:06:00.0: External ROM exists
[Fri Jun 30 13:19:28 2023] xhci_hcd 0000:06:00.0: Found ROM version:
2026
[Fri Jun 30 13:19:28 2023] xhci_hcd 0000:06:00.0: ROM exists - rom state
8000, rom_state & RENESAS_ROM_STATUS_ROM_EXISTS 32768
[Fri Jun 30 13:19:28 2023] xhci_hcd 0000:06:00.0: Unknown ROM status ...
rom state 8000, rom_state & RENESAS_ROM_STATUS_ROM_EXISTS 32768
[Fri Jun 30 13:19:28 2023] xhci_hcd 0000:06:00.0: FW is not ready/loaded
yet.
[Fri Jun 30 13:19:28 2023] xhci_hcd 0000:06:00.0: External ROM exists
[Fri Jun 30 13:19:28 2023] xhci_hcd 0000:06:00.0: Performing ROM
Erase...
[Fri Jun 30 13:19:28 2023] xhci_hcd 0000:06:00.0: ROM Erase... Done
success
[Fri Jun 30 13:19:56 2023] xhci_hcd 0000:06:00.0: Download to external
ROM TO: 0
[Fri Jun 30 13:19:56 2023] xhci_hcd 0000:06:00.0: ROM load failed,
falling back on FW load
[Fri Jun 30 13:19:56 2023] xhci_hcd 0000:06:00.0: Timeout for Set DATAX
step: 2
[Fri Jun 30 13:19:56 2023] xhci_hcd 0000:06:00.0: Firmware Download Step
2 failed at position 8 bytes with (-110).
[Fri Jun 30 13:19:56 2023] xhci_hcd 0000:06:00.0: firmware failed to
download (-110).
[Fri Jun 30 13:19:56 2023] xhci_hcd: probe of 0000:06:00.0 failed with
error -110
```

These are the logs after a fresh boot. Take notice of this line: 

```
[Fri Jun 30 13:19:28 2023] xhci_hcd 0000:06:00.0: Unknown ROM status ...
rom state 8000, rom_state & RENESAS_ROM_STATUS_ROM_EXISTS 32768
```

ROM state is 8000... and after I retry loading the module:

```
[Fri Jun 30 13:20:43 2023] xhci_hcd 0000:06:00.0: External ROM exists
[Fri Jun 30 13:20:43 2023] xhci_hcd 0000:06:00.0: Found ROM version:
2026
[Fri Jun 30 13:20:43 2023] xhci_hcd 0000:06:00.0: ROM exists - rom state
8010, rom_state & RENESAS_ROM_STATUS_ROM_EXISTS 32768
[Fri Jun 30 13:20:43 2023] xhci_hcd 0000:06:00.0: xHCI Host Controller
[Fri Jun 30 13:20:43 2023] xhci_hcd 0000:06:00.0: new USB bus
registered, assigned bus number 3
[Fri Jun 30 13:20:43 2023] xhci_hcd 0000:06:00.0: Zeroing 64bit base
registers, expecting fault
[Fri Jun 30 13:20:53 2023] xhci_hcd 0000:06:00.0: can't setup: -110
[Fri Jun 30 13:20:53 2023] xhci_hcd 0000:06:00.0: USB bus 3 deregistered
[Fri Jun 30 13:20:53 2023] xhci_hcd 0000:06:00.0: init 0000:06:00.0
fail, -110
[Fri Jun 30 13:20:53 2023] xhci_hcd: probe of 0000:06:00.0 failed with
error -110
```

ROM state turns into 8010!!!! And skips the erase ROM path.

Things to keep in mind:

1. I tried checking the F4 word after boot and before module load using setpci

```sh
setpci -v -s 06:00.0 f6.w
0000:06:00.0 @f6 = 8000
```

As this is a PCI config, it obviously doesn't persist between boots. 

2. This is set by the Renesas controller when FW Download Enable is zeroed out after a FW download – it's read only and it depends on a firmware download being started. 

So this is the bug: relying on a register that is unset on boot and that is only set when FW download process starts and finishes. Of course it is going to erase the ROM on every boot!

## New card who dis

This week, my new Renesas card will arive from China, and I'm going to do the following: 

1. Before even connecting it to the motherboard, I'll dump the ROM using flashrom. 

```sh
sudo ./flashrom --programmer ch341a_spi -r new-card-factory-dump.bin
```

2. I'll connect the card, boot Linux with xhci-pci blocklisted and check the ROM status from the PCI registers

```sh
setpci -v -s 06:00.0 f6.w
```

3. Load the xhci-pci-renesas module, load my bpftrace program, dmesg, and see if I get the step-34 bug with the new card – will also see if the card gets erased as well.

## A simple workaround

I've also found a quite simple workaround: to fiddle with the FW Download Lock register. This will run before
any kernel modules load (even the ones on your mkinitcpio) and also before cryptsetup. Please change the PCI id for your card (mine is 
06:00.0).

It's pretty simple, and can be set up on boot automatically:

1. Create a file for the service: `/lib/systemd/system/renesas-setpci.service"`

2. Contents:

```sh
[Unit]
Description=Disable Renesas FW Download
Before=systemd-modules-load.service systemd-cryptsetup@.service

[Service]
Type=simple
ExecStart=/usr/bin/setpci -v -s 06:00.00 f4.b=ff

[Install]
WantedBy=systemd-modules-load.service systemd-cryptsetup@.service
```

3. Enable the service

```sh
systemctl enable renesas-setpci
```

Reboot and you'll see the FW download lock engaged and your ROM will be spared :). 

> *_NOTE_* this post is being updated as I figure stuff out.

# References 

\[1] [xhci-pci-renesas.c](https://elixir.bootlin.com/linux/latest/source/drivers/usb/host/xhci-pci-renesas.c)
