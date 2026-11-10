/*
 * stage2/stage2.ld
 * Linker script for Stage 2 Bare-Metal Loader (MT6771 entry at 0x40008000)
 */

ENTRY(_start)

SECTIONS
{
    . = 0x40008000;

    .text : {
        KEEP(*(.text.entry))
        *(.text*)
        *(.rodata*)
    }

    .data : {
        *(.data*)
    }

    .bss (NOLOAD) : {
        __bss_start = .;
        *(.bss*)
        *(COMMON)
        __bss_end = .;
    }

    _image_end = .;

    /DISCARD/ : {
        *(.ARM.exidx*)
        *(.ARM.extab*)
        *(.comment)
        *(.ARM.attributes)
        *(.note*)
    }
}
