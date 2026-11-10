/*
 * stage1/entry.S
 * Bare-metal entry point for MediaTek MT6771 (Helio P70M) in ARMv7-A 32-bit mode
 * Loads at 0x40008000 (standard Linux zImage entry address in Little Kernel)
 */

.arm
.syntax unified
.arch_extension sec
.section .text.entry, "ax"
.globl _start
.globl _image_start
.globl _image_end

_image_start:
_start:
    /* Standard ARM zImage header format expected by MediaTek Little Kernel */
    mov     r0, r0                      /* NOP 1 (0xe1a00000) */
    mov     r0, r0                      /* NOP 2 */
    mov     r0, r0                      /* NOP 3 */
    mov     r0, r0                      /* NOP 4 */
    mov     r0, r0                      /* NOP 5 */
    mov     r0, r0                      /* NOP 6 */
    mov     r0, r0                      /* NOP 7 */
    mov     r0, r0                      /* NOP 8 */

    b       reset_entry                 /* Branch past zImage header */

    .word   0x016f2818                  /* Magic number: zImage (0x016f2818) */
    .word   0x00000000                  /* Start address offset (0) */
    .word   _image_end - _image_start   /* End address offset (image size) */
    .word   0x04030201                  /* Endian magic */

reset_entry:
    /* Disable interrupts (IRQ and FIQ) in CPSR */
    cpsid   if

    /* Initialize stack pointer to safe DRAM region (0x41000000) */
    ldr     sp, =0x41000000

    /* Preserve bootloader arguments: r0 = 0, r1 = mach_type, r2 = dtb pointer */
    /* Call C entry point */
    bl      stage1_main

halt_loop:
    wfe
    b       halt_loop

.globl trigger_psci_reset
trigger_psci_reset:
    /* PSCI SYSTEM_RESET SMC call (0x84000009) */
    ldr     r0, =0x84000009
    smc     #0
    b       halt_loop
