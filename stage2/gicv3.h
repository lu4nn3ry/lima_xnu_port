#ifndef STAGE2_GICV3_H
#define STAGE2_GICV3_H

#include <stdint.h>

#define GICD_BASE           0x0c000000
#define GICR_BASE           0x0c100000
#define GICR_SGI_BASE       (GICR_BASE + 0x10000)

/* GICD Registers */
#define GICD_CTLR           (*(volatile uint32_t *)(GICD_BASE + 0x0000))
#define GICD_TYPER          (*(volatile uint32_t *)(GICD_BASE + 0x0004))
#define GICD_IIDR           (*(volatile uint32_t *)(GICD_BASE + 0x0008))

/* GICR Registers */
#define GICR_WAKER          (*(volatile uint32_t *)(GICR_BASE + 0x0014))
#define GICR_WAKER_ProcessorSleep   (1 << 1)
#define GICR_WAKER_ChildrenAsleep   (1 << 2)

/* GICR SGI/PPI Registers */
#define GICR_ISENABLER0     (*(volatile uint32_t *)(GICR_SGI_BASE + 0x0100))

void gicv3_init(void);

#endif
