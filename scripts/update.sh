#!/system/bin/sh
# Q2Ray Root v0.0.2 — verified release updater.
# Copyright (C) 2026 lemanhquyen20004; GPL-3.0-or-later.
# Never installs without a user-initiated "begin" command.
# Only downloads known HTTPS GitHub release URLs. Never eval remote input.
MODDIR=$(dirname "$(dirname "$0")")
DATA=/data/adb/q2rayroot
META_URL=https://raw.githubusercontent.com/lemanhquyen20004/Q2RayRoot/main/update.json
REPO_RELEASE=https://github.com/lemanhquyen20004/Q2RayRoot/releases/download
STATUS=$DATA/update.status
LOCK=/dev/q2rayroot-update.lock
LOG=$DATA/update.log
mkdir -p "$DATA"
chmod 700 "$DATA" 2>/dev/null || :
umask 077
FETCH_MAX=240
FETCH_RETRIES=2

log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG"; }
state() { printf '%s\n' "$*" > "$STATUS"; log "$*"; }
fetch_file() {
    u=$1
    target=$2
    if command -v curl >/dev/null 2>&1; then
        curl --fail --location --silent --show-error --connect-timeout 12 --max-time "$FETCH_MAX" \
            --retry "$FETCH_RETRIES" -o "$target" "$u" >> "$LOG" 2>&1
        return $?
    fi
    for b in /data/adb/magisk/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox; do
        [ -x "$b" ] || continue
        "$b" wget -q -T 15 -O "$target" "$u" >> "$LOG" 2>&1 && return 0
    done
    if command -v wget >/dev/null 2>&1; then
        wget -q -T 15 -O "$target" "$u" >> "$LOG" 2>&1 && return 0
    fi
    log "Download failed, or neither curl nor HTTPS-capable BusyBox wget is available."
    return 1
}
read_meta() {
    file=$1
    VERSION=$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$file" | head -n 1)
    CODE=$(sed -n 's/.*"versionCode"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$file" | head -n 1)
    printf '%s\n' "$VERSION" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$' || return 1
    case "$CODE" in ''|*[!0-9]*) return 1 ;; esac
    [ "$CODE" -gt 0 ] 2>/dev/null || return 1
    [ "$CODE" -le 2147483647 ] 2>/dev/null || return 1
    return 0
}
current_code() {
    CURRENT=$(sed -n 's/^versionCode=//p' "$MODDIR/module.prop" | head -n 1)
    case "$CURRENT" in ''|*[!0-9]*) CURRENT=0 ;; esac
}
check_info() {
    dest=$1
    fetch_file "$META_URL" "$dest" || { echo NO_INTERNET; return 1; }
    read_meta "$dest" || { echo INVALID_METADATA; return 1; }
    current_code
    if [ "$CODE" -gt "$CURRENT" ]; then
        printf 'UPDATE %s %s\n' "$CODE" "$VERSION"
    else
        printf 'CURRENT %s %s\n' "$CURRENT" "$VERSION"
    fi
}
run_install() {
    trap 'rm -f "$DATA/update-payload.zip" "$DATA/update-payload.sha256" "$DATA/update-meta.json"; rmdir "$LOCK" 2>/dev/null || :' EXIT
    state CHECKING
    fetch_file "$META_URL" "$DATA/update-meta.json" || {
        state "FAILED: NO_INTERNET"; return 1;
    }
    read_meta "$DATA/update-meta.json" || {
        state "FAILED: INVALID_METADATA"; return 1;
    }
    current_code
    if [ "$CODE" -le "$CURRENT" ]; then state NO_UPDATE; return 0; fi
    file="Q2RayRoot-$VERSION-arm64.zip"
    url="$REPO_RELEASE/$VERSION/$file"
    state DOWNLOADING
    fetch_file "$url" "$DATA/update-payload.zip" || {
        state "FAILED: DOWNLOAD_ZIP"; return 1;
    }
    state VERIFYING
    fetch_file "$url.sha256" "$DATA/update-payload.sha256" || {
        state "FAILED: NO_CHECKSUM"; return 1;
    }
    expected=$(awk 'NR==1 {print $1}' "$DATA/update-payload.sha256")
    actual=$(/system/bin/sha256sum "$DATA/update-payload.zip" 2>/dev/null | awk 'NR==1 {print $1}')
    if [ -z "$actual" ]; then
        for b in /data/adb/magisk/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox; do
            [ -x "$b" ] || continue
            actual=$("$b" sha256sum "$DATA/update-payload.zip" 2>/dev/null | awk 'NR==1 {print $1}')
            [ -n "$actual" ] && break
        done
    fi
    if ! printf '%s\n' "$expected" | grep -Eq '^[a-fA-F0-9]{64}$' ||
       [ -z "$actual" ] || [ "$actual" != "$expected" ]; then
        state "FAILED: SHA256_MISMATCH"
        return 1
    fi
    if ! unzip -t "$DATA/update-payload.zip" >> "$LOG" 2>&1; then
        state "FAILED: INVALID_ZIP"
        return 1
    fi
    if ! unzip -p "$DATA/update-payload.zip" module.prop 2>/dev/null |
        grep -qx 'id=q2rayroot'; then
        state "FAILED: INVALID_MODULE"
        return 1
    fi
    # Only Magisk CLI installation is supported by WebUI in this revision.
    # KernelSU/APatch users can use the native manager's Update action.
    if ! command -v magisk >/dev/null 2>&1; then
        state "FAILED: NO_MAGISK_CLI"
        return 1
    fi
    state INSTALLING
    if magisk --install-module "$DATA/update-payload.zip" >> "$LOG" 2>&1; then
        state READY_REBOOT
        return 0
    fi
    state "FAILED: INSTALL_COMMAND"
    return 1
}
case "$1" in
    check)
        FETCH_MAX=15
        FETCH_RETRIES=0
        testfile="$DATA/update-check.$$.json"
        trap 'rm -f "$testfile"' EXIT
        check_info "$testfile"
        ;;
    begin)
        if ! mkdir "$LOCK" 2>/dev/null; then
            echo BUSY
            exit 1
        fi
        state QUEUED
        ( /system/bin/sh "$0" _worker </dev/null >/dev/null 2>&1 ) &
        echo STARTED
        ;;
    _worker)
        run_install
        ;;
    status)
        if [ -f "$STATUS" ]; then cat "$STATUS"; else echo IDLE; fi
        ;;
    *)
        echo 'usage: update.sh {check|begin|status}' >&2
        exit 2
        ;;
esac
