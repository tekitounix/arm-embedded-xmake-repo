# Flash Plugin Database

`xmake flash` (Phase 4a 以降は probe-rs CLI 経由) が読み込むターゲット
情報データベース。pyOCD パック概念は撤去済み — probe-rs は CMSIS-Pack
互換のチップ定義を CLI に同梱しているため、追加インストール不要。

## flash-targets.json

以下の情報を定義する:

### 1. ビルトインターゲット (`FLASH_TARGETS.builtin`)

probe-rs registry に標準で含まれるターゲットで、何の準備もなく書き込み可能。

例:
- `stm32f051` → `probe_rs_chip = "STM32F051R8"`
- `stm32f103rc` → `probe_rs_chip = "STM32F103RC"`
- `cortex_m` (generic Cortex-M、`probe_rs_chip = null`)

### 2. 旧パック必要ターゲット (`FLASH_TARGETS.pack_required`)

pyOCD 時代に「パックが必要」だった STM32F4 / H5 / G4 / H7 / RP2350 等。
probe-rs ではいずれも追加インストール不要だが、key 名 (`stm32f407vg`
など) を呼び出し側が引き続き使えるよう group 自体は残す。

各エントリのフィールド:
- `vendor`: メーカー名
- `part_number`: 型番
- `series` / `families`: 表示用カテゴリ
- `probe_rs_chip`: `probe-rs chip list` に存在する識別子 (必須)

### 3. ターゲットエイリアス (`FLASH_TARGETS.target_aliases`)

旧 pyOCD 命名の short 名を canonical 名にマップする後方互換用テーブル:
- `stm32h533re` → `stm32h533retx`
- `stm32f407vg` → `stm32f407vgtx`
- `stm32g431kb` → `stm32g431kbtx`

エイリアス解決後、`probe_rs_chip` 解決へ進む。

## 動作

`plugins/flash/xmake.lua` がフラッシュ前にこの JSON を読み、ターゲット
キーに対応する `probe_rs_chip` を取り出して `probe-rs download --chip`
に渡す。`probe_rs_chip` が未設定の場合はエラーで停止する。

## 新しいターゲットの追加

1. `probe-rs chip list | grep -i <識別子>` で probe-rs 側の chip 名を確認。
2. `pack_required.targets` (legacy key) もしくは `builtin.targets` に
   エントリを追加。最小フィールドは `vendor` + `part_number` + `series`
   + `probe_rs_chip`。
3. 旧名と新名で表記揺れする場合 (`stm32g474re` vs `stm32g474retx` 等) は
   `target_aliases.aliases` にエイリアスを追加。

例:

```json
"stm32g474re": {
  "vendor": "STMicroelectronics",
  "part_number": "STM32G474RE",
  "series": "STM32G4",
  "families": ["STM32G4 Series", "STM32G474"],
  "probe_rs_chip": "STM32G474RE"
}
```
