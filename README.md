# ARM Embedded XMake Repository

A custom xmake package repository for ARM embedded development.

## Packages

### arm-embedded

ARM embedded development toolchain and rules.

- `gcc-arm`: GCC ARM cross-compiler
- `embedded` rule: Build settings for ARM targets
- `embedded.vscode` rule: VSCode settings generation
- `embedded.test` rule: Embedded test support

### coding-rules

C++ coding style automation.

**Features:**
- `xmake coding` command for managing code style configuration
- `coding.style` rule for build-time formatting/linting
- clangd, clang-tidy, clang-format configuration templates

## Usage

```lua
-- xmake.lua
add_repositories("arm-embedded https://github.com/tekitounix/arm-embedded-xmake-repo.git")

add_requires("arm-embedded", {optional = true})
add_requires("coding-rules", {optional = true})

-- Load coding task
local coding_rule = path.join(os.getenv("HOME") or os.getenv("USERPROFILE"), ".xmake/rules/coding/xmake.lua")
if os.isfile(coding_rule) then
    includes(coding_rule)
end
```

## xmake coding Command

After installing `coding-rules`, use the `xmake coding` command:

```bash
# Generate config files in project root
xmake coding init

# Generate specific files only
xmake coding init --clangd
xmake coding init --clang-tidy
xmake coding init --clang-format

# Overwrite existing files
xmake coding init --force

# Show current configuration
xmake coding show

# Format source files
xmake coding format
xmake coding format src/*.cc

# Check style (for CI)
xmake coding check
```

### Generated Files

| File | Git | Purpose |
|------|-----|---------|
| `.clangd` | gitignore | Editor clangd config (auto-detects ARM compiler) |
| `.clang-tidy` | managed | Code style rules |
| `.clang-format` | managed | Formatting rules |

## License

MIT License

## Documentation

- [Package Update Guide](docs/UPDATING_PACKAGES.md) - How to update gcc-arm/clang-arm packages
