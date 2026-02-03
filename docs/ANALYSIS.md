# arm-embedded-xmake-repo 問題点分析

## 現状の課題

### 1. clangd設定の問題

**症状:**
- IntelliSenseが不安定
- クロスコンパイラのヘッダが見つからない
- エラーが多発する

**原因:**
- `.clangd`に`--query-driver`が設定されていない
- coding-rulesパッケージの`.clangd`は最小限の設定のみ
- VSCode ruleで`settings.json`にquery-driverを書いているが、`.clangd`と二重管理

**現在の`.clangd`:**
```yaml
CompileFlags:
  CompilationDatabase: .build/
```

**あるべき姿:**
```yaml
CompileFlags:
  CompilationDatabase: .build/
  Add:
    - --target=arm-none-eabi
  Remove:
    - -mfpu=*
    - -mfloat-abi=*
```

### 2. query-driverパスの問題

**症状:**
- xmakeパッケージパスが変わるとclangdが動作しない
- ワイルドカードパスが機能しない場合がある

**現在の実装（vscode/xmake.lua）:**
```lua
driver = "~/.xmake/packages/g/gcc-arm/*/bin/arm-none-eabi-g++"
```

**問題点:**
- パスがハードコード
- xmakeのキャッシュパスは環境により異なる
- Homebrew版やシステム版のツールチェーンは対象外

### 3. MCUマッピングの不完全性

**症状:**
- launch.jsonのdevice設定が一部MCUでしか動作しない

**現在のマッピング（7個のみ）:**
```lua
mcu_to_device = {
    ["stm32f407vgt6"] = "STM32F407VG",
    ["stm32f411ceu6"] = "STM32F411CE",
    -- ...
}
```

**問題点:**
- mcu-database.jsonには50+個のMCU定義あり
- 新規MCU追加時に複数箇所の修正が必要

### 4. 設定ファイルの二重管理

**現在の構造:**
```
coding-rules/rules/coding/configs/
├── .clangd          # CompilationDatabaseのみ
├── .clang-format    # フォーマット設定
└── .clang-tidy      # lint設定

vscode/xmake.lua
└── settings.json生成 # query-driver設定
```

**問題点:**
- `.clangd`とVSCode settings.jsonが異なる設定
- IDE以外（CLI clangd）では設定が不完全

### 5. embedded ruleの複雑性

**on_load関数が640行以上:**
- MCU設定
- ツールチェーン設定
- フラグ計算
- リンカスクリプト配置
- compile_commands.json監視

**問題点:**
- テスト困難
- 保守性が低い
- エラー処理が不十分

---

## 改善計画

### Phase 1: clangd設定の完全化

**目標:** `.clangd`ファイルだけで完全に動作する設定

1. `.clangd`テンプレートの拡充
   - query-driverの動的生成
   - ARM固有フラグの追加/削除

2. coding-rulesパッケージの改修
   - ツールチェーンパス検出ロジック追加
   - プロジェクト固有設定のマージ機能

3. VSCode rule との統合
   - settings.jsonからquery-driver設定を削除
   - `.clangd`への一元化

### Phase 2: MCUマッピングの自動化

**目標:** JSONデータベースから自動生成

1. mcu-database.jsonにdevice名フィールド追加
   ```json
   {
     "stm32f407vgt6": {
       "core": "cortex-m4f",
       "flash": "1M",
       "ram": "192K",
       "device": "STM32F407VG"  // 追加
     }
   }
   ```

2. launch.json生成ロジックの改修
   - JSONからdevice名を取得
   - フォールバック: MCU名からの推測

### Phase 3: リファクタリング

**目標:** embedded ruleの分割

1. 機能分割
   ```
   rules/embedded/
   ├── xmake.lua          # エントリポイント（軽量）
   ├── mcu.lua            # MCU設定
   ├── toolchain.lua      # ツールチェーン設定
   ├── flags.lua          # フラグ計算
   └── linker.lua         # リンカスクリプト
   ```

2. キャッシュ機構の導入
   - MCUデータのメモ化
   - ツールチェーンパスのキャッシュ

### Phase 4: GCC/Clang両対応の強化

**目標:** 明示的なツールチェーン切り替え

1. 設定オプションの追加
   ```lua
   set_values("embedded.toolchain", "gcc-arm")  -- or "clang-arm"
   ```

2. ツールチェーン固有設定の分離
   - GCC固有フラグ
   - Clang固有フラグ
   - 共通フラグ

---

## 検証方法

umiプロジェクトで以下を確認:

1. **clangd動作確認**
   ```bash
   # IntelliSenseエラーがないこと
   clangd --check=tests/test_kernel.cc
   ```

2. **clang-format動作確認**
   ```bash
   clang-format --dry-run tests/test_kernel.cc
   ```

3. **ビルド確認**
   ```bash
   xmake build test_kernel
   xmake build firmware  # ARM target
   ```

4. **VSCode確認**
   - C/C++拡張のIntelliSense
   - clangd拡張の動作
   - デバッグ設定の有効性

---

## 優先度

| 改善項目 | 優先度 | 効果 | 工数 |
|---------|--------|------|------|
| clangd設定完全化 | **高** | 開発体験向上 | 中 |
| query-driver動的生成 | **高** | 環境依存解消 | 中 |
| MCUマッピング自動化 | 中 | デバッグ改善 | 低 |
| embedded rule分割 | 低 | 保守性向上 | 高 |
| GCC/Clang切り替え | 中 | 柔軟性向上 | 中 |

まずPhase 1（clangd設定の完全化）から着手する。

---

