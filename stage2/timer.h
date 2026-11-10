#ifndef STAGE2_TIMER_H
#define STAGE2_TIMER_H

#include <stdint.h>

#define ARM_TIMER_FREQ_HZ   13000000ULL

void timer_init(void);
uint64_t timer_get_ticks(void);
void timer_delay_ms(uint32_t ms);
void timer_delay_us(uint32_t us);

#endif
