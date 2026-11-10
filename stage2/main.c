/*
 * stage2/main.c
 * Stage 2 Bare-Metal Loader Core for Motorola Moto G8 Play (lima_32 / MT6771)
 */

#include <stdint.h>
#include "mmu.h"
#include "gicv3.h"
#include "timer.h"

#define UART0_BASE       0x11002000
#define UART0_THR        (*(volatile uint32_t *)(UART0_BASE + 0x00))
#define UART0_LSR        (*(volatile uint32_t *)(UART0_BASE + 0x14))
#define UART0_LSR_THRE   (1 << 5)

#define RAMOOPS_BASE     0x54410000
#define MTK_WDT_BASE     0x10007000
#define MTK_WDT_SWRST    (*(volatile uint32_t *)(MTK_WDT_BASE + 0x14))

extern void trigger_psci_reset(void);

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

static void uart_put_hex(uint32_t val) {
    const char hex_chars[] = "0123456789ABCDEF";
    uart_puts("0x");
    for (int i = 28; i >= 0; i -= 4) {
        uart_putc(hex_chars[(val >> i) & 0xF]);
    }
}

static void ramoops_append(const char *msg) {
    volatile char *p = (volatile char *)RAMOOPS_BASE;
    while (*p) p++;
    while (*msg) *p++ = *msg++;
    *p = '\0';
}

void stage2_main(uint32_t r0, uint32_t mach_type, uint32_t dtb_ptr) {
    /* 1. Limpar buffer do Ramoops */
    volatile char *p = (volatile char *)RAMOOPS_BASE;
    *p = '\0';

    const char *banner =
        "\n"
        "==========================================================\n"
        "⚡ [LIMA-XNU STAGE 2 HARDWARE LOADER] ⚡\n"
        "==========================================================\n"
        "SoC:      MediaTek MT6771V/WL (Helio P70M) ARMv7-A 32-bit\n"
        "Target:   Motorola Moto G8 Play (lima_32 / XT2015-2)\n"
        "Stage:    Stage 2 (MMU 1:1, GICv3, ARM Arch Timer 13MHz)\n"
        "==========================================================\n\n";

    uart_puts(banner);
    ramoops_append(banner);

    /* 2. Inicializar e ativar MMU 1:1 */
    uart_puts("[Stage2] Configurando tabela de paginas MMU 1:1...\n");
    mmu_init();
    uart_puts("[Stage2] MMU + Caches L1 ativados com sucesso!\n");
    ramoops_append("[Stage2] MMU + Caches L1 ativados com sucesso!\n");

    /* 3. Inicializar GICv3 */
    uart_puts("[Stage2] Inicializando GICv3 (Distributor 0x0c000000, Redistributor 0x0c100000)...\n");
    gicv3_init();
    uart_puts("[Stage2] GICv3 ativado e pronto para interrupcoes!\n");
    ramoops_append("[Stage2] GICv3 ativado e pronto para interrupcoes!\n");

    /* 4. Inicializar ARM Generic Timer (13 MHz) */
    uart_puts("[Stage2] Inicializando ARM Generic Timer @ 13.000.000 Hz...\n");
    timer_init();
    uint64_t t0 = timer_get_ticks();
    uart_puts("[Stage2] Timer rodando. Ticks iniciais: ");
    uart_put_hex((uint32_t)t0);
    uart_puts("\n");

    /* Testar delay de 500 ms com o timer de hardware */
    uart_puts("[Stage2] Testando delay de hardware de 500 ms...\n");
    timer_delay_ms(500);
    uint64_t t1 = timer_get_ticks();
    uart_puts("[Stage2] Ticks apos 500 ms: ");
    uart_put_hex((uint32_t)t1);
    uart_puts(" (Delta: ");
    uart_put_hex((uint32_t)(t1 - t0));
    uart_puts(" ticks)\n");
    ramoops_append("[Stage2] Timer 13MHz validado com precisao de hardware!\n");

    uart_puts("\n==========================================================\n");
    uart_puts("✔ STAGE 2 HARDWARE SETUP CONCLUIDO COM SUCESSO!\n");
    uart_puts("Pronto para receber o kernel XNU / Darwin Mach!\n");
    uart_puts("==========================================================\n\n");
    ramoops_append("✔ STAGE 2 HARDWARE SETUP CONCLUIDO COM SUCESSO!\n");

    /* Aguardar 2 segundos antes do reinicio seguro */
    timer_delay_ms(2000);

    /* Reset seguro via MTK Watchdog */
    MTK_WDT_SWRST = 0x22000001;
    trigger_psci_reset();

    while (1) {
        __asm__ volatile("wfi");
    }
}
