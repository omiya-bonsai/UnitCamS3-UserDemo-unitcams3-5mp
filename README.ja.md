# UnitCamS3-5MP Home Assistant ローカルカメラ化

English version:

[README.md](README.md)

---

このプロジェクトは、M5Stack公式の UnitCamS3-5MP UserDemo firmware を改造し、
Home Assistant から利用可能なローカルLANカメラとして動作させるものです。

元の firmware は:

- APモード中心
- EZDataクラウド投稿中心

の構成になっていました。

本改造では:

- STAモード常用
- ローカルWebサーバ化
- Home Assistant Generic Camera対応

を目的として変更しています。

---

# 主な変更点

## poster task 無効化

元の firmware は:

```text
WiFi接続
→ EZDataへ画像POST
```

という流れでした。

これを:

```text
WiFi接続
→ ローカルWebサーバ起動
```

へ変更しています。

---

# 利用可能URL

```text
http://192.168.3.62/
http://192.168.3.62/api/v1/capture
http://192.168.3.62/api/v1/stream
```

---

# Home Assistant 設定例

```yaml
camera:
  - platform: generic
    name: unitcams3_5mp
    still_image_url: "http://192.168.3.62/api/v1/capture"
    stream_source: "http://192.168.3.62/api/v1/stream"
```

---

# ビルド方法

## ESP-IDF

```zsh
cd platforms/unitcam_s3_5mp

idf.py build

idf.py -p /dev/cu.usbmodem201301 flash monitor
```

---

# 主な解析ポイント

今回解析・修正した主な箇所:

- AssetPool.bin
- server_ap.cpp
- server_poster.cpp
- api_camera.cpp
- HAL camera init flow
- STA/AP startup sequence

---

# ディレクトリ構成

```text
docs/          ドキュメント
platforms/     ESP-IDF platform
app/           アプリ本体
dependencies/  外部依存
```

---

# 詳細ドキュメント

詳細な作業ログ:

```text
docs/unitcams3_ha_sta_integration_handoff_2026_05_06.md
```

---

# 注意事項

これは M5Stack公式 firmware をベースにした改造版です。

M5Stack公式更新との互換性は保証されません。

---

# License

LICENSE を参照してください。
