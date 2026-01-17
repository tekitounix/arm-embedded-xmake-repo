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
