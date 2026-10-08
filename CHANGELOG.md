# Changelog / Nhật ký

## v0.0.3 — Multi-protocol nodes and subscriptions (technical preview)

- New node list with VLESS, Trojan, VMess, Shadowsocks, Hysteria/Hysteria2, TUIC URI import.
- HTTPS subscription downloader: plain URI, Base64 URI, Clash YAML and sing-box outbound JSON.
- Bundled sing-box Android ARM64 alongside Xray; node/subscription configs run on sing-box.
- Switch Xray/sing-box engine in WebUI and validate configuration with selected core.
- Fix Xray JSON save failure by using `config.candidate.json` extension.
- Preserve existing Xray configurations and private saved nodes across upgrades.
- Additional parser tests and sing-box 1.14.2 format validation in CI.

**Scope:** technical preview; actual Redmi Note 8T + MIUI 12.5.5 performance has not yet been device-tested.


## v0.0.2 — GitHub updater (technical preview)

- Nút kiểm tra cập nhật và tải/cài trong WebUI hai ngôn ngữ.
- Magisk Update sử dụng `update.json`, phiên bản tăng lên `v0.0.2`.
- Tự đóng gói ZIP ARM64, tạo SHA-256 và phát hành GitHub prerelease sau khi CI thành công.
- Kiểm tra checksum trước khi cài qua Magisk CLI; dọn ZIP tạm, không tự động reboot.
- KernelSU/APatch: sử dụng nút Update trong trình quản lý module.


## v0.0.1 — technical preview (source)

- Independent Q2Ray Root module, ARM64-first.
- Root Xray TPROXY controller and fail-open cleanup.
- Optional Hotspot interception on detected AP interfaces only.
- Responsive WebUI in Vietnamese and English.
- VLESS TLS / REALITY import and Xray JSON validation.
- No automatic proxy start after install or reboot.
- GitHub Actions source tests and binary-bearing ZIP build.

**Limitations:** Device-level testing not yet completed; only Xray is wired up. Magisk Update works only after the corresponding GitHub release ZIP actually exists.
