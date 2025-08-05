/* STM32F407VG Linker Script */

MEMORY
{
    FLASH (rx)  : ORIGIN = DEFINED(__flash_origin) ? __flash_origin : 0x08000000, 
                  LENGTH = DEFINED(__flash_size) ? __flash_size : 1024K
    RAM (rwx)   : ORIGIN = DEFINED(__ram_origin) ? __ram_origin : 0x20000000, 
                  LENGTH = DEFINED(__ram_size) ? __ram_size : 128K
    CCMRAM (rw) : ORIGIN = DEFINED(__ccm_origin) ? __ccm_origin : 0x10000000, 
                  LENGTH = DEFINED(__ccm_size) ? __ccm_size : 64K
}

ENTRY(_start)

SECTIONS
{
    .isr_vector :
    {
        . = ALIGN(4);
        KEEP(*(.isr_vector))
        . = ALIGN(4);
    } > FLASH

    .text :
    {
        . = ALIGN(4);
        *(.text)
        *(.text*)
        *(.rodata)
        *(.rodata*)
        KEEP(*(.init))
        KEEP(*(.fini))
        
        /* C++ constructor arrays */
        . = ALIGN(4);
        _preinit_start = .;
        KEEP(*(.preinit_array*))
        _preinit_end = .;
        
        . = ALIGN(4);
        _init_start = .;
        KEEP(*(SORT(.init_array.*)))
        KEEP(*(.init_array*))
        _init_end = .;
        
        . = ALIGN(4);
        _fini_start = .;
        KEEP(*(SORT(.fini_array.*)))
        KEEP(*(.fini_array*))
        _fini_end = .;
        
        . = ALIGN(4);
    } > FLASH

    _data_load = LOADADDR(.data);

    .data :
    {
        . = ALIGN(4);
        _data_start = .;
        *(.data)
        *(.data*)
        . = ALIGN(4);
        _data_end = .;
    } > RAM AT > FLASH

    /* RAM関数セクション */
    .ramfunc :
    {
        . = ALIGN(4);
        _ramfunc_start = .;
        *(.ramfunc)
        *(.ramfunc*)
        . = ALIGN(4);
        _ramfunc_end = .;
    } > RAM AT > FLASH
    _ramfunc_load = LOADADDR(.ramfunc);

    .bss :
    {
        . = ALIGN(4);
        _bss_start = .;
        *(.bss)
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        _bss_end = .;
    } > RAM

    ._user_heap_stack (NOLOAD) :
    {
        . = ALIGN(8);
        PROVIDE(_heap_start = .);
        PROVIDE(_heap_end = .);
        . = . + 0x400; /* Minimum stack size */
        . = ALIGN(8);
    } > RAM

    /* Remove information from the compiler libraries */
    /DISCARD/ :
    {
        libc.a ( * )
        libm.a ( * )
        libgcc.a ( * )
    }
}

/* Stack pointer */
_stack_top = ORIGIN(RAM) + LENGTH(RAM);