## 新設計案: コマンドベースの設定管理

### 設計思想

1. **明示的なコマンド実行** - 設定ファイルは自動生成ではなく、ユーザーがコマンドで明示的に生成
2. **カスタマイズ可能** - デフォルト設定 + プロジェクト固有の上書き
3. **透明性** - 何が生成されるか、どこに配置されるかが明確
4. **選択的共有** - `.clangd`はgitignore、`.clang-tidy`はgit管理、など選択可能

### ファイル配置の整理

| ファイル | 配置場所 | 生成/共有 | 用途 |
|---------|---------|----------|------|
| `.clangd` | プロジェクトルート | 生成 (gitignore) | エディタ用clangd設定 |
| `.clang-tidy` | プロジェクトルート | 共有 (git管理) | コーディング規約 |
| `.clang-format` | プロジェクトルート | 共有 (git管理) | フォーマット設定 |

**理由:**
- `.clangd` - ローカル環境依存（query-driver、CompilationDatabase）
- `.clang-tidy` - コーディング規約はチーム共有すべき
- `.clang-format` - フォーマット設定もチーム共有すべき

### コマンド設計

```bash
# 設定ファイルを生成（初期化）
xmake coding init

# 個別生成
xmake coding init --clangd      # .clangdのみ
xmake coding init --clang-tidy  # .clang-tidyのみ
xmake coding init --clang-format # .clang-formatのみ

# 強制上書き（既存ファイルがあっても上書き）
xmake coding init --force

# 設定を表示
xmake coding show

# フォーマット実行
xmake coding format [files...]

# チェック実行（CIモード）
xmake coding check [files...]
```

### 実装方針

#### 1. `xmake coding` タスクの作成

```lua
-- rules/coding/xmake.lua に追加

task("coding")
    set_category("plugin")
    on_run(function ()
        import("core.base.option")
        import("core.base.global")

        local action = option.get("action") or "help"

        if action == "init" then
            _coding_init()
        elseif action == "show" then
            _coding_show()
        elseif action == "format" then
            _coding_format()
        elseif action == "check" then
            _coding_check()
        else
            _coding_help()
        end
    end)

    set_menu {
        usage = "xmake coding [action] [options]",
        description = "Manage coding style configuration",
        options = {
            {'a', "action", "kv", nil, "Action: init, show, format, check"},
            {nil, "clangd", "k", nil, "Generate .clangd only"},
            {nil, "clang-tidy", "k", nil, "Generate .clang-tidy only"},
            {nil, "clang-format", "k", nil, "Generate .clang-format only"},
            {'f', "force", "k", nil, "Force overwrite existing files"},
        }
    }
```

#### 2. 設定テンプレート

```
~/.xmake/rules/coding/
├── templates/
│   ├── clangd.yaml           # .clangd テンプレート
│   ├── clang-tidy.yaml       # .clang-tidy テンプレート
│   └── clang-format.yaml     # .clang-format テンプレート
└── configs/                   # 互換性のため残す
    ├── .clangd
    ├── .clang-tidy
    └── .clang-format
```

#### 3. プロジェクト固有設定のサポート

`xmake.lua` でカスタマイズ可能:

```lua
-- プロジェクトのxmake.lua
add_rules("coding.style")

-- カスタム設定（オプション）
set_values("coding.clangd.compilation_database", ".build")
set_values("coding.clangd.query_driver", "/usr/bin/arm-none-eabi-g++")
set_values("coding.clang_tidy.extra_checks", {"google-*"})
set_values("coding.clang_tidy.remove_checks", {"modernize-use-trailing-return-type"})
```

### 移行手順

1. **テンプレートファイルの作成**
   - `templates/clangd.yaml` - 動的生成用テンプレート
   - `templates/clang-tidy.yaml` - 静的テンプレート
   - `templates/clang-format.yaml` - 静的テンプレート

2. **`xmake coding` タスクの実装**
   - `init` - 設定ファイル生成
   - `show` - 現在の設定表示
   - `format` - フォーマット実行
   - `check` - チェック実行

3. **`coding.style` ruleの変更**
   - 自動生成を削除
   - プロジェクトの設定ファイルを参照するように変更

4. **`clangd.config` ruleの廃止**
   - `xmake coding init --clangd` に置き換え

5. **ドキュメント更新**
   - README.mdに使い方を記載
   - 移行ガイドを作成

### `xmake coding init` の動作詳細

```
$ xmake coding init

Coding Style Configuration
================================================================================
Generating configuration files...

  .clangd
    - CompilationDatabase: .build/
    - Query drivers: /Users/user/.xmake/packages/g/gcc-arm/14.2.0/bin/arm-none-eabi-g++
    - Status: Generated (gitignored)

  .clang-tidy
    - File already exists, skipping (use --force to overwrite)
    - Status: Existing (git managed)

  .clang-format
    - File already exists, skipping (use --force to overwrite)
    - Status: Existing (git managed)

================================================================================
Done. Run 'xmake coding show' to view current configuration.
```

### 利点

1. **明示的** - ユーザーが何を生成するか把握できる
2. **カスタマイズ可能** - プロジェクト固有の設定を追加できる
3. **選択的共有** - `.clangd`は生成、`.clang-tidy`は共有、と使い分け
4. **CI対応** - `xmake coding check`でCIでのチェックが可能
5. **IDE非依存** - VSCode以外でも使える

### 注意点

- 既存の`clangd.config` ruleとの互換性を維持
- `coding.style` ruleの自動フォーマット/チェックはオプションとして残す
- 移行ドキュメントを用意する
