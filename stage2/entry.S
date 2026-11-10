/*
 * stage2/entry.S
 * Bare-metal Stage 2 Entry Point and ARMv7-A System Register Primitives
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
    /* Standard ARM zImage header (MediaTek LK compatibility) */
    mov     r0, r0                      /* NOP 1 */
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
    .word   _image_end - _image_start   /* End address offset */
    .word   0x04030201                  /* Endian magic */

reset_entry:
    /* Disable interrupts (IRQ and FIQ) */
    cpsid   if

    /* Initialize stack pointer to safe DRAM region (0x41000000) */
    ldr     sp, =0x41000000

    /* Call C entry point with bootloader arguments */
    bl      stage2_main

halt_loop:
    wfe
    b       halt_loop

/*
 * void mmu_enable_asm(uint32_t ttbr0, uint32_t dacr);
 */
.globl mmu_enable_asm
mmu_enable_asm:
    /* r0 = ttbr0, r1 = dacr */
    dsb
    isb

    /* 1. Invalidate TLB */
    mcr     p15, 0, r0, c8, c7, 0       /* TLBIALL */

    /* 2. Set Domain Access Control Register (DACR) */
    mcr     p15, 0, r1, c3, c0, 0

    /* 3. Set TTBCR (Translation Table Base Control Register) = 0 (32-bit short-descriptor) */
    mov     r2, #0
    mcr     p15, 0, r2, c2, c0, 2

    /* 4. Set TTBR0 (Translation Table Base Register 0) */
    mcr     p15, 0, r0, c2, c0, 0

    isb

    /* 5. Read SCTLR, enable MMU (bit 0), D-Cache (bit 2), I-Cache (bit 12) */
    mrc     p15, 0, r2, c1, c0, 0
    orr     r2, r2, #(1 << 0)           /* M: MMU enable */
    orr     r2, r2, #(1 << 2)           /* C: Data cache enable */
    orr     r2, r2, #(1 << 12)          /* I: Instruction cache enable */
    mcr     p15, 0, r2, c1, c0, 0

    dsb
    isb
    bx      lr

/*
 * uint64_t timer_get_cntvct_asm(void);
 * Returns 64-bit counter value in r0 (low), r1 (high)
 */
.globl timer_get_cntvct_asm
timer_get_cntvct_asm:
    mrrc    p15, 1, r0, r1, c14         /* CNTVCT (Virtual Count) */
    bx      lr

/*
 * uint32_t timer_get_cntfrq_asm(void);
 */
.globl timer_get_cntfrq_asm
timer_get_cntfrq_asm:
    mrc     p15, 0, r0, c14, c0, 0      /* CNTFRQ */
    bx      lr

/*
 * void timer_enable_cntv_asm(void);
 */
.globl timer_enable_cntv_asm
timer_enable_cntv_asm:
    mov     r0, #1
    mcr     p15, 0, r0, c14, c3, 1      /* CNTV_CTL: enable=1, imask=0 */
    isb
    bx      lr

/*
 * void trigger_psci_reset(void);
 */
.globl trigger_psci_reset
trigger_psci_reset:
    ldr     r0, =0x84000009             /* PSCI SYSTEM_RESET */
    smc     #0
    b       halt_loop
