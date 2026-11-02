#!/usr/bin/env bash
# Tester chat: does the widget's "+" bring the keyboard up?
# Usage: kb_check.sh <serial> <label> <runs>
# warm = Uplan was opened, then sent away with Home (its activity stays alive),
#        then the "+" intent arrives (onNewIntent -> openQuickAdd), like on the phone.
# cold = the app's process is stopped first, then the "+" intent starts it.
export MSYS_NO_PATHCONV=1
S=$1; LABEL=$2; RUNS=$3
P=com.lifetracker.life_tracker
PLUS="am start -a es.antonborri.home_widget.action.LAUNCH -d uplan://add_task -n $P/.MainActivity"
shown() { adb -s "$S" shell dumpsys input_method | tr -d '\r' | grep -o "mInputShown=[a-z]*" | head -1; }
for i in $(seq 1 "$RUNS"); do
  adb -s "$S" shell am force-stop $P
  adb -s "$S" shell am start -n $P/.MainActivity > /dev/null
  adb -s "$S" shell sleep 6
  adb -s "$S" shell input keyevent KEYCODE_HOME
  adb -s "$S" shell sleep 2
  adb -s "$S" logcat -c
  adb -s "$S" shell $PLUS > /dev/null
  adb -s "$S" shell sleep 3
  echo "$LABEL warm $i: $(shown) | ignored asks: $(adb -s "$S" logcat -d | grep -c 'Ignoring showSoftInput')"
done
adb -s "$S" shell am force-stop $P
adb -s "$S" shell sleep 2
adb -s "$S" shell $PLUS > /dev/null
adb -s "$S" shell sleep 6
echo "$LABEL cold: $(shown)"
# then Home, and back to Uplan from its icon (the sheet is still open)
adb -s "$S" shell input keyevent KEYCODE_HOME
adb -s "$S" shell sleep 2
adb -s "$S" shell am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -n $P/.MainActivity > /dev/null
adb -s "$S" shell sleep 3
echo "$LABEL cold, Home, back from the icon: $(shown)"
# keyboard up (this sheet), Home, then the "+" again: Android then hides the
# keyboard as Uplan's window comes back (HIDE_WINDOW_GAINED_FOCUS_WITHOUT_EDITOR)
adb -s "$S" shell input keyevent KEYCODE_HOME
adb -s "$S" shell sleep 2
adb -s "$S" shell $PLUS > /dev/null
adb -s "$S" shell sleep 3
echo "$LABEL keyboard up, Home, + again: $(shown)"
adb -s "$S" shell am force-stop $P
