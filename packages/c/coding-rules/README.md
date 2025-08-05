# Coding Rules Package

C++ coding style and testing automation for embedded development.

## Overview

The `coding-rules` package provides automated code formatting, static analysis, and testing tools for C++ embedded projects. It enforces consistent coding standards and helps maintain code quality across your project.

## Features

- **Automatic Code Formatting**: Uses clang-format to enforce consistent code style
- **Static Analysis**: Integrates clang-tidy for naming conventions and code quality checks
- **Test Automation**: Provides testing framework with sanitizer support
- **CI/CD Support**: Includes rules for continuous integration environments
- **xmake Tasks**: Convenient commands for formatting, linting, and checking code

## Installation

Add the package to your `xmake.lua`:

```lua
add_repositories("arm-embedded https://github.com/your-repo/arm-embedded-xmake-repo.git")
add_requires("coding-rules")
```

## Usage

### Rules

#### coding.style

Automatically formats and checks code during build:

```lua
target("my-app")
    add_rules("coding.style")
    add_files("src/*.cc")
    
    -- Configuration options (all default to true if not specified)
    set_values("coding.style.format", true)   -- Enable auto-formatting
    set_values("coding.style.check", true)    -- Enable naming convention checks
    set_values("coding.style.fix", true)      -- Enable auto-fixing of naming conventions
    set_values("coding.style.headers", true)  -- Process header files in include directories
```

This rule will:
- Format all source files with clang-format before compilation
- Apply naming convention fixes with clang-tidy
- Process header files in include directories

##### Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `coding.style.format` | `true` | Enable automatic code formatting with clang-format |
| `coding.style.check` | `true` | Enable naming convention checks with clang-tidy |
| `coding.style.fix` | `true` | Enable automatic fixing of naming convention issues |
| `coding.style.headers` | `true` | Process header files in include directories |

##### Usage Examples

```lua
-- Example 1: Only format, no checks or fixes
target("my-app")
    add_rules("coding.style")
    set_values("coding.style.check", false)
    set_values("coding.style.fix", false)

-- Example 2: Check only, no automatic changes
target("my-app")
    add_rules("coding.style")
    set_values("coding.style.format", false)
    set_values("coding.style.fix", false)

-- Example 3: Fast build - skip header processing
target("my-app")
    add_rules("coding.style")
    set_values("coding.style.headers", false)
```

#### coding.style.ci

For CI environments where auto-fixing is not desired:

```lua
target("my-app")
    add_rules("coding.style.ci")
    add_files("src/*.cc")
```

This rule will fail the build if any files need formatting.

#### coding.test

Configures testing with sanitizer support:

```lua
target("my-test")
    add_rules("coding.test")
    set_values("testing.sanitizers", {"address", "undefined"})
    add_files("test/*.cc")
```

Available sanitizers (host builds only):
- `address`: Memory error detection
- `undefined`: Undefined behavior detection
- `thread`: Data race detection
- `memory`: Uninitialized memory detection

#### coding.test.coverage

Enables code coverage analysis:

```lua
target("my-test")
    add_rules("coding.test.coverage")
    add_files("test/*.cc")
```

### xmake Tasks

#### Format Code

Format all source files in your project:

```bash
xmake format
```

Format only a specific target:

```bash
xmake format --target=my-app
```

#### Lint Code

Run static analysis:

```bash
xmake lint
```

Fix issues automatically:

```bash
xmake lint --fix
```

Specify custom checks:

```bash
xmake lint --checks="readability-*,performance-*"
```

#### Comprehensive Check

Run all quality checks:

```bash
xmake check
```

Run with full build check:

```bash
xmake check --full
```

## Configuration

The package uses the following configuration files:

- `.clang-format`: Code formatting rules
- `.clang-tidy`: Static analysis and naming conventions
- `.clangd`: Language server configuration

These files are automatically installed and used by the rules.

## Coding Standards

The package enforces the following naming conventions:

- **Classes**: `PascalCase` (e.g., `MyClass`)
- **Functions**: `snake_case` (e.g., `my_function`)
- **Variables**: `snake_case` (e.g., `my_variable`)
- **Constants**: `SCREAMING_SNAKE_CASE` (e.g., `MY_CONSTANT`)
- **Private members**: `snake_case_` with trailing underscore

See the included `style_guide.md` for complete coding standards.

## Requirements

- clang-format (for formatting)
- clang-tidy (for static analysis)
- C++23 compatible compiler

## Integration with CI/CD

For GitHub Actions:

```yaml
- name: Check code style
  run: |
    xmake config
    xmake check
```

For GitLab CI:

```yaml
check:
  script:
    - xmake config
    - xmake check
```

## Troubleshooting

### clang-format not found

Install clang-format:
- macOS: `brew install clang-format`
- Ubuntu: `sudo apt install clang-format`
- Windows: Install LLVM

### Files not being formatted

Ensure your files are included in the target:
- Use `add_files()` for source files
- Use `add_headerfiles()` for headers
- Check include directories with `add_includedirs()`

### CI build failures

Use `coding.style.ci` rule instead of `coding.style` to prevent auto-fixing in CI environments.

## License

This package is part of the arm-embedded-xmake-repo project.