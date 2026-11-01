# Signing-key move Implementation Plan

> **For agentic workers:** carried out in this chat with superpowers:executing-plans (Ahmed's standing rule: no
> helpers by default). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ahmed's Uplan keeps all its data (notes, 309 photos, Settings) and moves to a real signing key, under the
same app ID on his Z Flip 6.

**Architecture:** A new RSA key signs every build from `android/key.properties`. The phone's whole private folder is
copied to D: over adb `run-as`, checked, rehearsed into a throwaway test copy of the app, and then put back into a
fresh install that carries the new key.

**Tech Stack:** Flutter 3.44.9, Gradle Kotlin DSL, Java 21 `keytool`, Android build-tools 36.0.0 (`apksigner`,
`aapt2`), adb, Python 3.14 (`tarfile`, `sqlite3`, `hashlib`).

**Spec:** `docs/superpowers/specs/2026-11-01-signing-key-design.md`

## Global Constraints
- Nothing on the phone is removed before Task 5 has passed and Ahmed has said so in chat.
- The key's password never appears in chat, logs, commits or command lines: only in `android/key.properties` and in
  a child process's environment. Run `git status` before every commit; `key.properties` and `*.jks` must not show.
- His data copies live only in `D:\backups\uplan\2026-11-01\`, never in a repo (it shows as public on GitHub).
  Scripts that read them go in the scratchpad and run as `python -X utf8 -I`.
- Tools by full path: adb `D:\dev\android-sdk\platform-tools\adb.exe`, keytool `D:\dev\jdk-21\bin\keytool.exe`,
  apksigner `D:\dev\android-sdk\build-tools\36.0.0\apksigner.bat`, aapt2 `D:\dev\android-sdk\build-tools\36.0.0\aapt2.exe`,
  flutter `D:\dev\flutter\bin\flutter.bat` (3.44.9, never 3.47.9).
- Phone commands run from Git Bash with `MSYS_NO_PATHCONV=1` for `/data/...` paths. Never redirect adb's binary
  output in PowerShell (it re-encodes the bytes).
- Phone serial `R5CX631BMJB`; app `com.lifetracker.life_tracker`; test copy `com.lifetracker.life_tracker.rehearsal`.
- Never change Smart App Control (debug builds work while it is on).

## Review Focus
1. **A short or damaged copy** (the USB link drops, or bytes get mangled on Windows): Task 4 checks the file count
   against the phone's, SQLite's integrity check, and that every photo a note points to is in the copy.
2. **`run-as` can't write into a fresh install** (a phone or Samsung limit): Task 5 meets it first, on the test copy,
   and has a fallback; if both fail, stop before anything is removed.
3. **Ahmed uses the app between the copy and the uninstall:** Task 6 makes a final copy and compares the database's
   SHA-256 with Task 4's before removing anything.
4. **Reminders don't come back after the move:** Task 6 counts Uplan's alarms before and after, and restarts the
   phone if they are missing.
5. **Builds without `key.properties` (cloud chats, fresh clones):** Task 2 checks the fallback to the debug key.

---

### Task 1: The signing key and its backup

**Files:**
- Create (outside the repo): `D:\keys\uplan\uplan-release.jks`, `C:\Users\kille\OneDrive\Uplan key backup\uplan-release.jks`
- Create (git-ignored): `android/key.properties`
- Modify: `docs/_Undo_Table.md`

**Interfaces:**
- Produces: `android/key.properties` with `storePassword`, `keyPassword` (the same value; PKCS12 uses one password),
  `keyAlias=uplan`, `storeFile=D:/keys/uplan/uplan-release.jks`; the certificate's SHA-256 fingerprint, written into
  the task file and later START HERE.

- [ ] **Step 1:** `git check-ignore -v android/key.properties` → prints the `android/.gitignore` rule.
- [ ] **Step 2:** A scratchpad Python script stops if the `.jks` or `key.properties` already exists; makes the password
  with `secrets.token_urlsafe(24)`; writes `key.properties`; runs `keytool -genkeypair -keystore <storeFile>
  -storetype PKCS12 -keyalg RSA -keysize 4096 -validity 10000 -alias uplan -dname "CN=Uplan" -storepass:env
  UPLAN_KS_PASS -keypass:env UPLAN_KS_PASS` with the password only in the child's environment; prints only the `SHA256:`
  line of `keytool -list -v`. Expected: one fingerprint line and no password anywhere in the output.
- [ ] **Step 3:** Copy the `.jks` into `OneDrive\Uplan key backup\` (Ahmed's go-ahead covers it) and compare both
  files' SHA-256. Expected: equal.
- [ ] **Step 4 (Ahmed):** Notepad opens `android/key.properties`; he copies the password into his password manager or a
  locked note on his phone, never next to the key file, and closes Notepad.
- [ ] **Step 5:** Two undo-table rows: the key folder on D:, and the OneDrive copy. Commit the undo table only.

### Task 2: Sign builds with the new key

**Files:**
- Modify: `android/app/build.gradle.kts` (the top for `java.util.Properties`; `android { signingConfigs … }`; `buildTypes`)

**Interfaces:**
- Consumes: `android/key.properties` from Task 1, read with `rootProject.file("key.properties")`.
- Produces: debug and release builds signed with the new key when the file exists. Without it, release falls back to
  `signingConfigs.getByName("debug")` and debug keeps its default.

- [ ] **Step 1:** Add `signingConfigs { create("release") { … } }` filled from the properties file, and use it in both
  `debug` and `release` when the file exists. Keep the R8 comment and `isMinifyEnabled = false` /
  `isShrinkResources = false`, and replace the two TODO lines with one line saying what signs the build.
- [ ] **Step 2:** In `android/`: `cmd //c gradlew.bat :app:signingReport` → the debug and release variants show
  `D:\keys\uplan\uplan-release.jks`, alias `uplan`, and Task 1's SHA-256.
