#!/system/bin/sh
MODDIR=${0%/*}
CTL="$MODDIR/scripts/q2r.sh"
state=$(/system/bin/sh "$CTL" status)
case "$state" in
  running)
    echo "Q2Ray Root: restoring DIRECT..."
    exec /system/bin/sh "$CTL" stop ;;
  missing-core)
    echo "Q2Ray Root: Xray binary is missing. Install a release ZIP."
    exit 1 ;;
  *)
    echo "Q2Ray Root: starting Xray..."
    exec /system/bin/sh "$CTL" start ;;
esac
