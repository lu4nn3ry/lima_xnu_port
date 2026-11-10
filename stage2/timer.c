/*
 * stage2/timer.c
 * ARMv7-A Generic Timer Driver (13 MHz)
 */

#include "timer.h"

extern uint64_t timer_get_cntvct_asm(void);
extern uint32_t timer_get_cntfrq_asm(void);
extern void timer_enable_cntv_asm(void);

void timer_init(void) {
    /* Habilitar Virtual Timer (CNTV) */
    timer_enable_cntv_asm();
}

uint64_t timer_get_ticks(void) {
    return timer_get_cntvct_asm();
}

void timer_delay_us(uint32_t us) {
    /* 13 ticks por microsegundo (13 MHz / 1.000.000) */
    uint64_t ticks_to_wait = (uint64_t)us * 13ULL;
    uint64_t start = timer_get_ticks();
    while ((timer_get_ticks() - start) < ticks_to_wait) {
        __asm__ volatile("nop");
    }
}

void timer_delay_ms(uint32_t ms) {
    /* 13.000 ticks por milisegundo */
    uint64_t ticks_to_wait = (uint64_t)ms * 13000ULL;
    uint64_t start = timer_get_ticks();
    while ((timer_get_ticks() - start) < ticks_to_wait) {
        __asm__ volatile("nop");
    }
}
