#!/usr/bin/env bash
# Tester chat: tap the Uplan widget's "+" for real (a tap on the launcher, like
# a finger) in each situation and report whether the keyboard came up.
# Usage: phone_plus.sh <serial> <x> <y> <rounds> <out dir> [dead]
#   warm  = Uplan's own screen open, sent away with Home, then "+"
#   cold  = the sheet just closed with Back (activity gone, app alive), then "+"
#   again = that sheet left open, sent away with Home, then "+"
#   dead  = (only with the 6th argument) Uplan stopped, then "+"
# Nothing is typed or sent: every sheet is closed with Back. Ends with Uplan
# started normally, so a stopped app re-books its reminders.
export MSYS_NO_PATHCONV=1
S=$1; X=$2; Y=$3; N=$4; OUT=$5; DEAD=${6:-}
P=com.lifetracker.life_tracker
mkdir -p "$OUT"
shown() { adb -s "$S" shell dumpsys input_method | tr -d '\r' | grep -o "mInputShown=[a-z]*" | head -1 | cut -d= -f2; }
plus() {
  adb -s "$S" logcat -c
  adb -s "$S" shell input tap "$X" "$Y"
  adb -s "$S" shell sleep 3
  local k; k=$(shown)
  adb -s "$S" logcat -d -v threadtime > "$OUT/$1.log"
  local start shownat
  start=$(grep -m1 'START u0.*add_task' "$OUT/$1.log" | awk '{print $2}')
  shownat=$(grep -m1 'ImeTracker: com.lifetracker.*onShown' "$OUT/$1.log" | awk '{print $2}')
  echo "$1: keyboard=$k start=$start shown=${shownat:--} early_ignored=$(grep -c 'Ignoring showSoftInput' "$OUT/$1.log") asks=$(grep -c 'ImeTracker: com.lifetracker.*onRequestShow' "$OUT/$1.log") hides=$(grep -o 'reason HIDE_[A-Z_]*' "$OUT/$1.log" | sort | uniq -c | tr -s ' ' | tr '\n' ';')"
}
close_sheet() {
  adb -s "$S" shell input keyevent KEYCODE_BACK
  adb -s "$S" shell sleep 0.7
  adb -s "$S" shell input keyevent KEYCODE_BACK
  adb -s "$S" shell sleep 1.5
}
open_app() {
  adb -s "$S" shell am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -n $P/.MainActivity > /dev/null 2>&1
  adb -s "$S" shell sleep 5
}
for i in $(seq 1 "$N"); do
  open_app
  adb -s "$S" shell input keyevent KEYCODE_HOME
  adb -s "$S" shell sleep 2
  plus "warm_$i"
  close_sheet
  plus "cold_$i"
  adb -s "$S" shell input keyevent KEYCODE_HOME
  adb -s "$S" shell sleep 2
  plus "again_$i"
  close_sheet
  if [ -n "$DEAD" ]; then
    adb -s "$S" shell am force-stop $P
    adb -s "$S" shell sleep 1
    plus "dead_$i"
    close_sheet
  fi
done
open_app
adb -s "$S" shell input keyevent KEYCODE_HOME
