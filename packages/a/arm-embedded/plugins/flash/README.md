# Flash Plugin for ARM Embedded Targets

A plugin to flash ARM microcontrollers using PyOCD.

## Usage

```bash
xmake flash [options] [target]
```

## Options

| Option | Short | Description | Example |
|--------|-------|-------------|---------|
| `--target` | `-t` | Specify target to flash | `xmake flash -t stm32f4-discovery` |
| `--device` | `-d` | Override target device | `xmake flash -d stm32f407vg` |
| `--frequency` | `-f` | Set SWD clock frequency | `xmake flash -f 4M` |
| `--erase` | `-e` | Perform chip erase before programming | `xmake flash -e` |
| `--reset` | `-r` | Reset target after programming | `xmake flash -r` |
| `--no-reset` | `-n` | Do not reset target after programming | `xmake flash -n` |
| `--probe` | | Specify debug probe to use | `xmake flash --probe 0669FF37` |
| `--connect` | | Connection mode | `xmake flash --connect halt` |

## Features

- **Automatic Target Selection**: Uses the default target if not specified
- **Multi-Probe Support**: Interactive selection when multiple probes are connected
- **Progress Display**: Shows flashing progress with file size and transfer speed
- **Error Handling**: Detailed error messages and troubleshooting tips

## Multi-Probe Environment

When multiple debug probes are connected:

1. The plugin will detect all connected probes
2. Display a list with probe type, UID, and target information
3. Prompt for selection (with default suggestion if a matching target is found)
4. You can skip probe detection by specifying the probe UID directly:
   ```bash
   xmake flash --probe 0669FF3731324B4D43183949
   ```

## Troubleshooting

If flashing fails:
1. Check debug probe connection
2. Verify target power supply
3. Try different USB port/cable
4. Update probe firmware if needed
5. Run with elevated privileges if necessary
6. If multiple probes connected, use: `xmake flash --probe <unique_id>`

For verbose output:
```bash
pyocd flash --verbose --format elf <target_file>
```