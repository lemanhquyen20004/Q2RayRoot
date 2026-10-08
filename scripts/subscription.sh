#!/system/bin/sh
# Q2Ray Root subscription downloader; HTTPS-only, capped at 1 MiB.
# Copyright (C) 2026 lemanhquyen20004; GPL-3.0-or-later.
DATA=/data/adb/q2rayroot
URL_FILE="$DATA/subscription.url"
DEST="$DATA/subscription.raw"
TEMP="$DATA/subscription.tmp"
LOG="$DATA/subscription.log"
CHUNK=16384
MAXSIZE=1048576
umask 077
mkdir -p "$DATA"
chmod 700 "$DATA" 2>/dev/null || :
error() { echo "ERROR: $1"; exit 1; }
case "$1" in
  fetch)
    [ -s "$URL_FILE" ] || error "Enter a subscription URL"
    [ "$(wc -c < "$URL_FILE")" -le 2048 ] || error "Subscription URL too long"
    url=$(cat "$URL_FILE")
    # Only HTTPS URLs with normal domain names; prohibit whitespace and shell controls.
    printf '%s\n' "$url" | grep -Eq '^https://[a-zA-Z0-9][a-zA-Z0-9.-]*(:[0-9]{1,5})?(/[^[:space:]]*)?$' ||
      error "Only HTTPS subscription URLs with a hostname are supported"
    host=$(printf '%s\n' "$url" | sed -E 's|^https://([^/:]+).*|\1|' | tr '[:upper:]' '[:lower:]')
    case "$host" in
      localhost|*.localhost|127.*|10.*|192.168.*|169.254.*|0.*|::1)
        error "Local subscription hosts are not accepted" ;;
    esac
    rm -f "$TEMP"
    if command -v curl >/dev/null 2>&1; then
      curl --fail --location --silent --show-error --connect-timeout 12 \
        --max-time 60 --retry 1 --proto '=https' --proto-redir '=https' \
        --max-filesize "$MAXSIZE" -o "$TEMP" "$url" >> "$LOG" 2>&1 ||
          error "Could not fetch subscription (HTTPS/network error)"
    else
      fetched=false
      for b in /data/adb/magisk/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox; do
        [ -x "$b" ] || continue
        if "$b" wget -q -T 45 -O "$TEMP" "$url" >> "$LOG" 2>&1; then
          fetched=true; break
        fi
      done
      if [ "$fetched" = false ]; then
        if command -v wget >/dev/null 2>&1; then
          wget -q -T 45 -O "$TEMP" "$url" >> "$LOG" 2>&1 ||
            error "No working HTTPS downloader available"
        else
          error "No working HTTPS downloader available"
        fi
      fi
    fi
    [ -s "$TEMP" ] || error "Subscription response empty"
    [ "$(wc -c < "$TEMP")" -le "$MAXSIZE" ] || {
      rm -f "$TEMP"; error "Subscription exceeds 1 MiB limit";
    }
    mv -f "$TEMP" "$DEST" || error "Unable to save subscription"
    chmod 600 "$DEST"
    echo "FETCHED $(wc -c < "$DEST" | tr -d ' ')"
    ;;
  chunks)
    [ -s "$DEST" ] || error "Fetch a subscription first"
    size=$(wc -c < "$DEST" | tr -d ' ')
    [ "$size" -le "$MAXSIZE" ] || error "Subscription exceeds 1 MiB"
    echo $(( (size+CHUNK-1)/CHUNK ))
    ;;
  chunk)
    n=$2
    case "$n" in ''|*[!0-9]*) error "Invalid chunk index" ;; esac
    [ "$n" -ge 0 ] && [ "$n" -le 63 ] || error "Chunk index out of range"
    [ -s "$DEST" ] || error "Fetch a subscription first"
    dd if="$DEST" bs="$CHUNK" skip="$n" count=1 2>/dev/null | base64 | tr -d '\n'
    echo
    ;;
  *)
    echo 'usage: subscription.sh {fetch|chunks|chunk N}' >&2
    exit 2
    ;;
esac
