---
layout: post
title: "GSoC 2024 first task - perf, bpf, lock contention"
date: 2024-03-05 17:43:32 -0300
categories: kernel-dev 
tags: gsoc-2024 gsoc kernel-dev perf
---

My first task on the preparation for the GSoC's perf project is filtering `__traceiter_foobar` calls that show up here: 

```
sudo ./perf lock con -a -b -- sleep 3                                                                                                        
 contended   total wait     max wait     avg wait         type   caller                                                                         
                                                                                                                                                
         2      2.35 s       2.35 s       1.18 s      spinlock   __traceiter_contention_begin+0x44                                              
         6    274.62 ms     91.59 ms     45.77 ms     rwlock:W   __traceiter_contention_begin+0x44                                              
         4    183.13 ms     91.56 ms     45.78 ms     rwlock:W   __traceiter_contention_begin+0x44                                              
```

So that they show the correct values of the symbols: 

```
sudo ./perf lock con --stack-skip 5 -a -b -- sleep 3                                                                                         
 contended   total wait     max wait     avg wait         type   caller                                                                         
                                                                                                                                                
         2      2.00 s       2.00 s       1.00 s      spinlock   calculate_sigpending+0x1c                                                      
         4      2.00 s       2.00 s     499.73 ms     rwlock:W   do_exit+0x338                                                                  
         3      2.00 s       2.00 s     666.31 ms     rwlock:W   do_exit+0x338                                                                  
         3      2.00 s       2.00 s     666.30 ms     spinlock   get_signal+0x108
```

On `linux/tools/perf/builtin-lock.c` I found the signature for the output of the perf lock contention call: 

```c
case LOCK_AGGR_CALLER:                                                                                                                
         fprintf(lock_output, "%s%s %s", "type", sep, "caller");
```

This means the `aggr_mode` for this program is `LOCK_AGGR_CALLER`. Where else did I see `LOCK_AGGR_CALLER`? On the bpf program for the lock contention itself.

## Resources 

[x] https://nakryiko.com/posts/bpf-tips-printk/

[y] https://www.kernel.org/doc/html/v4.20/core-api/printk-formats.html
