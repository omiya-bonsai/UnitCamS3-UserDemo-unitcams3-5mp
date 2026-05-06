# UnitCamS3-5MP + Home Assistant ローカルSTA化 改造記録

作成日: 2026-05-06

---

# プロジェクトパス

```text
/Users/tomato/Documents/projects/UnitCamS3-UserDemo-unitcams3-5mp
```

---

# 概要

M5Stack UnitCamS3-5MP の公式 UserDemo firmware を解析し、
クラウド依存の Poster モードから、Home Assistant 向けのローカル LAN カメラとして利用できる構成へ変更した。

最終的に以下を達成した。

- UnitCamS3-5MP を Wi‑Fi STA モードで常時接続
- APモード依存を除去
- ローカル HTTP camera API を維持
- Home Assistant Generic Camera から閲覧可能
- `/api/v1/capture`
- `/api/v1/stream`
- ESP-IDF build 成功
- desktop build 成功
- AssetPool.bin の生成と flash 成功

---

# 開発環境

- macOS
- Apple Silicon Mac Studio
- ESP-IDF v5.1.4
- Arduino IDE
- M5Stack ESP32 core 3.3.7
- Home Assistant OS

---

# 元の firmware の設計思想

M5公式 firmware は基本的に:

```text
UnitCam → M5クラウド(EZData)へ定期画像投稿
```

を前提としていた。

つまり:

- AP mode
- Poster mode
- EZData upload

中心設計だった。

Home Assistant のような:

- ローカルLAN camera
- MJPEG stream
- Generic Camera
- RTSP代替

用途は主目的ではなかった。

---

# desktop build の解析

## 最初の問題

SDL 系 compile error:

```text
unknown type name 'SDL_KeyCode'
```

など。

## 原因

SDL2 が見つかっていなかった。

## 対応

```zsh
brew install sdl2
```

さらに:

```zsh
cmake ../../platforms/desktop -DCMAKE_PREFIX_PATH=/opt/homebrew
```

を使用。

---

# AssetPool.bin 問題

desktop build 後:

```text
AssetPool.bin
```

が必要であることを確認。

ESP32 firmware はこの binary asset を flash partition へ書き込む構成だった。

確認ログ:

```text
output asset pool to: AssetPool.bin
load asset pool from: AssetPool.bin
```

flash:

```text
Written contents of file '../desktop/build/desktop/AssetPool.bin' at offset 0x610000
```

---

# CameraWebServer 検証

Arduino IDE 側でも camera 動作検証を実施。

## 問題

M5Stack UnitCamS3 variant が ESP32-CAM standard pin と異なる。

通常 CameraWebServer は動作しない。

## pin 定義調査

以下で pin 定義を解析:

```zsh
grep -R "CAMERA_PIN_" -n platforms/unitcam_s3_5mp
```

## 判明した pin

```cpp
#define CAMERA_PIN_VSYNC 42
#define CAMERA_PIN_HREF 18
#define CAMERA_PIN_PCLK 12
#define CAMERA_PIN_XCLK 11

#define CAMERA_PIN_SIOD 17
#define CAMERA_PIN_SIOC 41

#define CAMERA_PIN_D0 6
#define CAMERA_PIN_D1 15
#define CAMERA_PIN_D2 16
#define CAMERA_PIN_D3 7
#define CAMERA_PIN_D4 5
#define CAMERA_PIN_D5 10
#define CAMERA_PIN_D6 4
#define CAMERA_PIN_D7 13
```

これを CameraWebServer 用 pin 定義へ移植。

---

# CameraWebServer 動作確認

最終的に:

```text
http://192.168.3.62/
http://192.168.3.62:81/stream
http://192.168.3.62/capture
```

でアクセス可能になった。

ただし:

```text
Warmup failed
```

は残った。

しかし stream/capture は実用上動作。

---

# ESP-IDF firmware 側の本命改造

本命は:

```text
M5 official UserDemo firmware を
ローカル LAN camera server 化すること
```

だった。

---

# API 調査

以下を確認:

