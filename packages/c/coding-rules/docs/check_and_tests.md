# チェックとテストガイド

C++プロジェクトのコード品質を保証するための自動チェックとテスト手法を説明します。

## 必要なツール

```bash
# macOS
brew install clang-format clang-tidy

# Ubuntu/Debian
apt install clang-format clang-tidy
```

## ビルド時の自動チェック

### coding.rulesルール

xmakeビルドシステムに統合された`coding.rules`により、ビルド時に自動的に以下が実行されます：

1. **clang-format**によるコードの自動フォーマット
2. **clang-tidy**による命名規則の自動修正
3. ソースファイル（.cc）とヘッダーファイル（.hh）の両方を処理

```lua
-- xmake.luaでの設定
add_rules("coding.rules")
```

### CI/CD用チェックモード

CIパイプラインでは自動修正を無効にしてチェックのみを行います：

```lua
-- CI用の設定
add_rules("coding.rules.ci")
```

このモードでは、スタイル違反があるとビルドが失敗します。

## Pre-commitフック

Gitコミット前に自動チェックと修正を行うには：

```bash
# Unix系
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/sh
# ステージされたC++ファイルを取得
files=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(cc|hh)$')
if [ -n "$files" ]; then
    echo "Running code formatting and naming convention checks..."
    
    # フォーマット修正
    clang-format -i $files
    
    # 命名規則修正
    for file in $files; do
        clang-tidy "$file" --config-file=coding_rules/.clang-tidy --fix --quiet -- -x c++ -std=c++23 -Iinclude 2>/dev/null
    done
    
    # 修正後のファイルを再ステージ
    git add $files
    
    # 最終チェック（修正できなかった問題がないか確認）
    clang-format --dry-run --Werror $files || exit 1
fi
EOF
chmod +x .git/hooks/pre-commit

# Windows
# .git/hooks/pre-commit.batファイルを作成
```

## 手動チェック

### フォーマットチェック

```bash
# フォーマットをチェック（変更なし）
clang-format --dry-run --Werror include/**/*.{cc,hh}

# フォーマットを適用
clang-format -i include/**/*.{cc,hh}
```

### 命名規則チェック

```bash
# 命名規則をチェック
clang-tidy include/**/*.{cc,hh} --config-file=coding_rules/.clang-tidy

# 命名規則を自動修正
clang-tidy include/**/*.{cc,hh} --config-file=coding_rules/.clang-tidy --fix
```

## 静的解析とサニタイザ

### 開発段階別適用ガイド

| 開発段階 | 静的解析 | Sanitizers | インクルード最適化 | 適用環境 |
|----------|----------|------------|-------------------|----------|
| **ライブラリ開発** | ✅ 必須 | ✅ 完全適用 | ✅ 推奨 | ホスト環境 |
| **ベアメタル組み込み** | ✅ 必須 | ❌ 不適用 | ✅ 推奨 | ホストテストのみ |
| **MPU無しカーネル** | ✅ 必須 | ⚠️ 限定的 | ✅ 推奨 | データ構造テスト |
| **MPU有りカーネル** | ✅ 必須 | ✅ 条件付き | ✅ 推奨 | 仮想メモリ後 |

### clang-tidy（必須・最優先）

Clang Static Analyzerの全機能＋追加チェック＋命名規則

```bash
# 推奨設定（Static Analyzer込み）
clang-tidy src/*.cc --checks='-*,\
  clang-analyzer-*,\
  bugprone-*,\
  readability-identifier-naming,\
  modernize-use-nullptr,\
  performance-*'
```

**注**: 
- Clang Static Analyzer単体は不要（clang-tidyに含まれる）
- cppcheckも基本的に不要（誤検出が多く投資対効果が低い）

### ランタイムSanitizers（ホスト環境）

**AddressSanitizer（ASan）・UndefinedBehaviorSanitizer（UBSan）**
- **コスト**: 無料（コンパイラ標準搭載）  
- **対応**: Clang 3.1+, GCC 4.8+, MSVC 2019+  
- **適用対象**: ライブラリ、カーネルデータ構造テスト

```lua
-- xmake.lua - 統合設定
option("static_analysis")
    set_default(false)
    set_description("静的解析を有効化")

option("host_test")
    set_default(false) 
    set_description("ホスト環境でのサニタイザテスト")

target("my_library")
    if has_config("host_test") then
        add_cxflags("-fsanitize=address,undefined", {tools = {"clang", "gcc"}})
        add_ldflags("-fsanitize=address,undefined", {tools = {"clang", "gcc"}})
    end
```

### インクルード最適化

**misc-include-cleaner（clang-tidy）**
- 未使用インクルードの削除
- 前方宣言で十分な箇所の検出
- ビルド時間の大幅短縮（30-50%）

```bash
clang-tidy src/*.cc --checks='-*,misc-include-cleaner' --fix
```

## トラブルシューティング

### 大量の警告が表示される場合

システムヘッダーからの警告は自動的に抑制されますが、もし表示される場合は、最新バージョンのclang-tidyを使用しているか確認してください。

### 命名規則の自動修正が機能しない場合

1. clang-tidyがインストールされているか確認
2. `.clang-tidy`ファイルが正しく配置されているか確認
3. C++23サポートがあるか確認（C++20でも動作します）

### サニタイザでメモリリークが検出される場合

正常な終了処理でもリークとして検出される場合があります：

```cpp
// 抑制リストの例
// lsan_suppressions.txt
leak:libsystem_malloc.dylib
leak:_NSConcreteStackBlock
```

## ベストプラクティス

1. **開発時**: ASan/UBSanを常時有効化
2. **CI**: 静的解析とサニタイザテストを必須化
3. **リリース前**: 全サニタイザでの完全テスト実施
4. **定期的**: インクルード最適化を実行

## 参考資料

- [AddressSanitizer](https://clang.llvm.org/docs/AddressSanitizer.html)
- [UndefinedBehaviorSanitizer](https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html)
- [Clang-Tidy](https://clang.llvm.org/extra/clang-tidy/)