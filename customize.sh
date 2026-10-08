#!/system/bin/sh
# Q2Ray Root installation: no traffic interception, no core downloads.
SKIPUNZIP=0
SKIPMOUNT=false
PROPFILE=true
POSTFSDATA=false
LATESTARTSERVICE=true

[ "$BOOTMODE" = true ] || abort "! Install through Magisk/KernelSU/APatch Manager."
[ "$ARCH" = arm64 ] || abort "! First build supports ARM64 only."
ui_print "- Installing Q2Ray Root v0.0.1 (ARM64)"
ui_print "- All network interception remains OFF after installation."
DATA=/data/adb/q2rayroot
mkdir -p "$DATA"
chmod 700 "$DATA"
if [ ! -s "$DATA/config.json" ]; then
  cp "$MODPATH/config/default.json" "$DATA/config.json" ||
    abort "! Could not initialize default Xray config"
  chmod 600 "$DATA/config.json"
  ui_print "- Added DIRECT-only example config; import a node to proxy traffic."
else
  ui_print "- Preserved existing Xray config."
fi
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/scripts/q2r.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
if [ -f "$MODPATH/bin/xray" ]; then
  set_perm "$MODPATH/bin/xray" 0 0 0755
  ui_print "- Bundled Xray ARM64 core detected."
else
  ui_print "! Xray core missing: use the built release ZIP, not GitHub source ZIP."
fi
ui_print "- WebUI language: Tiếng Việt / English"
ui_print "- No change to Android DNS, 4G, Wi-Fi, IPv6 or routing at installation."
