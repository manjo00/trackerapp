#!/usr/bin/env bash
# Tester chat: film what the screen shows when the widget's "+" is tapped.
# Usage: [TARGET=.MainActivity] plus_video.sh <serial> <label> <warm|again|cold|dead> [display id]
# The "+" goes to $TARGET: .QuickAddActivity by default, the sheet's own window since
# 2026-11-03 (not exported, so run `adb root` on the emulator first); .MainActivity is
# the old way, still used by widget buttons drawn before that update.
#   warm  = Uplan opened normally (its main screen), sent away with Home, then "+"
#   again = a "+" sheet left open, sent away with Home, then "+" again
#   cold  = a "+" sheet opened and closed with Back (activity gone, app alive), then "+"
#   dead  = Uplan's process stopped, then "+"
# Writes <label>.h264, the frames at 10 per second and <label>_sheet.png (the
# first 3 seconds after the "+", 30 frames in a grid) to OUT.
export MSYS_NO_PATHCONV=1
S=$1; LABEL=$2; MODE=$3; DISPLAY_ID=${4:-}
P=com.lifetracker.life_tracker
OUT=${OUT:-C:/Users/kille/AppData/Local/Temp/claude/D--projects-trackerapp/c8c479bc-9817-44c2-8220-600016f6dfea/scratchpad/video}
FF=$(ls -d "$LOCALAPPDATA"/Microsoft/WinGet/Packages/Gyan.FFmpeg.Essentials*/ffmpeg-*/bin | head -1)
TARGET=${TARGET:-.QuickAddActivity}
PLUS="am start -a es.antonborri.home_widget.action.LAUNCH -d uplan://add_task -n $P/$TARGET"
mkdir -p "$OUT"
case "$MODE" in
  warm)
    adb -s "$S" shell am force-stop $P
    adb -s "$S" shell am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -n $P/.MainActivity > /dev/null
    adb -s "$S" shell sleep 8
    adb -s "$S" shell input keyevent KEYCODE_HOME ;;
  again)
    adb -s "$S" shell am force-stop $P
    adb -s "$S" shell $PLUS > /dev/null
    adb -s "$S" shell sleep 8
    adb -s "$S" shell input keyevent KEYCODE_HOME ;;
  cold)
    adb -s "$S" shell $PLUS > /dev/null
    adb -s "$S" shell sleep 8
    adb -s "$S" shell input keyevent KEYCODE_BACK
    adb -s "$S" shell sleep 1
    adb -s "$S" shell input keyevent KEYCODE_BACK ;;
  dead)
    adb -s "$S" shell am force-stop $P ;;
esac
adb -s "$S" shell sleep 2
# An mp4 keeps real timestamps (a raw h264 stream doesn't). It goes to the
# shell's own scratch folder, never the user's storage, and is removed after.
REC="screenrecord --time-limit 5"
[ -n "$DISPLAY_ID" ] && REC="$REC --display-id $DISPLAY_ID"
adb -s "$S" shell $REC /data/local/tmp/uplan_rec.mp4 &
adb -s "$S" shell sleep 1
adb -s "$S" shell log -t UplanTest "plus sent"
# TAP="x y" taps the widget's "+" on the launcher, like a finger; otherwise
# the widget's intent is sent directly.
if [ -n "${TAP:-}" ]; then adb -s "$S" shell input tap $TAP; else adb -s "$S" shell $PLUS > /dev/null; fi
wait
adb -s "$S" pull /data/local/tmp/uplan_rec.mp4 "$OUT/$LABEL.mp4" > /dev/null
adb -s "$S" shell rm /data/local/tmp/uplan_rec.mp4
# Frames 0.1 s apart from 0.6 s on (the "+" goes out about 1 s in).
"$FF/ffmpeg.exe" -loglevel error -y -ss 0.6 -i "$OUT/$LABEL.mp4" -vf fps=10 "$OUT/${LABEL}_%03d.png"
"$FF/ffmpeg.exe" -loglevel error -y -i "$OUT/${LABEL}_%03d.png" -frames:v 1 \
  -vf "select='lt(n,24)',scale=216:-1,tile=12x2:padding=4" "$OUT/${LABEL}_sheet.png"
echo "$OUT/${LABEL}_sheet.png"
