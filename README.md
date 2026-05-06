# UnitCamS3-5MP Home Assistant Local Camera Mod

Japanese version:

[README.ja.md](README.ja.md)

---

This project modifies the official M5Stack UnitCamS3-5MP UserDemo firmware to work as a local LAN camera for Home Assistant.

The original firmware mainly focuses on AP mode and EZData cloud posting.
This modification converts it into a local STA-mode camera server.

---

## Features

- Wi-Fi STA mode
- Local Web UI
- Home Assistant Generic Camera support
- JPEG snapshot endpoint
- MJPEG stream endpoint
- No cloud dependency
- ESP-IDF based build

---

## URLs

```text
http://192.168.3.62/
http://192.168.3.62/api/v1/capture
http://192.168.3.62/api/v1/stream
```

---

## Home Assistant Example

```yaml
camera:
  - platform: generic
    name: unitcams3_5mp
    still_image_url: "http://192.168.3.62/api/v1/capture"
    stream_source: "http://192.168.3.62/api/v1/stream"
```

---

## Build

```zsh
cd platforms/unitcam_s3_5mp

idf.py build

idf.py -p /dev/cu.usbmodem201301 flash monitor
```

---

## Notes

This repository includes modifications for:

- local web server startup
- STA mode operation
- disabling poster task flow
- Home Assistant integration

---

## Documentation

Detailed development notes:

```text
docs/unitcams3_ha_sta_integration_handoff_2026_05_06.md
```

---

## License

See LICENSE.
