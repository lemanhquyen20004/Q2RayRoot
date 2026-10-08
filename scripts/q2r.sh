#!/system/bin/sh
# Q2Ray Root: original module controller.
# Copyright (C) 2026 lemanhquyen20004
# GPL-3.0-or-later; see LICENSE.
# Safe by default: never modify Android's global default route, IPv6,
# netd NAT, rp_filter or forwarding sysctls.
MODDIR=${0%/scripts/*}
DATA=/data/adb/q2rayroot
XRAY_BIN="$MODDIR/bin/xray"
SINGBOX_BIN="$MODDIR/bin/sing-box"
ENGINE_FILE="$DATA/engine.txt"
BIN="$XRAY_BIN"
CONF="$DATA/config.json"
ENGINE=xray
load_engine() {
  ENGINE=$(cat "$ENGINE_FILE" 2>/dev/null)
  case "$ENGINE" in
    sing-box) BIN="$SINGBOX_BIN"; CONF="$DATA/singbox.json" ;;
    *) ENGINE=xray; BIN="$XRAY_BIN"; CONF="$DATA/config.json" ;;
  esac
}
is_our_pid() {
  pp=$1
  case "$pp" in ''|*[!0-9]*) return 1 ;; esac
  [ -r "/proc/$pp/cmdline" ] || return 1
  cmdline=$(tr '\000' ' ' < "/proc/$pp/cmdline")
  case "$cmdline" in
    *"$XRAY_BIN"*|*"$SINGBOX_BIN"*) return 0 ;;
    *) return 1 ;;
  esac
}
LOG="$DATA/run.log"
PIDFILE="$DATA/xray.pid"
ACTIVE="$DATA/active"
AP_WANT="$DATA/hotspot.enabled"
AP_CURRENT="$DATA/hotspot.current"
LOCK="$DATA/control.lock"
IP=/system/bin/ip
IPT=/system/bin/iptables
MARK=0x04000000/0x04000000
TABLE=29691
PREF=1081
OUT=Q2R_OUT
PRE=Q2R_PRE
AP=Q2R_AP
PORT=9898

mkdir -p "$DATA"
chmod 700 "$DATA" 2>/dev/null
log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG"; }
alive() {
  [ -s "$PIDFILE" ] || return 1
  p=$(cat "$PIDFILE" 2>/dev/null)
  case "$p" in ''|*[!0-9]*) return 1 ;; esac
  kill -0 "$p" 2>/dev/null || return 1
  # Avoid treating a recycled PID as our own daemon.
  [ -r "/proc/$p/cmdline" ] || return 1
  is_our_pid "$p" || return 1
}
lock_enter() {
  count=0
  while ! mkdir "$LOCK" 2>/dev/null; do
    count=$((count+1))
    [ "$count" -lt 5 ] || { echo "BUSY"; return 1; }
    sleep 1
  done
  printf '%s\n' "$$" > "$LOCK/pid"
  trap 'rm -f "$LOCK/pid"; rmdir "$LOCK" 2>/dev/null' EXIT HUP INT TERM
}
lock_exit() {
  rm -f "$LOCK/pid"
  rmdir "$LOCK" 2>/dev/null || :
  trap - EXIT HUP INT TERM
}
ipt() { "$IPT" -w 5 "$@"; }
remove_jump() {
  table=$1; parent=$2; chain=$3
  n=0
  while [ "$n" -lt 4 ] && ipt -t "$table" -D "$parent" -j "$chain" >/dev/null 2>&1; do
    n=$((n+1))
  done
}
cleanup_rules() {
  # Touch only this module's own chains, policy mark and table.
  remove_jump mangle OUTPUT "$OUT"
  remove_jump mangle PREROUTING "$PRE"
  for c in "$AP" "$PRE" "$OUT"; do
    ipt -t mangle -F "$c" >/dev/null 2>&1 || :
    ipt -t mangle -X "$c" >/dev/null 2>&1 || :
  done
  "$IP" -4 rule del pref "$PREF" fwmark "$MARK" lookup "$TABLE" >/dev/null 2>&1 || :
  "$IP" -4 route del local default dev lo table "$TABLE" >/dev/null 2>&1 || :
  rm -f "$AP_CURRENT"
}
stop_impl() {
  # Restore direct networking first, THEN stop the core. Never flush Android chains.
  cleanup_rules
  rm -f "$ACTIVE"
  if [ -s "$PIDFILE" ]; then
    p=$(cat "$PIDFILE" 2>/dev/null)
    case "$p" in ''|*[!0-9]*) : ;; *)
      if is_our_pid "$p"; then
        kill "$p" 2>/dev/null || :
      fi ;;
    esac
  fi
  rm -f "$PIDFILE"
  log "stopped; DIRECT restored"
}
# Only recognize AP-like interfaces with an IPv4 private address.
# wlan0 can be a hotspot on MIUI, but is accepted ONLY for known AP gateway
# addresses and when the Internet uplink is NOT wlan0.
detect_ap() {
  found=$("$IP" -o -4 addr show 2>/dev/null | awk '
    {
      n=$2; sub(/@.*/, "", n);
      if (n ~ /^(ap[0-9]+|swlan[0-9]+|softap[0-9]+|wlan[1-9][0-9]*|rndis[0-9]+|tether[0-9]+|ncm[0-9]+)$/ &&
          $4 ~ /^(192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.|10\.)/) {
        print n; exit
      }
    }')
  if [ -n "$found" ]; then printf '%s\n' "$found"; return 0; fi
  gw=$("$IP" -o -4 addr show dev wlan0 2>/dev/null | awk '$4 ~ /^(192\.168\.43\.1|192\.168\.232\.1|192\.168\.42\.1)\// {print "wlan0"; exit}')
  [ -n "$gw" ] || return 1
  uplink=$("$IP" route get 1.1.1.1 2>/dev/null)
  case "$uplink" in *' dev wlan0 '*) return 1 ;; esac
  printf '%s\n' "$gw"
}
apply_hotspot() {
  # Chain exists only after the core and policy route are installed.
  ipt -t mangle -n -L "$AP" >/dev/null 2>&1 || return 0
  wanted=""
  if [ -f "$AP_WANT" ]; then wanted=$(detect_ap 2>/dev/null) || wanted=""; fi
  old=$(cat "$AP_CURRENT" 2>/dev/null)
  [ "$wanted" = "$old" ] && return 0
  ipt -t mangle -F "$AP" || return 1
  rm -f "$AP_CURRENT"
  if [ -n "$wanted" ]; then
    ipt -t mangle -A "$AP" -i "$wanted" -p tcp -j TPROXY --on-port "$PORT" --tproxy-mark "$MARK" || return 1
    ipt -t mangle -A "$AP" -i "$wanted" -p udp -j TPROXY --on-port "$PORT" --tproxy-mark "$MARK" || return 1
    printf '%s\n' "$wanted" > "$AP_CURRENT"
    log "Hotspot proxy enabled on $wanted"
  else
    log "Hotspot proxy waiting for AP or disabled"
  fi
}
add_bypass() {
  chain=$1
  for cidr in 0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 \
              169.254.0.0/16 172.16.0.0/12 192.168.0.0/16 \
              198.18.0.0/15 224.0.0.0/4 240.0.0.0/4; do
    ipt -t mangle -A "$chain" -d "$cidr" -j RETURN || return 1
  done
}
conflict_check() {
  if ipt -t mangle -C OUTPUT -j BOX_LOCAL >/dev/null 2>&1 ||
     ipt -t mangle -C OUTPUT -j XRAY_MARK >/dev/null 2>&1; then
    echo "CONFLICT: another rooted transparent proxy is active"
    log "refused start: existing Box/Magic netfilter interception"
    return 1
  fi
}
apply_rules() {
  # Build inactive private chains; attach them only after every step succeeds.
  cleanup_rules
  "$IP" -4 route replace local default dev lo table "$TABLE" || return 1
  "$IP" -4 rule add pref "$PREF" fwmark "$MARK" lookup "$TABLE" || return 1
  ipt -t mangle -N "$OUT" || return 1
  ipt -t mangle -N "$PRE" || return 1
  ipt -t mangle -N "$AP" || return 1
  ipt -t mangle -A "$OUT" -m owner --uid-owner 0 -j RETURN || return 1
  add_bypass "$OUT" || return 1
  ipt -t mangle -A "$OUT" -p tcp -j MARK --set-xmark "$MARK" || return 1
  ipt -t mangle -A "$OUT" -p udp -j MARK --set-xmark "$MARK" || return 1
  add_bypass "$PRE" || return 1
  ipt -t mangle -A "$PRE" -i lo -p tcp -j TPROXY --on-port "$PORT" --tproxy-mark "$MARK" || return 1
  ipt -t mangle -A "$PRE" -i lo -p udp -j TPROXY --on-port "$PORT" --tproxy-mark "$MARK" || return 1
  ipt -t mangle -A "$PRE" -j "$AP" || return 1
  apply_hotspot || return 1
  ipt -t mangle -I PREROUTING 1 -j "$PRE" || return 1
  ipt -t mangle -I OUTPUT 1 -j "$OUT" || return 1
}
valid_config() {
  path=$1
  check_engine=$2
  case "$check_engine" in
    sing-box) check_bin="$SINGBOX_BIN" ;;
    xray) check_bin="$XRAY_BIN" ;;
    *) echo "BAD_ENGINE"; return 1 ;;
  esac
  [ -x "$check_bin" ] || { echo "NO_CORE: $check_engine ARM64 binary missing"; return 1; }
  [ -s "$path" ] || { echo "NO_CONFIG: Save $check_engine JSON first"; return 1; }
  if [ "$check_engine" = sing-box ]; then
    "$check_bin" check -c "$path" >> "$LOG" 2>&1 || {
      echo "INVALID_CONFIG: sing-box validation failed (see run.log)"; return 1;
    }
  else
    "$check_bin" run -test -c "$path" >> "$LOG" 2>&1 || {
      echo "INVALID_CONFIG: Xray validation failed (see run.log)"; return 1;
    }
  fi
}
start_impl() {
  if alive && [ -f "$ACTIVE" ]; then echo "ALREADY_RUNNING"; return 0; fi
  stop_impl
  load_engine
  conflict_check || return 1
  valid_config "$CONF" "$ENGINE" || return 1
  log "launching $ENGINE..."
  "$BIN" run -c "$CONF" >> "$LOG" 2>&1 </dev/null &
  p=$!
  printf '%s\n' "$p" > "$PIDFILE"
  sleep 2
  if ! alive; then
    log "Xray exited before network activation"
    stop_impl
    echo "CORE_EXITED"
    return 1
  fi
  if ! apply_rules; then
    log "iptables/policy routing failed; restoring DIRECT"
    stop_impl
    echo "RULES_FAILED"
    return 1
  fi
  touch "$ACTIVE"
  log "$ENGINE TPROXY enabled"
  echo "RUNNING"
}
case "${1:-}" in
  status)
    load_engine
    if alive && [ -f "$ACTIVE" ]; then echo running
    elif [ ! -x "$BIN" ]; then echo missing-core
    else echo stopped; fi
    ;;
  engine)
    load_engine
    echo "$ENGINE"
    ;;
  validate)
    # A fixed candidate file and allowlisted core only. No arbitrary paths.
    case "$2" in xray|sing-box) valid_config "$DATA/config.candidate.json" "$2" ;;
      *) echo "BAD_ENGINE"; exit 2 ;;
    esac
    ;;
  start)
    lock_enter || exit 1
    start_impl
    rc=$?
    lock_exit
    exit "$rc"
    ;;
  stop)
    lock_enter || exit 1
    stop_impl
    echo DIRECT
    lock_exit
    ;;
  restart)
    lock_enter || exit 1
    stop_impl
    start_impl
    rc=$?
    lock_exit
    exit "$rc"
    ;;
  hotspot)
    case "${2:-}" in
      on|off)
        lock_enter || exit 1
        if [ "$2" = on ]; then touch "$AP_WANT"; else rm -f "$AP_WANT"; fi
        if [ -f "$ACTIVE" ]; then apply_hotspot; fi
        echo "HOTSPOT_${2}"
        lock_exit
        ;;
      status)
        if [ -f "$AP_WANT" ]; then
          printf 'on %s\n' "$(cat "$AP_CURRENT" 2>/dev/null)"
        else echo off; fi ;;
      *) echo "usage: hotspot on|off|status"; exit 2 ;;
    esac
    ;;
  monitor)
    # Started at service boot, no implicit proxy auto-start.
    while true; do
      sleep 6
      [ -f "$ACTIVE" ] || continue
      if ! alive; then
        if lock_enter; then
          if ! alive && [ -f "$ACTIVE" ]; then
            log "watchdog: Xray exited; fail-open DIRECT"
            stop_impl
          fi
          lock_exit
        fi
      elif [ -f "$AP_WANT" ]; then
        if lock_enter; then apply_hotspot >/dev/null 2>&1 || :; lock_exit; fi
      fi
    done
    ;;
  *)
    echo "usage: q2r.sh {status|engine|validate xray|sing-box|start|stop|restart|hotspot on|off|status|monitor}" >&2
    exit 2
    ;;
esac