- [ ] **Step 3:** Rename `android/key.properties` to `key.properties.off`, run the report again → both variants show
  `C:\Users\kille\.android\debug.keystore`. Rename it back.
- [ ] **Step 4:** `flutter analyze` → "No issues found!"; `flutter test` → all pass (303 on 2026-10-31).
- [ ] **Step 5:** Commit `android/app/build.gradle.kts`: `build(android): sign builds with the key from key.properties`.

### Task 3: Build the two apps

**Files:** none committed. Outputs go to `D:\backups\uplan\2026-11-01\`.

- [ ] **Step 1:** `flutter build apk --debug`, then copy `build/app/outputs/flutter-apk/app-debug.apk` to
  `uplan-new-key-debug.apk`.
- [ ] **Step 2:** Set `applicationId = "com.lifetracker.life_tracker.rehearsal"` for one build only; `flutter build apk
  --debug`; copy to `uplan-rehearsal-debug.apk`; `git checkout -- android/app/build.gradle.kts`; `git status` is clean.
- [ ] **Step 3:** For each APK: `apksigner verify --print-certs` → the SHA-256 equals Task 1's (compare without colons
  or case); `aapt2 dump badging` → `package: name='com.lifetracker.life_tracker'` and `…rehearsal'`.

### Task 4: Copy the phone's data to D: and check it

**Files:** `D:\backups\uplan\2026-11-01\uplan-full.tar`, `uplan-restore.tar`, `counts.txt` (none in git).

