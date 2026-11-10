/*
 * stage2/mmu.c
 * ARMv7-A 1:1 Identity Mapping MMU Driver
 */

#include "mmu.h"

/* 16 KB aligned L1 Section Translation Table (4096 x 4 bytes) */
__attribute__((aligned(16384)))
static uint32_t translation_table[MMU_TABLE_ENTRIES];

extern void mmu_enable_asm(uint32_t ttbr0, uint32_t dacr);

void mmu_init(void) {
    /* 1. Mapear MMIO e Periféricos (0x00000000 a 0x3FFFFFFF = 1 GB) */
    for (uint32_t i = 0; i < 1024; i++) {
        uint32_t base = i * MMU_SECTION_SIZE;
        translation_table[i] = base | MMU_ATTR_DEVICE;
    }

    /* 2. Mapear DRAM Física (0x40000000 a 0xBFFFFFFF = 2 GB de RAM) */
    for (uint32_t i = 1024; i < 3072; i++) {
        uint32_t base = i * MMU_SECTION_SIZE;
        translation_table[i] = base | MMU_ATTR_NORMAL_RAM;
    }

    /* 3. Mapear Periféricos Superiores e Espaço Reservado (0xC0000000 a 0xFFFFFFFF = 1 GB) */
    for (uint32_t i = 3072; i < 4096; i++) {
        uint32_t base = i * MMU_SECTION_SIZE;
        translation_table[i] = base | MMU_ATTR_DEVICE;
    }

    /* Domain 0 = Client (0b01) */
    uint32_t dacr = 0x00000001;
    uint32_t ttbr0 = (uint32_t)&translation_table[0];

    /* Ativar MMU, D-Cache e I-Cache */
    mmu_enable_asm(ttbr0, dacr);
}
