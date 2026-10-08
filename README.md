# Q2Ray Root

**Q2Ray Root** is an independent, root-based Android transparent-proxy module developed for `lemanhquyen20004`. The first technical-preview version, **v0.0.1**, focuses on the **Xray-core TPROXY engine** and a Vietnamese/English WebUI.

> **Technical preview — not verified on a real Redmi Note 8T yet.** Do not install this next to an active Box for Root / Magic V2Ray transparent-proxy service. Test the direct connection and recovery procedures before relying on tethering. A configured, reachable proxy node is required for proxied Internet access.

**Key principles:** fail-open on core failure; no automatic interception immediately after installation; only module-owned firewall chains and policy rules; optional AP interface-specific tethering; no global IPv6 blocking, default-route replacement or Android DNS resets.

## Quick start / Hướng dẫn nhanh

1. Download the `Q2RayRoot-v0.0.1-arm64.zip` artifact built by GitHub Actions (or the corresponding release ZIP when published). **Source code ZIP does not include the Xray binary.**
2. Install the module through Magisk / KernelSU / APatch and reboot. Only ARM64 Android is supported for the first build.
3. Open the module's WebUI (Magisk may require a compatible WebUI host such as KsuWebUIStandalone), select **Tiếng Việt** or **English**.
4. Paste a supported VLESS link or an Xray JSON configuration, save it, then press **Start**.
5. Switch **Share proxy via Hotspot** on only after normal on-device traffic works. Hotspot discovery never treats a normal Wi-Fi uplink as an AP.

1. Cài file ZIP ARM64 được build từ GitHub Actions/Release bằng Magisk, sau đó khởi động lại máy.
2. Mở WebUI và chọn tiếng Việt hoặc tiếng Anh.
3. Nhập liên kết VLESS hoặc cấu hình JSON Xray, lưu và bấm **Bật**.
4. Chỉ bật **Chia sẻ Proxy qua Hotspot** sau khi mạng trên điện thoại đã hoạt động tốt.

**Emergency / Khôi phục mạng:** Disable the module in Magisk and reboot if necessary. The controller's **Stop / Direct** action only removes Q2Ray Root's own rules. Logs: `/data/adb/q2rayroot/run.log`.

## Architecture / Kiến trúc

- `scripts/q2r.sh`: root daemon controls, Xray lifecycle, independent TPROXY rules, AP detection, cleanup and watchdog.
- `webroot/index.html`: responsive WebUI with two languages, VLESS URI import, raw JSON editing, status and logs.
- `config/default.json`: minimal direct-only configuration for safe engine testing. Replace the default with a real proxy to route through a server.
- `build.sh`: packages ARM64 Magisk ZIP using an official Xray binary downloaded during the release build, not at device startup.

**Planned, not yet delivered:** Mihomo, sing-box, advanced subscription management, per-device traffic quotas, game profiles. These will only be added after testing networking on real devices.

## Copyright and acknowledgments / Bản quyền và ghi nhận

Copyright © 2026 **lemanhquyen20004** for original Q2Ray Root project materials. See [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md).

The architecture was researched with reference to [Box for Root](https://github.com/taamarin/box_for_magisk) and [Magic V2Ray](https://github.com/vincentng295/Magic_V2Ray); their source code and copyrights remain with their respective owners. The separately distributed [Xray-core](https://github.com/XTLS/Xray-core) binary remains subject to its own MPL-2.0 license and other applicable notices. **Owning this repository does not transfer third-party copyrights.**

---
**Status:** early source release; automated shell/JavaScript tests can pass without proving support for a specific Android kernel.
