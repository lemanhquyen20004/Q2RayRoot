# Q2Ray Root

**Q2Ray Root** is an Android root-based transparent proxy module, maintained by **lemanhquyen20004**. It combines Xray-core and sing-box proxy engines, a responsive WebUI, and optional Wi-Fi hotspot proxy sharing in one project.

[Tiếng Việt](README_vi.md) · [Releases](https://github.com/lemanhquyen20004/Q2RayRoot/releases) · [Source code](https://github.com/lemanhquyen20004/Q2RayRoot)

> **Version v0.0.3 — technical preview.** This build has passed automated CI checks but has **not yet been confirmed working on Redmi Note 8T / MIUI 12.5.5 / Android 11**. Test on-device networking before relying on it.

## Features

- **Xray-core / sing-box:** transparent TCP/UDP proxy using TPROXY, with the engine chosen based on configuration.
- **Bilingual WebUI:** switch between **English** and **Tiếng Việt**.
- **Node and subscription import:** VLESS, Trojan, VMess, Shadowsocks, Hysteria/Hysteria2 and TUIC links; plain/Base64 subscriptions, Clash YAML, and supported sing-box outbound JSON.
- **Saved node list:** import multiple links, keep node credentials privately on the device, pick a node and generate sing-box JSON automatically.
- **Advanced configuration:** edit Xray or sing-box JSON and validate it against the selected engine.
- **Hotspot proxy sharing:** optional interception of traffic from a detected tethering interface.
- **Network recovery:** remove Q2Ray Root-owned routing rules if startup fails or Xray exits unexpectedly.
- **Updates:** check GitHub Releases from the WebUI; on Magisk, install a confirmed update after SHA-256 verification, or use the module's native **Update** button.

The module **does not turn on proxy interception automatically** during installation or after reboot. Hotspot proxying is off until enabled.

## Requirements

- Rooted Android using **Magisk, KernelSU, or APatch**.
- **ARM64** CPU (the current build target).
- A compatible module WebUI host. Some Magisk installations require KsuWebUIStandalone.
- A valid, reachable proxy server for proxied Internet traffic.

## Installation

1. Download **[Q2RayRoot-v0.0.3-arm64.zip](https://github.com/lemanhquyen20004/Q2RayRoot/releases/download/v0.0.3/Q2RayRoot-v0.0.3-arm64.zip)** from the official project release.
2. Install the ZIP in your root module manager and reboot.
3. Open Q2Ray Root's WebUI and select **English** or **Tiếng Việt**.
4. To import nodes, paste one or more URI links into **Nodes / Subscriptions → Import nodes**. To import an HTTPS sub URL, paste it into the **HTTPS subscription URL** field and select **Fetch / Refresh subscription**.
5. Choose a node from the list and press **Select & save node**. The module generates and validates a sing-box TPROXY configuration. Alternatively, use **Core configuration** for custom Xray JSON.
6. Start the selected core and verify Internet connectivity **on the phone first**.
7. Enable hotspot proxy sharing only if needed; then check connectivity on a tethered device.

**Do not install the GitHub-generated “Source code” ZIP:** it does not bundle the ARM64 Xray executable.

## Supported imports and limitations

**Node links:** `vless://`, `trojan://`, `vmess://`, `ss://`, `hysteria://`, `hy2://`, `hysteria2://`, `tuic://` (common parameters only).

**Subscriptions:** HTTPS URLs returning plain URI lists, Base64-encoded URI lists, Clash YAML with a `proxies:` collection, or sing-box JSON with supported outbound items. You may also paste subscription text directly. Unsupported items are skipped with an error count. The import is capped at 1 MiB per subscription. Some advanced transports or plugin-dependent nodes are not supported.

**Engine selection:** Nodes imported from subscriptions use sing-box; custom Xray JSON remains available. Stop the proxy before switching nodes or engines. A successful format check does not guarantee that a remote server is reachable.

**Saved private data:** `/data/adb/q2rayroot/nodes.json` and `subscription.url`; keep server passwords and tokenized subscription URLs private. You can refresh the saved subscription manually; there is no automatic background subscription update.

## Updating Q2Ray Root

### From Magisk

When a newer release has a higher `versionCode`, open **Magisk → Modules → Q2Ray Root → Update**, then reboot after installation.

### From the WebUI

Open **Updates → Check for updates**. If a newer release is found, choose **Download & install** and confirm. The installer downloads the module ZIP from this project's GitHub Releases, verifies its SHA-256 checksum, and installs through the Magisk command-line interface. After the successful installation message, **reboot to apply the update**.

For **KernelSU or APatch**, use the module manager's own update workflow. Updates are **not installed without your confirmation**. Temporary ZIP files are deleted after the installer finishes.

Developers should increment both `version` and `versionCode` in `module.prop` and `update.json` for new releases. GitHub Actions runs checks, builds the ARM64 ZIP, and publishes a prerelease with its checksum.

## Network safety

Avoid running another root-level transparent proxy at the same time, as its firewall or policy-routing rules may conflict with Q2Ray Root.

If your connection fails, use **Stop / Direct** in the WebUI. If recovery is unsuccessful, disable Q2Ray Root in the root module manager and reboot. The configuration is stored at `/data/adb/q2rayroot/config.json`.

| File | Purpose |
| --- | --- |
| `/data/adb/q2rayroot/run.log` | Proxy engine and routing events |
| `/data/adb/q2rayroot/update.status` | Update progress |
| `/data/adb/q2rayroot/update.log` | Update diagnostics |

**Privacy:** Keep VLESS UUIDs, subscription tokens, and private server credentials out of public GitHub commits and issue reports.

## Project structure

| Path | Description |
| --- | --- |
| `scripts/q2r.sh` | Xray lifecycle, firewall policy, hotspot detection, watchdog |
| `scripts/update.sh` | Version check and verified Magisk update workflow |
| `webroot/index.html` | English/Vietnamese WebUI |
| `config/default.json` | Initial direct-only Xray configuration |
| `build.sh` | ARM64 release packaging |
| `.github/workflows/build.yml` | Automated validation and prerelease publishing |

## Core and WebUI files

The module bundles two official Android ARM64 cores and a vendored MIT-licensed YAML parser:
- Xray-core (manual JSON configurations)
- sing-box 1.14.x (common node links, subscriptions and Hysteria2)
- js-yaml 4.1.0 (offline Clash YAML parsing)

## Roadmap

Future versions may include Mihomo, scheduled subscription refresh, advanced subscription management, per-device hotspot limits, and gaming profiles. **These are not included in v0.0.3.**

## Copyright and license

Copyright © 2026 **lemanhquyen20004** for the original Q2Ray Root project source and interface.

Q2Ray Root is distributed under **GPL-3.0-or-later**. External components, including **Xray-core (MPL-2.0), sing-box (GPL-3.0-or-later), and js-yaml (MIT)**, retain their respective copyrights and licenses. See [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md).

*Q2Ray Root is an independently maintained project. Compatibility, performance and hotspot behavior depend on the Android device and kernel.*
