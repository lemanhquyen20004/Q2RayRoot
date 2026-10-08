# Q2Ray Root

**Q2Ray Root** is an Android root-based transparent proxy module, maintained by **lemanhquyen20004**. It combines an Xray-based proxy engine, a responsive WebUI, and optional Wi-Fi hotspot proxy sharing in one project.

[Tiếng Việt](README_vi.md) · [Releases](https://github.com/lemanhquyen20004/Q2RayRoot/releases) · [Source code](https://github.com/lemanhquyen20004/Q2RayRoot)

> **Version v0.0.2 — technical preview.** This build has passed automated CI checks but has **not yet been confirmed working on Redmi Note 8T / MIUI 12.5.5 / Android 11**. Test on-device networking before relying on it.

## Features

- **Xray-core:** transparent TCP/UDP proxy using TPROXY.
- **Bilingual WebUI:** switch between **English** and **Tiếng Việt**.
- **Configuration management:** import supported VLESS links (TLS or REALITY), edit Xray JSON, and validate configuration.
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

1. Download **[Q2RayRoot-v0.0.2-arm64.zip](https://github.com/lemanhquyen20004/Q2RayRoot/releases/download/v0.0.2/Q2RayRoot-v0.0.2-arm64.zip)** from the official project release.
2. Install the ZIP in your root module manager and reboot.
3. Open Q2Ray Root's WebUI and select **English** or **Tiếng Việt**.
4. Import a supported VLESS URI or save a valid Xray JSON configuration.
5. Start Xray and verify Internet connectivity **on the phone first**.
6. Enable hotspot proxy sharing only if you need it, then check connectivity on a tethered device.

**Do not install the GitHub-generated “Source code” ZIP:** it does not bundle the ARM64 Xray executable.

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

## Roadmap

Future versions may include Mihomo, sing-box, advanced subscription management, per-device hotspot limits, and gaming profiles. **These are not included in v0.0.2.**

## Copyright and license

Copyright © 2026 **lemanhquyen20004** for the original Q2Ray Root project source and interface.

Q2Ray Root is distributed under **GPL-3.0-or-later**. External components, including **Xray-core (MPL-2.0)**, retain their respective copyrights and licenses. See [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md).

*Q2Ray Root is an independently maintained project. Compatibility, performance and hotspot behavior depend on the Android device and kernel.*
