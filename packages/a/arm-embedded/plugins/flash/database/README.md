# Flash Plugin Database

This directory contains the flash target database for PyOCD integration.

## flash-targets.json

This file defines:

### 1. Built-in Targets
Targets that are supported by PyOCD without requiring additional device packs:
- STM32F051
- STM32F103RC  
- Generic Cortex-M

### 2. Pack-Required Targets
Targets that require PyOCD device pack installation:
- STM32F4 series (stm32f407vg, stm32f401re, etc.)
- STM32H5 series (stm32h533re, etc.)

Each pack-required target includes:
- `vendor`: Manufacturer name
- `part_number`: Specific part number
- `series`: Device series
- `families`: Device families for PyOCD
- `auto_install_pack`: Enable automatic pack installation
- `pack_name`: PyOCD pack name
- `pack_install_command`: Manual installation command

### 3. Target Aliases
Maps common MCU names to PyOCD target names:
- `stm32h533re` → `stm32h533retx`
- `stm32f407vg` → `stm32f407vgtx`
- `stm32f401re` → `stm32f401retx`

### 4. Pack Management Settings
- `auto_install_enabled`: Enable/disable automatic pack installation
- `pack_install_timeout`: Timeout for pack installation
- `common_packs`: List of commonly used PyOCD packs

## Usage

The flash plugin automatically loads this database when flashing a target. If a required pack is not installed, it will:

1. Detect the missing pack
2. Prompt the user for automatic installation
3. Install the pack if approved
4. Continue with the flash operation

## Adding New Targets

To add support for a new target:

1. Check if PyOCD supports it: `pyocd list --targets`
2. If it requires a pack, add it to `pack_required.targets`
3. If the name differs from PyOCD's name, add an alias

Example:
```json
"stm32g474re": {
  "vendor": "STMicroelectronics",
  "part_number": "STM32G474RE",
  "series": "STM32G4",
  "families": ["STM32G4 Series", "STM32G474"],
  "auto_install_pack": true,
  "pack_name": "stm32g4",
  "pack_install_command": "pyocd pack --install stm32g4"
}
```