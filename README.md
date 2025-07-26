# ARM Embedded XMake Repository

A custom xmake package repository for ARM embedded development.

## Usage

Add the following to your xmake.lua:

```lua
-- Use from GitHub repository
add_repositories("arm-embedded https://github.com/tekitounix/arm-embedded-xmake-repo.git")

-- Require packages
add_requires("llvm-embedded-arm", {host = true})
```

## Packages

- `llvm-embedded-arm`: LLVM Embedded Toolchain for Arm (official releases)

## License

MIT License