# ARM Embedded Build Rule

This directory contains the ARM embedded build rule and its supporting database modules.

## Structure

- `xmake.lua` - Main rule implementation
- `cortex-m.lua` - Cortex-M core definitions and configurations
- `mcu-database.lua` - MCU-specific configurations with memory layouts
- `build-options.lua` - Build options for optimization, debug, and toolchain settings
- `toolchain-configs.lua` - Toolchain detection and configuration

## Database Files

### cortex-m.lua
Contains comprehensive Cortex-M core definitions including:
- Architecture specifications (ARMv6-M, ARMv7-M, ARMv8-M, etc.)
- GCC and LLVM compiler flags
- FPU configurations
- Library paths for different architectures

### mcu-database.lua
MCU-specific configurations including:
- Core type mapping
- Flash and RAM sizes
- Memory origin addresses
- Vendor information

### build-options.lua
Build configuration options:
- Optimization levels (size, speed, balanced, debug)
- Debug options (debug info levels, stack protection)
- Semihosting support
- C++ options (RTTI, exceptions, etc.)
- Toolchain-specific linker options
- Bare-metal specific options

### toolchain-configs.lua
Toolchain management:
- Toolchain detection patterns
- Binary mappings for GCC and LLVM
- Package paths and structure
- Library configurations
- Version detection

## Usage

The rule is automatically loaded when you use:
```lua
target("my-firmware")
    add_rules("embedded")
    set_values("embedded.mcu", "stm32f407vg")
    set_values("embedded.toolchain", "gcc")  -- or "llvm"
    set_values("embedded.optimize", "size")  -- size/speed/balanced/debug
    set_values("embedded.c_standard", "c11")     -- C standard: c99/c11/c17/c23/gnu99/gnu11/gnu17/gnu23
    set_values("embedded.cxx_standard", "c++17")  -- C++ standard: c++98/c++03/c++11/c++14/c++17/c++20/c++23
```

### C++ Compiler Flags

The embedded rule automatically applies the following C++ flags for all targets:
- `-fno-rtti`: Disables Run-Time Type Information
- `-fno-exceptions`: Disables C++ exceptions
- `-fno-threadsafe-statics`: Disables thread-safe static initialization

These flags are standard for embedded C++ development (both bare metal and RTOS) as they:
- Reduce code size significantly
- Remove runtime overhead
- Are compatible with all embedded environments

## Adding New MCUs

To add a new MCU, edit `mcu-database.lua` and add an entry to `mcu_db.CONFIGS`:
```lua
["stm32f103c8"] = { 
    core = "cortex-m3", 
    flash = "64K", 
    ram = "20K", 
    flash_origin = "0x08000000", 
    ram_origin = "0x20000000",
    vendor = "st"
}
```

## Adding New Cores

To add a new Cortex-M core, edit `cortex-m.lua` and add an entry to `cortex_m.CORES`:
```lua
["cortex-m55"] = {
    arch = "armv8.1-m.main",
    gcc  = { mcpu = "cortex-m55", mfpu = "fpv5-sp-d16", mfloat_abi = "hard" },
    llvm = { target = "armv8.1m.main-none-eabi", mfpu = "fpv5-sp-d16", mfloat_abi = "hard" },
    features = { thumb = true, dsp = true, mve = true, trustzone = true, fpu = "fpv5-sp-d16" },
    lib  = "armv8_1m_main_hard_fpv5_sp_d16/lib"
}
```