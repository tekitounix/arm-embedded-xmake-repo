# パッケージ更新ガイド

## 概要

このドキュメントでは、ARM ツールチェーンパッケージの更新方法を説明します。

---

## 1. 新バージョンの確認

### clang-arm (Arm Toolchain for Embedded)

**リリースページ**: https://github.com/arm/arm-toolchain/releases

確認項目:
- バージョン番号（例: `21.1.1`）
- リリースタグ形式（例: `release-21.1.1-ATfE`）
- ダウンロードファイル名形式（例: `ATfE-21.1.1-Darwin-universal.dmg`）

> **注意**: バージョン 20.x 以降、パッケージ名が `LLVM-ET-Arm-*` から `ATfE-*` に変更されました。

### gcc-arm (GNU Arm Embedded Toolchain)

**リリースページ**: https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads

確認項目:
- バージョン番号（例: `15.2.rel1`）
- ダウンロードURL形式

---

## 2. チェックサムの取得

### clang-arm

```bash
# macOS (Darwin universal)
curl -sL "https://github.com/arm/arm-toolchain/releases/download/release-21.1.1-ATfE/ATfE-21.1.1-Darwin-universal.dmg.sha256" | awk '{print $1}'

# Linux x86_64
curl -sL "https://github.com/arm/arm-toolchain/releases/download/release-21.1.1-ATfE/ATfE-21.1.1-Linux-x86_64.tar.xz.sha256" | awk '{print $1}'

# Linux AArch64
curl -sL "https://github.com/arm/arm-toolchain/releases/download/release-21.1.1-ATfE/ATfE-21.1.1-Linux-AArch64.tar.xz.sha256" | awk '{print $1}'
```

### gcc-arm

```bash
# macOS x86_64
curl -sL "https://developer.arm.com/-/media/files/downloads/gnu/15.2.rel1/binrel/arm-gnu-toolchain-15.2.rel1-darwin-x86_64-arm-none-eabi.tar.xz" | shasum -a 256

# Linux x86_64
curl -sL "https://developer.arm.com/-/media/files/downloads/gnu/15.2.rel1/binrel/arm-gnu-toolchain-15.2.rel1-x86_64-arm-none-eabi.tar.xz" | shasum -a 256

# Linux AArch64
curl -sL "https://developer.arm.com/-/media/files/downloads/gnu/15.2.rel1/binrel/arm-gnu-toolchain-15.2.rel1-aarch64-arm-none-eabi.tar.xz" | shasum -a 256
```

> **注意**: gcc-arm のURLは `/files/` (小文字) です。大文字の `/Files/` は動作しません。

---

## 3. パッケージファイルの更新

### packages/c/clang-arm/xmake.lua

```lua
-- 1. add_versions にバージョンを追加
add_versions("21.1.1", "dummy")  -- sha256 は後で追加

-- 2. on_install 内の add_versions_map テーブルを更新
add_versions_map = {
    ["21.1.1"] = {
        macosx = "SHA256_HASH_HERE",
        linux_x86_64 = "SHA256_HASH_HERE",
        linux_aarch64 = "SHA256_HASH_HERE",
    },
    -- 既存バージョンは残す
}

-- 3. URL形式が変わった場合は get_download_url 関数も更新
```

### packages/g/gcc-arm/xmake.lua

```lua
-- 1. add_versions にバージョンを追加
add_versions("15.2.rel1", "dummy")

-- 2. on_install 内の sha256_map と urls_map テーブルを更新
```

### packages/a/arm-embedded/xmake.lua

```lua
-- on_load 内のデフォルトバージョンを更新（必要な場合）
local version = package:config("gcc_version") or "15.2.rel1"
local clang_version = package:config("clang_version") or "21.1.1"
```

---

## 4. ローカルでのテスト

```bash
# パッケージキャッシュをクリア
xmake g -c

# リポジトリを再読み込み
xmake repo -u

# パッケージ情報を確認
xmake require --info clang-arm
xmake require --info gcc-arm

# テストビルド
cd /path/to/your/project
xmake f -c  # 設定をリセット
xmake build your_target
```

---

## 5. 変更のコミットとプッシュ

```bash
cd .refs/arm-embedded-xmake-repo
git add packages/
git commit -m "chore: update clang-arm to 21.1.1, gcc-arm to 15.2.rel1"
git push origin main
```

---

## 使用者側のパッケージ更新方法

プロジェクトで最新のツールチェーンを使用するには：

### 1. リポジトリの更新

```bash
# xmake リポジトリを更新
xmake repo -u

# パッケージキャッシュをクリア（必要な場合）
xmake g -c
```

### 2. パッケージの再インストール

```bash
# 設定をリセット
xmake f -c

# または特定のツールチェーンバージョンを指定
xmake f --toolchain=clang-arm
```

### 3. バージョンの確認

```bash
# インストール済みパッケージを確認
xmake require --list

# 特定パッケージの情報
xmake require --info clang-arm
xmake require --info gcc-arm

# ビルド時に表示されるツールチェーンバージョンを確認
xmake build your_target
```

### 4. 特定バージョンの固定（xmake.lua）

```lua
-- 特定バージョンを使用したい場合
add_requires("clang-arm 21.1.1")
add_requires("gcc-arm 15.2.rel1")

-- または arm-embedded で指定
add_requires("arm-embedded", {configs = {
    clang_version = "21.1.1",
    gcc_version = "15.2.rel1"
}})
```

---

## トラブルシューティング

### パッケージが見つからない

```bash
# リポジトリURLを確認
xmake repo -l

# 強制更新
xmake repo -u --force
```

### ダウンロードエラー

1. URLが正しいか確認（大文字/小文字の違いに注意）
2. sha256 チェックサムが正しいか確認
3. ネットワーク接続を確認

### 古いバージョンが使われる

```bash
# パッケージキャッシュをクリア
xmake g -c

# グローバルパッケージディレクトリを確認
ls ~/.xmake/packages/c/clang-arm/
ls ~/.xmake/packages/g/gcc-arm/
```

---

## 参考リンク

- [Arm Toolchain for Embedded Releases](https://github.com/arm/arm-toolchain/releases)
- [GNU Arm Embedded Toolchain Downloads](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)
- [xmake package management](https://xmake.io/#/package/remote_package)