- [ ] **Step 1 (Ahmed):** the phone stays unlocked and plugged in, and he doesn't use Uplan until Task 6 ends.
- [ ] **Step 2:** On the phone, through `run-as`: count the files under `app_flutter shared_prefs databases files` and
  their size (`find … -type f | wc -l`, `du -sk`). Count Uplan's alarms: `dumpsys alarm | grep -c
  com.lifetracker.life_tracker`. Write both into `counts.txt`.
- [ ] **Step 3:** `adb shell am force-stop com.lifetracker.life_tracker`, then `adb exec-out run-as
  com.lifetracker.life_tracker tar cf - app_flutter shared_prefs databases files > …/uplan-full.tar`.
- [ ] **Step 4:** A scratchpad Python script checks the tar: its file count equals the phone's; `PRAGMA
  integrity_check` on `app_flutter/life_tracker.db` says `ok`; every `note_blocks.content` with `type = 'photo'` is a
  file in `app_flutter/note_images/` (expected 309 files, 0 missing). It writes the row counts per table and the
  database's SHA-256 to `counts.txt`.
- [ ] **Step 5:** The same script writes `uplan-restore.tar`: everything except `app_flutter/flutter_assets/`,
  `app_flutter/res_timestamp-*` and `shared_prefs/FlutterSecure*.xml`.

### Task 5: Dress rehearsal

- [ ] **Step 1:** `adb install …/uplan-rehearsal-debug.apk` → `Success`. Don't open it yet.
- [ ] **Step 2:** `adb push …/uplan-restore.tar /data/local/tmp/`, then `adb shell run-as
  com.lifetracker.life_tracker.rehearsal tar xf /data/local/tmp/uplan-restore.tar`. If `run-as` can't read the file,
  stream it instead: `adb exec-in run-as com.lifetracker.life_tracker.rehearsal tar xf - < …/uplan-restore.tar`.
- [ ] **Step 3:** Through `run-as`: `sha256sum app_flutter/life_tracker.db` equals `counts.txt`, and
  `ls app_flutter/note_images | wc -l` is 309.
- [ ] **Step 4 (Ahmed):** `adb shell monkey -p com.lifetracker.life_tracker.rehearsal -c
  android.intent.category.LAUNCHER 1` opens it. If it asks about notifications, tap **Don't allow**. He opens a few
  notes with photos, his tasks, his habits and a Setting he changed, and says whether anything is missing.
- [ ] **Step 5:** `adb uninstall com.lifetracker.life_tracker.rehearsal`.
- **Gate:** Task 6 starts only after Ahmed says the rehearsal looked right. Otherwise stop: nothing has been removed.

### Task 6: The move

- [ ] **Step 1:** Final copy: force-stop, tar to `uplan-full-final.tar`, and compare its file count and database
  SHA-256 with `counts.txt`. If they differ, run Task 4's checks on the final copy and rebuild `uplan-restore.tar`
  from it.
- [ ] **Step 2:** `adb uninstall com.lifetracker.life_tracker` → `Success`. This deletes the old app's folder; the
  checked copy is on D:.
- [ ] **Step 3:** `adb install …/uplan-new-key-debug.apk` → `Success`. Don't open it yet.
- [ ] **Step 4:** Put the data back as in Task 5, steps 2–3, into `com.lifetracker.life_tracker`, and check the
  database SHA-256 and the 309 photos. Then remove the phone's staging copy: `adb shell rm
  /data/local/tmp/uplan-restore.tar` (the original stays on D:).
- [ ] **Step 5 (Ahmed):** Launch it. He checks his notes, photos, tasks, habits and Settings; allows notifications,
  and alarms if asked; sets the battery to Unrestricted if he had that before (Settings > Apps > Uplan > Battery);
  adds the widgets again; enters the feedback key again if he uses it.
- [ ] **Step 6:** Count Uplan's alarms again. If they are near 0 while `counts.txt` had more, restart the phone and
  count once more.

### Task 7: Handover

**Files:**
- Modify: `CLAUDE.md` (START HERE: the signing-key trap is resolved, plus the key's place and fingerprint),
  `.claude/skills/uplan-device-release/SKILL.md` ("Deploying a build" and the release ritual: check the fingerprint
  first; builds carry the new key), `docs/_Master_Plan.md` (tick the item), `docs/_Current_Task.md`,
  `docs/_Task_History.md`, `docs/_Week_Log.md`, `docs/_Undo_Table.md` (the phone's reinstall and this PC's USB
  debugging trust)
- Modify (claude-setup): `tracker/rows.json` (Uplan's row), `workflow/retros.md` (once Ahmed says it works)

- [ ] **Step 1:** Make the edits; `git status` shows no key or backup files; commit and push trackerapp; then commit
  and push claude-setup.
- [ ] **Step 2:** The copy stays in `D:\backups\uplan\2026-11-01\` until Ahmed says he is happy; what happens to it
  after that is his call.
