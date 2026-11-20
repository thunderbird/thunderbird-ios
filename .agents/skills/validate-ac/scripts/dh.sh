#!/bin/bash
# Safe Device Hub driver. Acts only if Device Hub is the front-most app and the topmost window at the target point.
#   dh.sh shot FILE      capture the Device Hub window region only
#   dh.sh click X Y      real click at a point in window coordinates (points)
#   dh.sh type TEXT      keystrokes to the focused field
# Env: DH_TOOLS (helper dir, default $TMPDIR/dh-tools), DH_DEVICE (substring of the window title, e.g. "iPhone 17").
TOOLS="${DH_TOOLS:-${TMPDIR:-/tmp}/dh-tools}"
[ -x "$TOOLS/hit" ] && [ -x "$TOOLS/tap" ] || { echo "ABORT: run scripts/setup.sh first"; exit 1; }
WIN="window 1"
[ -n "$DH_DEVICE" ] && WIN="(first window whose name contains \"$DH_DEVICE\")"

geom() { osascript -e "tell application \"System Events\" to tell process \"DeviceHub\" to get {position, size} of $WIN" | tr -d ' '; }
front() { osascript -e 'tell application "System Events" to get name of first process whose frontmost is true'; }

osascript -e 'tell application "DeviceHub" to activate'
sleep 0.4
[ "$(front)" = "DeviceHub" ] || { echo "ABORT: frontmost is $(front)"; exit 1; }
IFS=, read WX WY WW WH <<< "$(geom)"
[ -n "$WW" ] || { echo "ABORT: cannot read Device Hub window (Accessibility granted?)"; exit 1; }

case "$1" in
  shot)
    screencapture -x -R"$WX,$WY,$WW,$WH" "$2" && echo "shot $2 (window ${WW}x${WH} pt)";;
  click)
    X=$((WX + $2)); Y=$((WY + $3))
    TOP=$("$TOOLS/hit" "$X" "$Y" | head -1)
    case "$TOP" in
      "Device Hub"*) ;;
      *) echo "ABORT: topmost at ($X,$Y) is ${TOP:-nothing}"; exit 1;;
    esac
    "$TOOLS/tap" "$X" "$Y" && echo "clicked window($2,$3) -> screen($X,$Y)";;
  type)
    osascript -e "tell application \"System Events\" to keystroke \"$2\"" && echo "typed";;
  *)
    echo "usage: dh.sh shot FILE | click X Y | type TEXT"; exit 2;;
esac
