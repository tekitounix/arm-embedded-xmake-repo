# ARM Embedded XMake Repository

A custom xmake package repository for ARM embedded development.

## Packages

### arm-embedded

ARM embedded development toolchain and rules.

- `gcc-arm`: GCC ARM cross-compiler
- `clang-arm`: LLVM ARM cross-compiler (optional)
- `embedded` rule: Build settings for ARM targets
- `embedded.vscode` rule: VSCode settings generation
- `embedded.test` rule: Embedded test support
- `host.test` rule: Host-side test support

**Plugins:**
- `xmake flash -t <target>`: Flash firmware to target
- `xmake debugger -t <target>`: Start GDB debugger with pyOCD
- `xmake emulator.*`: Renode emulator tasks
- `xmake deploy -t <target>`: Deploy build artifacts

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

## Commands

### xmake標準機能（v2.7+）

これらはxmakeに標準搭載されており、arm-embeddedでは提供しません：

```bash
# フォーマット
xmake format              # clang-format でフォーマット
xmake format -n           # Dry-run
xmake format -e           # エラーとして報告（CI向け）
xmake format -g test      # グループ指定

# 静的解析
xmake check               # プロジェクト設定チェック
xmake check clang.tidy    # clang-tidy 実行
xmake check --list        # チェッカー一覧

# プロジェクト情報
xmake show                # プロジェクト情報表示

# テスト
xmake test                # テスト実行（標準 or プロジェクト定義）

# デバッグビルド
xmake f -m debug && xmake # デバッグモードでビルド
```

### arm-embedded 提供機能

組み込み開発固有の機能を提供します：

```bash
# フラッシュ書き込み (pyOCD)
xmake flash -t <target>
xmake flash -t stm32f4_kernel -a 0x08000000
xmake flash --help

# GDBデバッガー
xmake debugger -t <target>
xmake debugger --help

# エミュレータ (Renode)
xmake emulator            # ヘルプ表示
xmake emulator.run        # 対話セッション
xmake emulator.test       # 自動テスト
xmake emulator.robot      # Robot Framework

# デプロイ
xmake deploy -t <target>
xmake deploy.webhost
xmake deploy.serve
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
```

Note: `xmake format` と `xmake check clang.tidy` はxmake標準機能を使用してください。

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

