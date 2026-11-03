#!/usr/bin/env bash
# Tester chat: does the widget's "+" bring the keyboard up?
# Usage: [TARGET=.MainActivity] kb_check.sh <serial> <label> <runs>
# The "+" goes to $TARGET: .QuickAddActivity by default, the sheet's own window since
# 2026-11-03 (not exported, so run `adb root` on the emulator first); .MainActivity is
# the old way, still used by widget buttons drawn before that update.
# warm = Uplan was opened from its icon, then sent away with Home (its activity stays
#        alive), then the "+".
# cold = the app's process is stopped first, then the "+" starts it.
# Each line names the window in front and whether the keyboard is up.
export MSYS_NO_PATHCONV=1
S=$1; LABEL=$2; RUNS=$3
P=com.lifetracker.life_tracker
TARGET=${TARGET:-.QuickAddActivity}
PLUS="am start -a es.antonborri.home_widget.action.LAUNCH -d uplan://add_task -n $P/$TARGET"
ICON="am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -n $P/.MainActivity"
front() { adb -s "$S" shell dumpsys window displays | tr -d '\r' | grep -m1 -o 'mCurrentFocus=[^ ]* [^ ]* [^ }]*' | awk '{print $3}' | sed 's/.*\.//'; }
shown() { adb -s "$S" shell dumpsys input_method | tr -d '\r' | grep -o "mInputShown=[a-z]*" | head -1; }
state() { echo "front=$(front) $(shown)"; }
for i in $(seq 1 "$RUNS"); do
  adb -s "$S" shell am force-stop $P
  adb -s "$S" shell $ICON > /dev/null
  adb -s "$S" shell sleep 6
  adb -s "$S" shell input keyevent KEYCODE_HOME
  adb -s "$S" shell sleep 2
  adb -s "$S" logcat -c
  adb -s "$S" shell $PLUS > /dev/null
  adb -s "$S" shell sleep 3
  echo "$LABEL warm $i: $(state) | ignored asks: $(adb -s "$S" logcat -d | grep -c 'Ignoring showSoftInput')"
done
adb -s "$S" shell am force-stop $P
adb -s "$S" shell sleep 2
adb -s "$S" shell $PLUS > /dev/null
adb -s "$S" shell sleep 6
echo "$LABEL cold: $(state)"
# keyboard up on the sheet, Home, then the "+" again: the open sheet comes back, and
# Android hides the keyboard as its window returns (HIDE_WINDOW_GAINED_FOCUS_WITHOUT_EDITOR)
adb -s "$S" shell input keyevent KEYCODE_HOME
adb -s "$S" shell sleep 2
adb -s "$S" shell $PLUS > /dev/null
adb -s "$S" shell sleep 3
echo "$LABEL keyboard up, Home, + again: $(state)"
# then Home and Uplan's icon: the app (the sheet's own window) or the sheet (the old way)
adb -s "$S" shell input keyevent KEYCODE_HOME
adb -s "$S" shell sleep 2
adb -s "$S" shell $ICON > /dev/null
adb -s "$S" shell sleep 3
echo "$LABEL Home, then Uplan's icon: $(state)"
adb -s "$S" shell am force-stop $P
