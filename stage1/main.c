/*
 * stage1/main.c
 * Bare-metal Stage 1 Loader logic for Motorola Moto G8 Play (lima_32 / MT6771)
 */

#include <stdint.h>

/* Hardware memory map definitions */
#define UART0_BASE       0x11002000
#define UART0_THR        (*(volatile uint32_t *)(UART0_BASE + 0x00))
#define UART0_LSR        (*(volatile uint32_t *)(UART0_BASE + 0x14))
#define UART0_LSR_THRE   (1 << 5)

#define RAMOOPS_BASE     0x54410000
#define RAMOOPS_SIZE     (256 * 1024)

#define FB_BASE          0x7d4f0000
#define FB_WIDTH         720
#define FB_HEIGHT        1520
#define FB_PIXELS        (FB_WIDTH * FB_HEIGHT)

#define MTK_WDT_BASE     0x10007000
#define MTK_WDT_SWRST    (*(volatile uint32_t *)(MTK_WDT_BASE + 0x14))
#define MTK_WDT_RESTART  (*(volatile uint32_t *)(MTK_WDT_BASE + 0x08))

extern void trigger_psci_reset(void);

/* UART primitives */
static void uart_putc(char c) {
    if (c == '\n') {
        while (!(UART0_LSR & UART0_LSR_THRE));
        UART0_THR = '\r';
    }
    while (!(UART0_LSR & UART0_LSR_THRE));
    UART0_THR = (uint32_t)c;
}

static void uart_puts(const char *s) {
    while (*s) {
        uart_putc(*s++);
    }
}

/* Ramoops primitives */
static void ramoops_write(const char *msg) {
    volatile char *p = (volatile char *)RAMOOPS_BASE;
    while (*msg) {
        *p++ = *msg++;
    }
    *p = '\0';
}

/* Framebuffer test */
static void fb_fill(uint32_t color) {
    volatile uint32_t *fb = (volatile uint32_t *)FB_BASE;
    for (uint32_t i = 0; i < FB_PIXELS; i++) {
        fb[i] = color;
    }
}

/* Delay loop */
static void delay_cycles(volatile uint32_t count) {
    while (count--) {
        __asm__ volatile("nop");
    }
}

/* Watchdog hardware reset */
static void mtk_watchdog_reset(void) {
    /* MTK Watchdog Software Reset key: 0x22000000 | 0x0001 */
    MTK_WDT_SWRST = 0x22000001;
}

void stage1_main(uint32_t r0, uint32_t mach_type, uint32_t dtb_ptr) {
    const char *banner =
        "\n"
        "==========================================================\n"
        "🚀 [LIMA-XNU STAGE1 BARE-METAL LOADER] 🚀\n"
        "==========================================================\n"
        "SoC:      MediaTek MT6771V/WL (Helio P70M)\n"
        "Device:   Motorola Moto G8 Play (XT2015-2 / lima_32)\n"
        "Arch:     ARMv7-A 32-bit (bare-metal AArch32)\n"
        "Slot:     SLOT B (boot_b) - ISOLADO COM SUCESSO!\n"
        "Entry:    0x40008000 | Stack: 0x41000000\n"
        "Ramoops:  0x54410000 (persiste entre reboots no /sys/fs/pstore)\n"
        "UART0:    0x11002000 @ 921600 baud\n"
        "FB Base:  0x7d4f0000 (720x1520 @ 32bpp)\n"
        "Status:   STAGE 1 EXECUTOU EM HARDWARE REAL!\n"
        "==========================================================\n\n";

    /* 1. Emitir caracteres na UART serial */
    uart_puts(banner);

    /* 2. Gravar no Ramoops Console persistente */
    ramoops_write(banner);

    /* 3. Desenhar no Framebuffer (cor sólida magenta / Apple purple: 0xFF800080) */
    fb_fill(0xFF800080);

    uart_puts("[Stage1] Assinatura salva no Ramoops e UART0 emitida.\n");
    uart_puts("[Stage1] Aguardando 3 segundos antes do reinicio seguro...\n");

    /* Delay de ~3 segundos (contagem empírica a 2.0 GHz) */
    delay_cycles(15000000);

    uart_puts("[Stage1] Acionando reset do sistema...\n");

    /* 4. Tentar reset via Watchdog da MediaTek */
    mtk_watchdog_reset();

    /* 5. Se o WDT não disparar imediatamente, tentar chamada PSCI */
    trigger_psci_reset();

    /* 6. Loop final de segurança */
    while (1) {
        __asm__ volatile("wfi");
    }
}
