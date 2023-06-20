---
layout: post
title: "WIP - BPF and OSS-Fuzz - Understanding a bug"
date: 2022-09-17 12:20:14 -0300
categories: bpf kernel oss-fuzz
---

# WIP - BPF and OSS-Fuzz - Understanding a bug

I came across this bug [1] on libbpf and I decided to tackle this. It's a bug that was reported by OSS-Fuzz, a project created by Google to lend their computing power to do Fuzzing on open source software. 

Reproducing the bug is straightforward, but I have to break it up to understand it better. 

Basically, you have to clone the libbpf repo (keep in mind that this is a mirror from tools/lib/bpf from the kernel). Then, build, download the test case program, and run the fuzzer

{% highlight bash %}
./scripts/build-fuzzers.sh
wget -O oss-fuzz-42345 https://oss-fuzz.com/download?testcase_id=5041748798210048
./out/bpf-object-fuzzer oss-fuzz-42345
{% endhighlight %}

You can see the stacktrace on the bug description. [1]

Anyways, it does tell me that there's a bug on bpf_object__init_user_btf_map, but that doesn't really tell me which data was loaded, what is the state of the registers when we get a SEGV, etc. I saw a similar bug on [2] that had a test code, so I kindly asked the issue creator to help me with that.

They responded with some code and now I understand how to reproduce it.

## C code for reproducing the bug

Getting the code consists in:

