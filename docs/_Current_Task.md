# Current Task: put the build tools back on this PC (in D:\dev)
**Date:** 2026-10-31 · **Branch:** master · Ahmed's OK: "Yes, install them" (2026-10-31)

## Goal
Flutter, the Android SDK (with adb) and a JDK, on D: so a future C: wipe can't take them, so chats can build Uplan again.
Size: small (about 20–30 min of work) plus 20–40 min of downloads and unpacking, then a first test build (5–10 min).

## The plan (everything in D:\dev)
- **Flutter 3.47.9** stable (2026-10-29; Uplan needs 3.44 or newer) → `D:\dev\flutter`.
  https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.47.9-stable.zip
  sha256 `d8e2b5977e09082c6440f89dc1aa887b94c8fbcc3b39222797046295a3f68a9e`
- **Java: Eclipse Temurin JDK 21.0.13+9** (a zip, no installer; Gradle 9.1 and AGP 9.0 need 17+, the laptop used Android Studio's Java 21) → `D:\dev\jdk-21`.
  https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.13%2B9/OpenJDK21U-jdk_x64_windows_hotspot_21.0.13_9.zip
  sha256 `a4dbaa05fca4bd89d84584e58c459bd732efebb1722af80ab13c6516832004f9`
- **Android SDK:** command-line tools 23.0 → `D:\dev\android-sdk\cmdline-tools\latest`, then platform-tools (adb), platform 36 and build-tools; the NDK comes by itself on the first build. **Waits for Ahmed's OK to accept Google's Android SDK license.**
  https://dl.google.com/android/repository/commandlinetools-win-16111833_latest.zip
  sha1 `57d04f2d75eb8e8fffc5000a987e5de4b5a63e9d`
- **Package cache** (`PUB_CACHE`) → `D:\dev\pub-cache`: a chat's writes under AppData land in the Claude app's private copy (found 2026-10-31, see Noticed), so nothing of this goes in AppData.
- **User variables, for real** (a .cmd started with explorer.exe, because a chat's registry writes never reach Windows): PATH gains `D:\dev\flutter\bin`, `D:\dev\android-sdk\platform-tools` and `D:\dev\android-sdk\cmdline-tools\latest\bin`; plus `JAVA_HOME`, `ANDROID_HOME` and `PUB_CACHE`. Chats see them after the Claude app restarts; until then they use full paths.
- Downloads stay in `D:\dev\downloads\<tool>\` so a crash never means downloading again.

## Done means
- [ ] `flutter doctor` shows Flutter and the Android toolchain without errors
- [ ] A debug build of Uplan (`flutter build apk --debug`) succeeds
- [ ] PATH and the three variables are set for real (checked from outside the app)
- [ ] START HERE and `.claude/skills/uplan-device-release/SKILL.md` name the new paths

## Do not touch
- Smart App Control, the system-wide PATH, any Windows setting beyond the user variables above.
- The app's code.

## Log (crash test: one line per step)
- 2026-10-31 14:06 · done: session start (repo up to date and clean); a START HERE line on the code map's auto-refresh (fc20a73) · half-done: nothing
- 2026-10-31 14:16 · starting: downloading Flutter and the JDK into `D:\dev\downloads\flutter` and `\jdk` in the background · to restart after a crash: run the same `curl -L -C - -o <file> <url>` again (it resumes), then check the sha256 above · next: unpack both; ask Ahmed about the Android SDK license

## Noticed (not fixing now)
- **The old signing key is very likely gone.** Release builds are signed with the debug key (`android/app/build.gradle.kts`), and that key lived in `C:\Users\kille\.android\debug.keystore` on the laptop, which the reset erased. This PC has no `.android` folder and git never held a key. An APK built here will refuse to install over the Uplan on the phone. Way out: in the app, Settings > Export data, keep the file off the phone, uninstall, install the new build, then Restore from the backup file (check first whether photos are in that backup). Then make a real signing key and back it up (master plan, Phase 4 list). Decide this before the release.
- **AppData writes from a chat stay inside the Claude app's private copy**, like the registry: `%LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local` holds `npm-cache`, `pip`, `GitHub CLI` and more. The shared rules say "Files aren't affected", which holds outside AppData. To pass to the AI management chat.
- The 10 plan files in `docs/superpowers/plans/` never had their check boxes ticked, although the work shipped. The master plan is the record of what is done.
- `feedback/app.md` still shows all 4 items unticked. 3 are done (today marker in v1.9.1; per-list auto-archive and photo crop in v1.10.0); the 4th (a Samsung- or Apple-style note design) is largely answered by the notes redesign.
- STATUS refers to "Working Style #11" (general, non-clinical examples in user-facing text), but this repo's `CLAUDE.md` lists only 8 Working Style rules. STATUS also says the durable project history lived in a CLAUDE.md in OneDrive, outside the repo. No such file was found in OneDrive on this PC (2026-10-27), so rules 9 and up may be lost. The decisions log records #11.
- STATUS's "IN-FLIGHT" section (2026-07-28) is out of date: the editor redesign and the photo grid shipped in v1.10.0, and the August shift entry is long past.
- `README.md` is still Flutter's default text.
- GitHub shows this repo as public, while the device skill calls it "the private source repo". Worth checking which one Ahmed wants.