```zsh
grep -R "api/v1/capture\|api/v1/stream" -n \
platforms/unitcam_s3_5mp/main/hal_unitcam_s3_5mp/servers/apis
```

結果:

```cpp
server.on("/api/v1/capture", HTTP_GET, sendJpg);
server.on("/api/v1/stream", HTTP_GET, streamJpg);
```

つまり camera API 自体は既に存在していた。

問題は:

```text
AP mode 前提
```

だった。

---

# AP mode 問題

起動時:

```text
start ap server
ap ip: 192.168.4.1
```

になっていた。

Home Assistant 用途では不要。

---

# startPosterServer() 問題

解析対象:

```text
server_poster.cpp
```

ここで:

- AP wait mode
- Poster upload
- EZData upload

を管理していた。

特に問題だったのは:

```cpp
startApServer();
```

が複数箇所に存在したこと。

途中だけ local web server 化しても、
最後で再び AP mode に戻していた。

---

# startLocalWebServer() 追加

server_ap.cpp へ追加。

```cpp
void HAL_UnitCamS3_5MP::startLocalWebServer()
```

役割:

- AP開始しない
- softAP使わない
- STA接続済み前提
- AsyncWebServer 起動のみ
- camera APIs を expose

重要:

```cpp
WiFi.softAP(...)
```

を呼ばない。

---

# 最終修正

## server_poster.cpp

以下を:

```cpp
startApServer();
```

↓

```cpp
startLocalWebServer();
```

へ変更。

さらに AP wait block を無効化。

```cpp
if (HAL::GetSystemConfig().waitApFirst == "yes")
```

を丸ごとコメントアウト。

---

# 最終成功ログ

```text
connect ok, ip: 192.168.3.62
start local web server instead of poster task
start local web server
start local web server done
```

重要:

以下が消えた。

```text
start ap server
ap ip: 192.168.4.1
```

これで:

```text
STA専用 local LAN camera
```

になった。

---

# Home Assistant 連携

configuration.yaml:

```yaml
camera:
  - platform: generic
    name: unitcams3_5mp
    still_image_url: "http://192.168.3.62/api/v1/capture"
    stream_source: "http://192.168.3.62/api/v1/stream"
```

Home Assistant 再起動後:

```text
camera.unitcams3_5mp
```

として利用可能。

---

# 推奨ディレクトリ構成

```text
/Users/tomato/Documents/projects/
├── gemma-mqtt
├── m5papers3-news-server
├── m5papers3-news-system
├── m5papers3-weather-learning-system
├── UnitCamS3-UserDemo-unitcams3-5mp
└── wc-schedule
```

Downloads に置き続けない。

---

# Git 化推奨

```zsh
cd /Users/tomato/Documents/projects/UnitCamS3-UserDemo-unitcams3-5mp

git init
git add .
git commit -m "UnitCamS3 STA local web server for Home Assistant"
```

---

# build ディレクトリ

生成物は容量を消費する。

例:

```text
platforms/desktop/build
platforms/unitcam_s3_5mp/build
```

ただし、動作安定確認前は削除しない。

---

# 今回の本質

これは単なる「サンプルを動かした」ではない。

実際には:

```text
M5 official cloud-oriented firmware
↓
HA local LAN camera firmware
```

へ思想転換した。

つまり:

- firmware解析
- build系解析
- Asset partition解析
- ESP-IDF runtime解析
- AP/STA architecture変更

まで到達している。

---

# 今後やりたくなる可能性

- MQTT publish
- motion detection
- snapshot保存
- NAS連携
- HA automation
- RTSP
- HLS
- ESPHome再挑戦
- low-latency MJPEG tuning
- dual stream
- HA Frigate integration

---

# 現状の最重要URL

```text
http://192.168.3.62/
http://192.168.3.62/api/v1/capture
http://192.168.3.62/api/v1/stream
```

---

# 結論

今回の成果は:

```text
「M5公式 firmware を Home Assistant 向けローカルカメラ化した」
```

ことにある。

これは単なる設定変更ではなく、
firmware architecture の方向性変更に近い。