- dumping the test case bytes (I'll explain later) 
- including the correct header files
- opening the test case (which is a bpf program)

To dump the test case bytes:

{% highlight bash %}
xxd -i oss-fuzz-42345
{% endhighlight %}

This will print some C code that contains the raw bytes. 

Now, the rest of the code:

{% highlight c %}
#include "bpf/btf.h"
#include "bpf/libbpf.h"

// Code for the test case dump redacted for readability

static int libbpf_print_fn(enum libbpf_print_level level, const char *format, va_list args)
{
        return 0;
}

int main(int argc, char *argv[]) {
        struct bpf_object *obj = NULL;
        DECLARE_LIBBPF_OPTS(bpf_object_open_opts, opts);
        int err;

        libbpf_set_print(libbpf_print_fn);

        opts.object_name = "fuzz-object";
        obj = bpf_object__open_mem(oss_fuzz_42345, sizeof(oss_fuzz_42345), &opts);
        err = libbpf_get_error(obj);
        if (err)
                return 0;

        bpf_object__close(obj);
        return 0;
}
{% endhighlight %}

I then compiled the code:

{% highlight bash %}
gcc -fsanitize=address -g -O1 -fno-omit-frame-pointer oss-fuzz-42345.c -o oss-fuzz-42345.o -I../libbpf/src -I../libbpf/include/uapi ../libbpf/src/libbpf.a -lelf -lz
{% endhighlight %}

When I run it:

{% highlight text %}
./oss-fuzz-42345.o
AddressSanitizer:DEADLYSIGNAL
=================================================================
==49276==ERROR: AddressSanitizer: SEGV on unknown address 0x000000000000 (pc 0x55f9ffa87295 bp 0x7ffca3fee1b0 sp 0x7ffca3fecf00 T0)
==49276==The signal is caused by a READ memory access.
==49276==Hint: address points to the zero page.
    #0 0x55f9ffa87295 in bpf_object__init_user_btf_map :2450
    #1 0x55f9ffa87295 in bpf_object__init_user_btf_maps :2574
    #2 0x55f9ffa87295 in bpf_object__init_maps :2595
    #3 0x55f9ffa4d900 in bpf_object_open :7207
    #4 0x55f9ffa4df0d in bpf_object__open_mem :7244
    #5 0x55f9ffa46a61 in main /home/kernel-dev/oss-fuzz-42345/oss-fuzz-42345.c:240
    #6 0x7f06de11ed09 in __libc_start_main ../csu/libc-start.c:308
    #7 0x55f9ffa468a9 in _start (/home/kernel-dev/oss-fuzz-42345/oss-fuzz-42345.o+0x4f8a9)

AddressSanitizer can not provide additional info.
SUMMARY: AddressSanitizer: SEGV :2450 in bpf_object__init_user_btf_map
==49276==ABORTING
{% endhighlight %}

## Debugging the code

Debugging is easy with gdb. To see the whole code, I had to pass the directory of my libbpf.

{% highlight text %}
gdb ./oss-fuzz-42345.o

(gdb) dir /home/kernel-dev/libbpf/src
Source directories searched: /home/kernel-dev/libbpf/src:$cdir:$cwd
(gdb) run
Starting program: /home/kernel-dev/oss-fuzz-42345/oss-fuzz-42345.o 
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/lib/x86_64-linux-gnu/libthread_db.so.1".

Program received signal SIGSEGV, Segmentation fault.
0x00005555555e4295 in bpf_object__init_user_btf_map (obj=0x614000000040, var_idx=0, sec_idx=1, pin_root_path=0x0, sec=<optimized out>, data=<optimized out>, strict=<optimized out>)
    at libbpf.c:2450
2450		map_name = btf__name_by_offset(obj->btf, var->name_off);
(gdb) l
2445		int err;
2446	
2447		vi = btf_var_secinfos(sec) + var_idx;
2448		var = btf__type_by_id(obj->btf, vi->type);
2449		var_extra = btf_var(var);
2450		map_name = btf__name_by_offset(obj->btf, var->name_off);
2451	
2452		if (map_name == NULL || map_name[0] == '\0') {
2453			pr_warn("map #%d: empty name.\n", var_idx);
2454			return -EINVAL;
(gdb) break 2450
Breakpoint 1 at 0x5555555e426e: file libbpf.c, line 2450.
(gdb) p var
$1 = (const struct btf_type *) 0x0
(gdb) p var->name_off
Cannot access memory at address 0x0
{% endhighlight %}

This must be the culprit: var->name_off. var's address is 0x0 and indirectly reaching var->name_off will cause a segfault. A null pointer dereference.

By changing the var, we get different values on the SEGV. 

{% highlight text %}
(gdb) p var
$2 = (const struct btf_type *) 0xff
(gdb) p var->name_off
Cannot access memory at address 0xff
(gdb) c
Continuing.

Program received signal SIGSEGV, Segmentation fault.
0x00005555555e4295 in bpf_object__init_user_btf_map (obj=0x614000000040, var_idx=0, sec_idx=1, pin_root_path=0x0, sec=<optimized out>, data=<optimized out>, strict=<optimized out>)
    at libbpf.c:2450
2450		map_name = btf__name_by_offset(obj->btf, var->name_off);
(gdb) c
Continuing.
AddressSanitizer:DEADLYSIGNAL
=================================================================
==49367==ERROR: AddressSanitizer: SEGV on unknown address 0x0000000000ff (pc 0x5555555e4295 bp 0x7fffffffdf50 sp 0x7fffffffcca0 T0)
{% endhighlight %}

But where does this var->name_off come from?

We'll try to figure out on the next session.

## Disassembling the test case

We have two programs: a userspace program (the C code we created up above) and the bpf program (that bunch of bytecode). In order to understand the bpf program, we need to disassemble it somehow. I tried analysing it with all the tools I had available, to no avail. 

{% highlight bash %}
qemu ➜  oss-fuzz-42345 file oss-fuzz-42345
oss-fuzz-42345: ELF 64-bit LSB relocatable, eBPF,, corrupted section header size
qemu ➜  oss-fuzz-42345 binwalk oss-fuzz-42345

DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------

qemu ➜  oss-fuzz-42345 llvm-objdump -d oss-fuzz-42345
llvm-objdump: error: 'oss-fuzz-42345': invalid e_shentsize in ELF header: 8224

qemu ➜  oss-fuzz-42345 rabin2 -S oss-fuzz-42345
[Sections]

nth paddr                             size vaddr                            vsize perm name
―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
0   0x2020202020202020  0xff20202020202020 0x2020202028202020  0xff20202020202020 ---- invalid0
1   0x2020202020202020                 0x0 0x2020202028202020                 0x0 ---- .maps
2   0x00000020                        0x20 0x08000020                        0x20 ---- _134217760
3   0x00000020                        0x20 0x08000020                        0x20 ----        ?   ?                                ?                                                                               .BTF
4   0x00000020                        0x20 0x08000020                        0x20 ----        ?   ?                                ?                                                                               .BTF
5   0x00000020                        0x20 0x08000020                        0x20 ----        ?   ?                                ?                                                                               .BTF
6   0x000000d4                       0x2ff 0x080000d4                       0x2ff ---- .BTF
7   0x00000320                        0x20 0x08000320                        0x20 ---- _134218528_4
8   0x00000020                        0x20 0x08000020                        0x20 ----        ?   ?                                ?                                                                               .BTF
9   0x00000320                        0xc0 0x08000320                        0xc0 ----        ?   ?                                ?                                                                               .BTF
10  0x00000420                        0x20 0x08000420                        0x20 ---- _134218784_7
11  0x2020202020202020                 0x0 0x2020202028202020                 0x0 ---- _2314885530952671264_8
12  0x2020202020202020                 0x0 0x2020202028202020                 0x0 ----        ?   ?                                ?                                                                               .BTF
13  0x2020202020202020                 0x0 0x2020202028202020                 0x0 -rwx        ?   ?                                ?                                                                               .BTF
14  0x00000020                       0x420 0x08000020                       0x420 ----        ?   ?                                ?                                                                               .BTF
15  0x0000058b                        0xff 0x0800058b                        0xff ---- _134219147_12

qemu ➜  oss-fuzz-42345 llvm-objdump -d oss-fuzz-42345
llvm-objdump: error: 'oss-fuzz-42345': invalid e_shentsize in ELF header: 8224

qemu ➜  oss-fuzz-42345 bpftool prog load -L -d oss-fuzz-42345
libbpf: loading oss-fuzz-42345
libbpf: elf: section(1) .maps, size 0, link -14671840, flags 2020202020202020, type=538976288
libbpf: elf: section(2)        ?   ?                                ?                                                                               .BTF, size 32, link 538976288, flags 2020202020202020, type=538976288
libbpf: elf: skipping section(2)        ?   ?                                ?                                                                               .BTF (size 32)
libbpf: elf: section(3)        ?   ?                                ?                                                                               .BTF, size 32, link 538976288, flags 2020202020202020, type=-14671840
libbpf: elf: skipping section(3)        ?   ?                                ?                                                                               .BTF (size 32)
libbpf: elf: section(4)        ?   ?                                ?                                                                               .BTF, size 32, link 538976288, flags 2020202020202020, type=538976288
libbpf: elf: skipping section(4)        ?   ?                                ?                                                                               .BTF (size 32)
libbpf: elf: section(5)        ?   ?                                ?                                                                               .BTF, size 32, link 538976288, flags 2020202020202020, type=538976288
libbpf: elf: skipping section(5)        ?   ?                                ?                                                                               .BTF (size 32)
libbpf: elf: section(6) .BTF, size 767, link 538976288, flags 2020202020202020, type=1
libbpf: elf: section(7)        ?   ?                                ?                                                                               .BTF, size 32, link 538976288, flags 2020202020202020, type=538976288
libbpf: elf: skipping section(7)        ?   ?                                ?                                                                               .BTF (size 32)
libbpf: elf: section(8)        ?   ?                                ?                                                                               .BTF, size 32, link 538976288, flags 2020202020202020, type=538976288
libbpf: elf: skipping section(8)        ?   ?                                ?                                                                               .BTF (size 32)
libbpf: elf: section(9)        ?   ?                                ?                                                                               .BTF, size 192, link 15, flags 2020202020202020, type=2
libbpf: elf: section(10)        ?   ?                                ?                                                                               .BTF, size 32, link 538976288, flags 2020202020202020, type=538976288
libbpf: elf: skipping section(10)        ?   ?                                ?                                                                               .BTF (size 32)
libbpf: elf: section(11)        ?   ?                                ?                                                                               .BTF, size 0, link 538976288, flags 2020202020202020, type=538976288
libbpf: elf: skipping section(11)        ?   ?                                ?                                                                               .BTF (size 0)
libbpf: elf: section(12)        ?   ?                                ?                                                                               .BTF, size 0, link 538976288, flags 2020202020ffff20, type=538976511
libbpf: elf: skipping section(12)        ?   ?                                ?                                                                               .BTF (size 0)
libbpf: elf: section(13)        ?   ?                                ?                                                                               .BTF, size 0, link 538976288, flags 202020ffffffffff, type=-57312
libbpf: elf: skipping section(13)        ?   ?                                ?                                                                               .BTF (size 0)
libbpf: elf: section(14)        ?   ?                                ?                                                                               .BTF, size 1056, link 538976288, flags 2020202020202020, type=538976288
libbpf: elf: skipping section(14)        ?   ?                                ?                                                                               .BTF (size 1056)
libbpf: looking for externs among 8 symbols...
libbpf: collected 0 externs total
[1]    49558 segmentation fault  bpftool prog load -L -d oss-fuzz-42345

qemu ➜  oss-fuzz-42345 readelf -a oss-fuzz-42345  
ELF Header:
  Magic:   7f 45 4c 46 02 01 01 20 20 20 20 20 20 20 20 20 
  Class:                             ELF64
  Data:                              2's complement, little endian
  Version:                           1 (current)
  OS/ABI:                            <unknown: 20>
  ABI Version:                       32
  Type:                              REL (Relocatable file)
  Machine:                           Linux BPF
  Version:                           0x20202020
  Entry point address:               0x2020202020202020
  Start of program headers:          2314885530818453536 (bytes into file)
  Start of section headers:          1600 (bytes into file)
  Flags:                             0x20202020
  Size of this header:               8224 (bytes)
  Size of program headers:           8224 (bytes)
  Number of program headers:         8224
  Size of section headers:           8224 (bytes)
  Number of section headers:         16
  Section header string table index: 15
readelf: Warning: The e_shentsize field in the ELF header is larger than the size of an ELF section header
readelf: Error: Reading 131584 bytes extends past end of file for section headers
readelf: Error: Section headers are not available!
readelf: Error: Too many program headers - 0x2020 - the file is not that big

There is no dynamic section in this file.
readelf: Error: Too many program headers - 0x2020 - the file is not that big
{% endhighlight %}

Fixing the header!

{% highlight bash%}
qemu ➜  oss-fuzz-42345 r2 -w -nn oss-fuzz-42345 
 -- Can you stand on your head?
[0x00000000]> .pf.elf_header.shentsize=0x000000040
[0x00000000]> q
qemu ➜  oss-fuzz-42345 file oss-fuzz-42345
oss-fuzz-42345: ELF 64-bit LSB relocatable, eBPF,, not stripped
{% endhighlight %}


## How detrimental it is

Now that we know everything about this flaw, you may be wondering "why is this important?". We'll investigate this here. 

## References
\[1][libbpf #484](https://github.com/libbpf/libbpf/issues/484)
\[2][libbpf #390](https://github.com/libbpf/libbpf/issues/390)
\[][]()
