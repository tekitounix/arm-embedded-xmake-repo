# ARM Embedded Database Files

This directory contains JSON database files that define various configurations for ARM embedded development.

## File Structure

### cortex-m.json
Contains Cortex-M core definitions including:
- Architecture specifications
- Compiler flags for GCC and LLVM
- FPU configurations
- Library paths

### mcu-database.json
MCU-specific configurations including:
- Core type mapping
- Memory sizes (Flash and RAM)
- Memory origin addresses
- Vendor information

### build-options.json
Build configuration options including:
- Optimization levels
- Debug information levels
- Semihosting settings
- C++ embedded options
- Linker options for different toolchains
- Bare-metal specific flags

### toolchain-configs.json
Toolchain-related configurations including:
- Toolchain mappings
- Package paths
- Linker script locations
- Memory symbol definitions


## Usage

These JSON files are loaded by the embedded rule (`../xmake.lua`) to provide data-driven configuration. This separation allows for easy updates and maintenance of target definitions without modifying the rule logic.

Note: Flash target configurations have been moved to the flash plugin's own database directory (`plugins/flash/database/`).

## Adding New Targets

To add a new MCU target:
1. Add the MCU definition to `mcu-database.json`
2. If it's a new core type, add it to `cortex-m.json`
3. If it requires PyOCD support, add it to `plugins/flash/database/flash-targets.json`

Example MCU entry:
```json
"stm32f429zi": {
  "core": "cortex-m4f",
  "flash": "2M",
  "ram": "256K",
  "flash_origin": "0x08000000",
  "ram_origin": "0x20000000",
  "vendor": "st"
}
```

