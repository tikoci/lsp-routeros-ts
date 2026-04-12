# Source: https://forum.mikrotik.com/t/v6-11-released/75450/140
# Post author: @rextended
# Extracted from: code-block

[admin@Test Gateway] /file> Oops: Exception in kernel mode, sig: 5 [#1]
SMP NR_CPUS=2 RB1120
NIP: 8021a730 LR: 8021a46c CTR: 00000000
REGS: dffefd30 TRAP: 0700   Not tainted  (3.3.5-smp)
MSR: 00029000 <CE,EE,ME>  CR: 42000028  XER: 20000000
TASK = 8036d3c0[0] 'swapper/0' THREAD: 80380000 CPU: 0
GPR00: 8021a46c dffefde0 8036d3c0 fffffff2 de6f58aa 00000001 de6f4e50 dc870cd2
GPR08: 120ff29a 0000001d 00000000 8021a400 42000022 00000001 dd9fc300 00000012
GPR16: 00000003 00000000 e1811a40 000005e2 de6dd414 e1811a2c e18119c8 e18119ec
GPR24: 00000012 e1811828 de6dd484 0000003b 000000fd dd9fc300 dd9fc300 de6dd3c0
NIP [8021a730] __pskb_pull_tail+0x330/0x340
LR [8021a46c] __pskb_pull_tail+0x6c/0x340
Call Trace:
[dffefde0] [8021a46c] __pskb_pull_tail+0x6c/0x340 (unreliable)
[dffefe00] [e180df30] ppp_register_channel+0xb20/0x1b4c [ppp_generic@0xe180c000]
[dffefe30] [e180f8d4] ppp_output_wakeup+0x978/0xa20 [ppp_generic@0xe180c000]
[dffefe90] [e180fb30] ppp_input+0xf0/0x12a4 [ppp_generic@0xe180c000]
[dffefeb0] [e18494d0] 0xe18494d0 [pppoe@0xe1849000]
[dffefed0] [80221f9c] __netif_receive_skb+0x220/0x400
[dffeff30] [802224a0] process_backlog+0xac/0x178
[dffeff60] [80223870] net_rx_action+0xc0/0x170
[dffeffa0] [80031a14] __do_softirq+0xf4/0x178
[dffefff0] [8000c054] call_do_softirq+0x14/0x24
[80381e80] [80003f5c] do_softirq+0x98/0xc4
[80381ea0] [80031d84] irq_exit+0xa0/0xd4
[80381eb0] [80003c44] do_IRQ+0x94/0x190
[80381ee0] [8000d71c] ret_from_except+0x0/0x18
--- Exception: 501 at cpu_idle+0x8c/0xe0
    LR = cpu_idle+0x8c/0xe0
[80381fc0] [8034076c] start_kernel+0x2d4/0x2e8
[80381ff0] [800003f8] skpinv+0x2e4/0x320
Instruction dump:
7fdcf378 3b400000 4bffffa0 7fc3f378 7c84f850 4bfffced 2f830000 409eff9c
7f43d378 4bffe9c9 38600000 4bffff00 <0fe00000> 38c00001 7cc903a6 4bfffd90
---[ end trace 72421d3cf3d534d4 ]---

Kernel panic - not syncing: Fatal exception in interrupt

panicSaver: dumping panic to flash
flash: erase 10
flash: prg 10
flash: prg err 0
Rebooting in 1 seconds..
------------[ cut here ]------------
Kernel BUG at 800a3a70 [verbose debug info unavailable]
Oops: Exception in kernel mode, sig: 5 [#2]
SMP NR_CPUS=2 RB1120
NIP: 800a3a70 LR: 800113ec CTR: 00000000
REGS: dffefa60 TRAP: 0700   Tainted: G      D       (3.3.5-smp)
MSR: 00021000 <CE,ME>  CR: 22000024  XER: 20000000
TASK = 8036d3c0[0] 'swapper/0' THREAD: 80380000 CPU: 0
GPR00: 800113ec dffefb10 8036d3c0 00001000 00000001 00000001 e1000000 edffc000
GPR08: 000000d0 80017554 00000300 fffffffd 22000024 00000001 dd9fc300 00000012
GPR16: 00000003 00000000 e1811a40 000005e2 de6dd414 e1811a2c e18119c8 e18119ec
GPR24: 80017554 80380000 e1000000 edffc000 000000d0 00000001 00000001 80017554
NIP [800a3a70] __get_vm_area_node.isra.31+0x34/0x180
LR [800113ec] __ioremap_caller+0x170/0x1a4
Call Trace:
[dffefb10] [e137c43c] flash_fixed_cmd+0x140/0x204 [flash@0xe137b000] (unreliable
)
[dffefb40] [800113ec] __ioremap_caller+0x170/0x1a4
[dffefb70] [80017554] rb1120_restart+0x68/0xa4
[dffefb90] [8000b35c] machine_restart+0x48/0x60
[dffefbb0] [802ad3b0] panic+0x198/0x1e8
[dffefc00] [800096b4] die+0x244/0x284
[dffefc30] [8000984c] _exception+0x100/0x114
[dffefd20] [8000d6d0] ret_from_except_full+0x0/0x4c
--- Exception: 700 at __pskb_pull_tail+0x330/0x340
    LR = __pskb_pull_tail+0x6c/0x340
[dffefe00] [e180df30] ppp_register_channel+0xb20/0x1b4c [ppp_generic@0xe180c000]
[dffefe30] [e180f8d4] ppp_output_wakeup+0x978/0xa20 [ppp_generic@0xe180c000]
[dffefe90] [e180fb30] ppp_input+0xf0/0x12a4 [ppp_generic@0xe180c000]
[dffefeb0] [e18494d0] 0xe18494d0 [pppoe@0xe1849000]
[dffefed0] [80221f9c] __netif_receive_skb+0x220/0x400
[dffeff30] [802224a0] process_backlog+0xac/0x178
[dffeff60] [80223870] net_rx_action+0xc0/0x170
[dffeffa0] [80031a14] __do_softirq+0xf4/0x178
[dffefff0] [8000c054] call_do_softirq+0x14/0x24
[80381e80] [80003f5c] do_softirq+0x98/0xc4
[80381ea0] [80031d84] irq_exit+0xa0/0xd4
[80381eb0] [80003c44] do_IRQ+0x94/0x190
[80381ee0] [8000d71c] ret_from_except+0x0/0x18
--- Exception: 501 at cpu_idle+0x8c/0xe0
    LR = cpu_idle+0x8c/0xe0
[80381fc0] [8034076c] start_kernel+0x2d4/0x2e8
[80381ff0] [800003f8] skpinv+0x2e4/0x320
Instruction dump:
9421ffd0 bf010010 542a0024 90010034 7c9d2378 7cbe2b78 7cda3378 814a000c
7cfb3b78 7d1c4378 7d384b78 554a016e <0f0a0000> 70a90001 41820018 7c690034
---[ end trace 72421d3cf3d534d5 ]---
