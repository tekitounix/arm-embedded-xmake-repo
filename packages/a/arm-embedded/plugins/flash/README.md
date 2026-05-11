# Flash Plugin for ARM Embedded Targets

`xmake flash` を probe-rs CLI 経由で実行し、ARM Cortex-M / Cortex-A /
RISC-V / Xtensa MCU にファームウェアを書き込むプラグイン (Phase 4a of
probe-rs migration、旧 PyOCD パスは置換済み)。

## 使用方法

```bash
xmake flash [options] [target]
```

## オプション

| オプション | 短縮 | 説明 | 例 |
|-----------|------|------|-----|
| `--target` | `-t` | フラッシュ対象ターゲットを指定 | `xmake flash -t stm32f4_kernel` |
| `--device` | `-d` | ターゲットデバイスを上書き | `xmake flash -d stm32f407vg` |
| `--frequency` | `-f` | SWD クロック周波数 (kHz 整数または `4M`) | `xmake flash -f 4000` |
| `--erase` | `-e` | `--allow-erase-all` を probe-rs download に渡す | `xmake flash -e` |
| `--reset` | `-r` | プログラミング後にリセット (デフォルト動作) | `xmake flash -r` |
| `--no-reset` | `-n` | リセットを抑止 (halted 状態で完了) | `xmake flash -n` |
| `--probe` | `-p` | デバッグプローブを VID:PID[:SERIAL] で指定 | `xmake flash --probe 0483:374b:0669FF37` |
| `--protocol` | | `swd` (デフォルト) または `jtag` | `xmake flash --protocol jtag` |

## 主な機能

- **自動ターゲット選択**: 未指定時はデフォルトターゲットを使用
- **probe-rs chip 名解決**: `flash-targets.json` の `probe_rs_chip` フィールドから自動。
- **マルチプローブ対応**: 1 本だけ繋がっていれば probe-rs が auto-select、複数の場合は `--probe` で指定。
- **再ビルド検出**: ELF が古いと自動で `xmake build` を実行。

## マルチプローブ環境

複数のデバッグプローブが接続されている場合:

1. `probe-rs list` で UID を確認
2. `xmake flash --probe <VID:PID:SERIAL>` で対象を明示

## トラブルシューティング

| 問題 | 解決策 |
|------|--------|
| デバッグプローブが見つからない | `probe-rs list` でも表示されないか確認、USB を差し直す。 |
| `chip … not in registry` | `probe-rs chip list` に対応 chip 名があるか確認し、`flash-targets.json` の `probe_rs_chip` を修正。 |
| ターゲットが応答しない | `xmake flash -r` で再リセット、もしくは MCP `reset` を使用。 |
| フラッシュ検証失敗 | `xmake flash -e` で chip mass-erase してから再書き込み。 |
| 複数プローブで誤選択 | `xmake flash --probe <VID:PID:SERIAL>` で指定。 |
| probe-rs 未インストール | Nix dev shell に入る (`nix develop` / `direnv allow`) か `cargo install probe-rs-tools` を実行。 |
