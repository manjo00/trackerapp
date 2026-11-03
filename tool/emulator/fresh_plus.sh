#!/usr/bin/env bash
# Tester chat: time the widget's "+" when no Uplan window exists yet (a fresh
# window and Flutter engine, app process alive). The "+" goes over the cable as
# the widget's own intent; nothing taps the launcher. The sheet is closed for
# real by tapping its dimmed area, and only after checking that Uplan's window
# is the one in front.
# Usage: fresh_plus.sh <serial> <runs> <out dir> [x y of a point on the dimmed area]
export MSYS_NO_PATHCONV=1
S=$1; N=$2; OUT=$3; SX=${4:-540}; SY=${5:-300}
P=com.lifetracker.life_tracker
PLUS="am start -a es.antonborri.home_widget.action.LAUNCH -d uplan://add_task -n $P/.MainActivity"
mkdir -p "$OUT"
front() { adb -s "$S" shell dumpsys window displays | tr -d '\r' | grep -m1 -o 'mCurrentFocus=[^ ]* [^ ]* [^ }]*' | awk '{print $3}'; }
shown() { adb -s "$S" shell dumpsys input_method | tr -d '\r' | grep -o "mInputShown=[a-z]*" | head -1 | cut -d= -f2; }
close_for_real() {
  case "$(front)" in
    $P/*) adb -s "$S" shell input tap "$SX" "$SY"; adb -s "$S" shell sleep 2.5 ;;
    *) echo "  (not closing: Uplan isn't in front)"; return 1 ;;
  esac
  case "$(front)" in $P/*) echo "  (the sheet is still in front)"; return 1 ;; esac
}
adb -s "$S" shell $PLUS > /dev/null 2>&1
adb -s "$S" shell sleep 3
for i in $(seq 1 "$N"); do
  close_for_real || exit 1
  adb -s "$S" logcat -c
  adb -s "$S" shell $PLUS > /dev/null 2>&1
  adb -s "$S" shell sleep 3.5
  k=$(shown)
  adb -s "$S" logcat -d -v threadtime > "$OUT/fresh_$i.log"
  L="$OUT/fresh_$i.log"
  echo "fresh_$i: keyboard=$k tap=$(grep -m1 'START u0.*add_task' "$L" | awk '{print $2}') displayed=$(grep -m1 'Displayed com.lifetracker' "$L" | grep -o '+[0-9a-z]*') first_ask=$(grep -m1 'ImeTracker: com.lifetracker.*onRequestShow' "$L" | awk '{print $2}') shown=$(grep -m1 'ImeTracker: .*onShown' "$L" | awk '{print $2}') early_ignored=$(grep -c 'Ignoring showSoftInput' "$L")"
done
close_for_real
