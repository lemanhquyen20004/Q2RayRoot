#!/usr/bin/env bash
# Q2Ray Root ARM64 Magisk ZIP builder.
# This build runs on an Internet-connected Ubuntu runner, never during install.
set -euo pipefail
cd "$(dirname "$0")"
version=$(sed -n 's/^version=//p' module.prop | head -n1)
xray_version="${XRAY_VERSION:-v26.9.30}"
asset="Xray-android-arm64-v8a.zip"
download="https://github.com/XTLS/Xray-core/releases/download/${xray_version}/${asset}"
root=$(pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/module/bin" "$tmp/module/third_party" "$root/dist"
printf 'Downloading verified upstream release URL: %s\n' "$download"
curl --fail --location --show-error --silent --retry 3 --connect-timeout 20 --max-time 360 \
  "$download" -o "$tmp/upstream.zip"
unzip -tqq "$tmp/upstream.zip"
unzip -j -o "$tmp/upstream.zip" xray -d "$tmp/module/bin" >/dev/null
[ -s "$tmp/module/bin/xray" ] || { echo "Xray ARM64 binary missing" >&2; exit 1; }
# ELF e_machine must be AArch64, to prevent accidentally shipping desktop binaries.
readelf -h "$tmp/module/bin/xray" | grep -q 'Machine:.*AArch64' ||
  { echo 'Downloaded core is not ELF ARM64' >&2; exit 1; }
curl --fail --location --show-error --silent --retry 2 \
  "https://raw.githubusercontent.com/XTLS/Xray-core/main/LICENSE" \
  -o "$tmp/module/third_party/Xray-LICENSE"
# Hysteria2/TUIC and subscription nodes run on sing-box, while legacy JSON
# continues to run on Xray. Both binaries are included in the release.
singbox_version="${SINGBOX_VERSION:-v1.14.2}"
sb_name="sing-box-${singbox_version#v}-android-arm64"
sb_url="https://github.com/SagerNet/sing-box/releases/download/${singbox_version}/${sb_name}.tar.gz"
printf 'Downloading official sing-box ARM64 core: %s\n' "$sb_url"
curl --fail --location --show-error --silent --retry 3 --connect-timeout 20 --max-time 360 \
  "$sb_url" -o "$tmp/sing-box.tar.gz"
tar -tzf "$tmp/sing-box.tar.gz" >/dev/null
mkdir -p "$tmp/sb"
tar -xzf "$tmp/sing-box.tar.gz" -C "$tmp/sb"
sb_binary=$(find "$tmp/sb" -type f -name sing-box | head -n 1)
[ -n "$sb_binary" ] && [ -s "$sb_binary" ] || { echo "Missing sing-box ARM64 binary" >&2; exit 1; }
readelf -h "$sb_binary" | grep -q 'Machine:.*AArch64' ||
  { echo 'sing-box binary is not ELF ARM64' >&2; exit 1; }
cp "$sb_binary" "$tmp/module/bin/sing-box"
cp third_party/js-yaml-LICENSE third_party/sing-box-LICENSE "$tmp/module/third_party/"

for f in module.prop customize.sh service.sh action.sh uninstall.sh LICENSE NOTICE.md README.md README_vi.md CHANGELOG.md update.json; do
  cp "$f" "$tmp/module/$f"
done
cp -R scripts webroot config "$tmp/module/"
chmod 0755 "$tmp/module/bin/xray" "$tmp/module/customize.sh" "$tmp/module/service.sh" \
  "$tmp/module/action.sh" "$tmp/module/uninstall.sh" "$tmp/module/scripts/q2r.sh" \
  "$tmp/module/scripts/subscription.sh" "$tmp/module/bin/sing-box"
package="Q2RayRoot-${version}-arm64.zip"
(cd "$tmp/module" && zip -q -r "$root/dist/$package" .)
unzip -tqq "$root/dist/$package"
(cd "$root/dist" && sha256sum "$package" > "$package.sha256")
printf 'Ready: %s (SHA-256 included)\n' "$root/dist/$package"
