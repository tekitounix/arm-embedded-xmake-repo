/*
 * Common linker script for ARM Cortex-M microcontrollers
 * Memory configuration is provided via linker symbols
 */

/* Entry Point */
ENTRY(Reset_Handler)

/* Memory regions - defined by linker symbols */
MEMORY
{
    FLASH (rx)  : ORIGIN = __flash_origin, LENGTH = __flash_size
    RAM   (rwx) : ORIGIN = __ram_origin,   LENGTH = __ram_size
}

/* Stack size */
__stack_size = 0x2000;  /* 8KB default stack */

SECTIONS
{
    /* Interrupt vector table */
    .isr_vector :
    {
        . = ALIGN(4);
        KEEP(*(.isr_vector))
        . = ALIGN(4);
    } > FLASH

    /* Program code and read-only data */
    .text :
    {
        . = ALIGN(4);
        *(.text)
        *(.text*)
        *(.glue_7)
        *(.glue_7t)
        *(.eh_frame)

        KEEP(*(.init))
        KEEP(*(.fini))

        . = ALIGN(4);
        _etext = .;
    } > FLASH

    /* Read-only data */
    .rodata :
    {
        . = ALIGN(4);
        *(.rodata)
        *(.rodata*)
        . = ALIGN(4);
    } > FLASH

    /* ARM exception handling */
    .ARM.extab :
    {
        . = ALIGN(4);
        *(.ARM.extab* .gnu.linkonce.armextab.*)
        . = ALIGN(4);
    } > FLASH

    .ARM :
    {
        . = ALIGN(4);
        __exidx_start = .;
        *(.ARM.exidx* .gnu.linkonce.armexidx.*)
        __exidx_end = .;
        . = ALIGN(4);
    } > FLASH

    /* Used by C++ runtime for static constructors */
    .preinit_array :
    {
        . = ALIGN(4);
        PROVIDE_HIDDEN(__preinit_array_start = .);
        KEEP(*(.preinit_array*))
        PROVIDE_HIDDEN(__preinit_array_end = .);
        . = ALIGN(4);
    } > FLASH

    .init_array :
    {
        . = ALIGN(4);
        PROVIDE_HIDDEN(__init_array_start = .);
        KEEP(*(SORT(.init_array.*)))
        KEEP(*(.init_array*))
        PROVIDE_HIDDEN(__init_array_end = .);
        . = ALIGN(4);
    } > FLASH

    .fini_array :
    {
        . = ALIGN(4);
        PROVIDE_HIDDEN(__fini_array_start = .);
        KEEP(*(SORT(.fini_array.*)))
        KEEP(*(.fini_array*))
        PROVIDE_HIDDEN(__fini_array_end = .);
        . = ALIGN(4);
    } > FLASH

    /* Load address of .data section */
    _sidata = LOADADDR(.data);
    __data_lma__ = LOADADDR(.data);

    /* Initialized data sections */
    .data :
    {
        . = ALIGN(4);
        _sdata = .;
        __data_start__ = .;
        *(.data)
        *(.data*)
        . = ALIGN(4);
        _edata = .;
        __data_end__ = .;
    } > RAM AT> FLASH

    /* Uninitialized data section */
    .bss :
    {
        . = ALIGN(4);
        _sbss = .;
        __bss_start__ = .;
        *(.bss)
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
        __bss_end__ = .;
    } > RAM

    /* Stack section */
    .stack :
    {
        . = ALIGN(8);
        _sstack = .;
        . = . + __stack_size;
        . = ALIGN(8);
        _estack = .;
    } > RAM

    /* Remove debugging information */
    /DISCARD/ :
    {
        *(.debug*)
        *(.comment)
        *(.ARM.attributes)
    }
}

/* Export symbols for startup code */
PROVIDE(_stack = _estack);
PROVIDE(__stack = _estack);