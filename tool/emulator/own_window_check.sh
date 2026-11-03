#!/usr/bin/env bash
# Tester chat: does the widget's "+" leave the open app alone?
# (docs/superpowers/specs/2026-11-03-quick-add-own-window-design.md)
# Usage: [TARGET=.MainActivity] own_window_check.sh <serial> [x y of a point on the dimmed area]
# The "+" goes to $TARGET: .QuickAddActivity by default, the sheet's own window (not
# exported, so run `adb root` on the emulator first); .MainActivity is the old way.
# Before each case Uplan is opened from its launcher intent on Notes, a screen other
# than its start tab, and then sent away with Home. Prints PASS or FAIL per case:
#   1 own task      the "+" window is in front, in a task of its own
#   2 app untouched after a tap on the dimmed area the app's window is still there,
#                   and the sheet's is gone
#   3 place kept    Uplan's icon then shows the screen it showed before the "+"
#   4 Back closes   "+", Back, Back: the sheet's window is gone and the home screen is
#                   in front; Uplan's icon then shows the app's screen again
#   5 comes back    "+", type "milk", Home, "+": the same sheet's task (the text is
#                   checked by eye in 5_back.png)
export MSYS_NO_PATHCONV=1
S=$1; SX=${2:-540}; SY=${3:-300}
P=com.lifetracker.life_tracker
TARGET=${TARGET:-.QuickAddActivity}
OUT=${OUT:-C:/Users/kille/AppData/Local/Temp/claude/D--projects-trackerapp/c8c479bc-9817-44c2-8220-600016f6dfea/scratchpad/own_window}
FF=$(ls -d "$LOCALAPPDATA"/Microsoft/WinGet/Packages/Gyan.FFmpeg.Essentials*/ffmpeg-*/bin | head -1)
PY=C:/Users/kille/AppData/Local/Programs/Python/Python314/python.exe
DIFF="$(dirname "$0")/screen_diff.py"
PLUS="am start -a es.antonborri.home_widget.action.LAUNCH -d uplan://add_task -n $P/$TARGET"
ICON="am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -n $P/.MainActivity"
mkdir -p "$OUT"
run() { adb -s "$S" shell "$@"; }
front() { run dumpsys window displays | tr -d '\r' | grep -m1 -o 'mCurrentFocus=[^ ]* [^ ]* [^ }]*' | awk '{print $3}'; }
# The task number of a live (not finishing) record of the class $1, or nothing.
task_of() { run dumpsys activity activities | tr -d '\r' | grep -o "ActivityRecord{[^}]* $P/\\$1 t[0-9]*}" | head -1 | sed -n 's/.* t\([0-9][0-9]*\)}$/\1/p'; }
shot() { adb -s "$S" exec-out screencap -p > "$OUT/$1.png"; }
differs() { "$PY" -I "$DIFF" "$FF" "$OUT/$1.png" "$OUT/$2.png"; }
small() { awk -v d="$1" 'BEGIN { exit !(d < 6) }'; }
verdict() { if [ "$2" = 0 ]; then echo "PASS $1 | $3"; else echo "FAIL $1 | $3"; fi; }
open_app_then_home() {
  run am force-stop $P
  run $ICON --es route /notes > /dev/null
  run sleep 8
  shot "$1"
  run input keyevent KEYCODE_HOME
  run sleep 2
}
close_sheet() {
  case "$(front)" in $P/*) run input tap "$SX" "$SY"; run sleep 2.5 ;; esac
}

# 1-3: "+", then a tap on the dimmed area, then Uplan's icon.
open_app_then_home before
app_task=$(task_of .MainActivity)
run $PLUS > /dev/null; run sleep 3
f=$(front); plus_task=$(task_of "$TARGET")
[ "${f##*.}" = "${TARGET#.}" ] && [ -n "$plus_task" ] && [ "$plus_task" != "$app_task" ]
verdict "1 own task" $? "front ${f##*.}, app task $app_task, + task $plus_task"
close_sheet
app_after=$(task_of .MainActivity); plus_after=$(task_of "$TARGET")
[ -n "$app_after" ] && [ -z "$plus_after" ]
verdict "2 app untouched" $? "app task ${app_after:-gone}, + task ${plus_after:-gone}"
run $ICON > /dev/null; run sleep 3; shot after_icon
d=$(differs before after_icon); small "$d"
verdict "3 place kept" $? "difference $d (front $(front | sed 's/.*\.//'))"

# 4: "+", Back, Back, then Uplan's icon.
open_app_then_home before4
run $PLUS > /dev/null; run sleep 3
run input keyevent KEYCODE_BACK; run sleep 1
run input keyevent KEYCODE_BACK; run sleep 2.5
f=$(front); plus_after=$(task_of "$TARGET")
case "$f" in $P/*) in_front=uplan ;; *) in_front=other ;; esac
run $ICON > /dev/null; run sleep 3; shot after_back
d=$(differs before4 after_back)
[ "$in_front" = other ] && [ -z "$plus_after" ] && small "$d"
verdict "4 Back closes" $? "front after Back ${f##*.}, + task ${plus_after:-gone}, then icon: difference $d"

# 5: "+", type, Home, "+" again.
open_app_then_home before5
run $PLUS > /dev/null; run sleep 3
first=$(task_of "$TARGET")
run input text milk; run sleep 1
run input keyevent KEYCODE_HOME; run sleep 2
run $PLUS > /dev/null; run sleep 3
again=$(task_of "$TARGET"); shot 5_back
[ -n "$first" ] && [ "$first" = "$again" ]
verdict "5 comes back" $? "+ task $first, then $again (text: $OUT/5_back.png)"
close_sheet
run am force-stop $P
