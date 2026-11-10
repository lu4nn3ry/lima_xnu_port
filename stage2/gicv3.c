/*
 * stage2/gicv3.c
 * ARM Generic Interrupt Controller v3 (GICv3) Initialization
 */

#include "gicv3.h"

void gicv3_init(void) {
    /* 1. Habilitar o Distribuidor (GICD) */
    /* EnableGrp0 (bit 0) | EnableGrp1NS (bit 1) */
    GICD_CTLR |= 0x3;

    /* 2. Acordar o Redistribuidor (GICR) da CPU de boot */
    /* Limpar bit ProcessorSleep */
    GICR_WAKER &= ~GICR_WAKER_ProcessorSleep;

    /* Aguardar ChildrenAsleep ser limpo pelo hardware */
    while (GICR_WAKER & GICR_WAKER_ChildrenAsleep) {
        __asm__ volatile("nop");
    }

    /* 3. Habilitar SGIs e PPIs locais da CPU */
    GICR_ISENABLER0 = 0xFFFFFFFF;
}
