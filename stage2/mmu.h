#ifndef STAGE2_MMU_H
#define STAGE2_MMU_H

#include <stdint.h>

#define MMU_TABLE_ENTRIES   4096
#define MMU_SECTION_SIZE    (1024 * 1024)

/* Section attributes for ARMv7-A Short Descriptor */
/* Bit [1:0] = 0b10 (Section descriptor) */
#define MMU_DESC_SECTION        (2 << 0)
/* Bit [2] = B, Bit [3] = C (Cacheability) */
#define MMU_DESC_BUFFERABLE     (1 << 2)
#define MMU_DESC_CACHEABLE      (1 << 3)
/* Bit [4] = XN (Execute Never) */
#define MMU_DESC_XN             (1 << 4)
/* Domain [8:5] = Domain 0 */
#define MMU_DESC_DOMAIN0        (0 << 5)
/* AP[1:0] = 0b11 (Read/Write for both Privileged and User) */
#define MMU_DESC_AP_RW          (3 << 10)
/* Bit [16] = S (Shareable) */
#define MMU_DESC_SHAREABLE      (1 << 16)

/* Device MMIO attribute: Strongly-Ordered / Device, Non-cacheable, XN */
#define MMU_ATTR_DEVICE         (MMU_DESC_SECTION | MMU_DESC_DOMAIN0 | MMU_DESC_AP_RW | MMU_DESC_XN)

/* Normal RAM attribute: Inner/Outer Write-Back Write-Allocate, Cacheable, Shareable */
#define MMU_ATTR_NORMAL_RAM     (MMU_DESC_SECTION | MMU_DESC_DOMAIN0 | MMU_DESC_AP_RW | MMU_DESC_BUFFERABLE | MMU_DESC_CACHEABLE | MMU_DESC_SHAREABLE)

void mmu_init(void);

#endif
