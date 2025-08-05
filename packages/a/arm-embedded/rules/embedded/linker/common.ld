MEMORY
{
    FLASH (rx)  : ORIGIN = __flash_origin, LENGTH = __flash_size
    RAM (rwx)   : ORIGIN = __ram_origin,   LENGTH = __ram_size
    CCMRAM (rw) : ORIGIN = __ccm_origin,   LENGTH = __ccm_size
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

    .heap (NOLOAD) :
    {
        . = ALIGN(4);
        PROVIDE(_heap_start = .);
    } > RAM

    .debug_info     0 : { *(.debug_info .gnu.linkonce.wi.*) }
    .debug_abbrev   0 : { *(.debug_abbrev) }
    .debug_line     0 : { *(.debug_line) }
    .debug_frame    0 : { *(.debug_frame) }
    .debug_str      0 : { *(.debug_str) }
    .debug_loc      0 : { *(.debug_loc) }
    .debug_macinfo  0 : { *(.debug_macinfo) }
    .debug_ranges   0 : { *(.debug_ranges) }
}

_stack_top = ORIGIN(RAM) + LENGTH(RAM);