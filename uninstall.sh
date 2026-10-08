#!/system/bin/sh
MODDIR=${0%/*}
# Remove only Q2Ray Root routing and kill only Q2Ray Root's own Xray process.
[ -f "$MODDIR/scripts/q2r.sh" ] &&
  /system/bin/sh "$MODDIR/scripts/q2r.sh" stop >/dev/null 2>&1 || :
# User config is intentionally preserved under /data/adb/q2rayroot.
echo "Q2Ray Root removed. Saved config remains in /data/adb/q2rayroot."
