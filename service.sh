#!/system/bin/sh
# Start only the fail-open monitor at boot; do not auto-enable proxy.
MODDIR=${0%/*}
(
  sleep 5
  exec /system/bin/sh "$MODDIR/scripts/q2r.sh" monitor
) >/dev/null 2>&1 &
