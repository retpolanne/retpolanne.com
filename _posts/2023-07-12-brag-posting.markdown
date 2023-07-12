---
layout: post
title:  "Anne Bragposting"
date:   2023-07-12 17:06:00 -0300
categories: brag-document 
tags: brag-document
---

Having a brag document [1] is important, and since I want to keep my open source contributions handy, I'm writing this post. 

## Merged patches 

- pypa/pip [Fix is_url from splitting the scheme incorrectly when using PEP 440's direct references #6203](https://github.com/pypa/pip/pull/6203)
- kubernetes/ingress-gce [Added NoSchedule effect to GetNodeConditionPredicate #792](https://github.com/kubernetes/ingress-gce/pull/792)
- kubernetes/kubernetes [Moving e2e boilerplate to separate functions #79909](https://github.com/kubernetes/kubernetes/pull/79909)
- ansible-community/molecule [Adds vpc_id to ec2_group, from subnet facts, and allows to specify SG ip cidr #2405](https://github.com/ansible-community/molecule/pull/2405)
- ansible-community/molecule [Added instance_profile_name to ec2 driver #2370](https://github.com/ansible-community/molecule/pull/2370)
- linux-sunxi/meta-sunxi [add u-boot ethernet support to orange pi one plus (h6) #389](https://github.com/linux-sunxi/meta-sunxi/pull/389)

## Patches awaiting approval/merge

- flashrom [flashchips: Add support for PUYA P25Q40H](https://review.coreboot.org/c/flashrom/+/76251)
- u-boot [[PATCH] sunxi: H6: Enable Ethernet on Orange Pi One Plus](https://lore.kernel.org/u-boot/20230711003957.658805-2-retpolanne@posteo.net/T/#u)

## Rejected patches 

- linux kernel [[PATCH] libbpf: add validation to BTF's variable type ID](https://lore.kernel.org/bpf/20220929160558.5034-1-annemacedo@linux.microsoft.com/)
- linux kernel [[PATCH] usb: host: xhci: parameterize Renesas delay/retry](https://lore.kernel.org/lkml/2023061951-taekwondo-unsoiled-faf2@gregkh/T/)
- linux kernel [[PATCH] usb: host: xhci: remove renesas rom wiping](https://lore.kernel.org/lkml/20230626204910.728-3-retpolanne@posteo.net/T/)

## References

\[1] [Get your work recognized: write a brag document](https://jvns.ca/blog/brag-documents/)
