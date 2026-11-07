---
name: validate-ac
description: Validate a list of acceptance criteria (AC) against the Thunderbird iOS app by driving the iOS simulator directly through Device Hub (Xcode 27's Simulator), observing the screen, and reporting PASS / FAIL / BLOCKED for each criterion with screenshot evidence, on the current branch only. Videos and a before/after baseline comparison are optional and only done when the user asks. Use when the user gives acceptance criteria, a ticket, or a PR description and asks to verify, validate, or demo it in the simulator.
---

# Validate acceptance criteria in the simulator

Take a list of acceptance criteria, run the real app in the iOS simulator, drive it like a user would, look at what
happens, and judge each criterion. No throwaway UI tests. Never edit app source as part of validation.

## Inputs

- The AC: pasted text, a ticket/PR body, or a file path. If it is a PR or issue URL, read it with `gh`.
- Optional: scheme, device, launch arguments, starting state ("fresh install", "signed-in account").
- Optional extras, **off by default, only when the user asks**:
  - **video**: "record", "video", "demo" -> follow step 3.
  - **baseline**: "before/after", "baseline", "compare with main" -> also run a build without the change (step 2).
  Default is: validate the criteria on the current branch's build, with screenshots as evidence, and nothing more.
- If something needed to reach a screen is unclear, ask once. Do not guess credentials, and never use real accounts.

## 0. Preflight (stop and tell the user if any step fails)

1. **Xcode.** `xcode-select -p` may point at Command Line Tools. Find the real Xcode
   (`ls -d /Applications/Xcode*.app`) and `export DEVELOPER_DIR=<app>/Contents/Developer` for every command.
2. **Device Hub.** In Xcode 27 the Simulator app is `Xcode*.app/Contents/Applications/DeviceHub.app`.
   Open it (`open -a <path>`). Pick one device and use only it. Check `xcrun simctl list devices booted`.
   A freshly booted device shows black or the Apple logo for a while: wait with `xcrun simctl bootstatus <udid>`.
3. **Permissions.** The app running these commands needs **Accessibility** and **Screen Recording**
   (System Settings > Privacy & Security; restart the app after granting). Test:
   `osascript -e 'tell application "System Events" to tell process "DeviceHub" to get {position, size} of window 1'`.
   Error `-1719` means Accessibility is not granted. If it is missing, ask the user to grant it; do not work around it.
4. **Helpers.** Run `scripts/setup.sh` once (compiles two tiny Swift tools into `$TMPDIR/dh-tools`).
5. **Build and install.**
   `xcodebuild build -project Thunderbird/Thunderbird.xcodeproj -scheme Thunderbird -destination "id=<udid>" -derivedDataPath $TMPDIR/ac-dd`
   then `xcrun simctl install <udid> <.app>` and `xcrun simctl launch <udid> net.thunderbird.ios [args]`.
   Validate the build the user cares about (current branch unless told otherwise). Say which commit you tested.

## 1. Turn the AC into checks

Write a numbered table before touching the simulator. For each criterion:

| # | Criterion (verbatim) | Steps to reach it | Observable expected result |

- One criterion = one observable outcome. Split compound criteria ("A and B") into separate rows.
- The expected result must be something you can **see on screen** (text, element present or absent, navigation).
  If a criterion cannot be observed in the UI (e.g. "password stored in keychain"), mark it
  `NOT UI-OBSERVABLE`, say what would verify it instead, and do not guess a verdict.
- Show the table to the user only if the AC were ambiguous; otherwise proceed.

## 2. Drive the simulator (Device Hub, direct control)

Use `scripts/dh.sh` (all coordinates are **points inside the Device Hub window**, not screen pixels):

```bash
export DH_TOOLS=$TMPDIR/dh-tools
scripts/dh.sh shot out.png        # capture the Device Hub window region only
scripts/dh.sh click X Y           # real mouse click at window point (X,Y)
scripts/dh.sh type "text"         # keystrokes to the focused field
```

How to find coordinates: take a `shot`, `Read` the PNG, and divide the pixel position by the capture scale
(capture pixel width / window width in points; 2.0 on a Retina display). Re-shoot after every action and confirm the
screen changed as expected before the next step. The window can move between calls, and the script re-reads it every time.

Safety rules, which are not optional:

- `dh.sh` refuses to act unless Device Hub is the front-most app **and** the topmost window at the click point.
  If it prints `ABORT`, wait a few seconds (a notification banner is usually in the way) and retry; never bypass it.
  It once clicked into another app's window (a browser) before these checks existed.
- Never capture the whole screen or read screenshots that include other apps. Use `dh.sh shot` (window region only).
- After clicking a text field, wait ~1.2 s before typing; the first keystroke is otherwise dropped.
- Keystrokes go to whatever is focused in Device Hub, including keys the user or another app sends. Tell the user
  up front to keep hands off the keyboard and mouse during a run. After typing, `shot` and read the field to confirm
  it contains exactly what you typed before continuing. If it does not, discard that run and redo it from a clean install;
  never report a verdict from a contaminated run (this happened once: `how how ho` was appended to the email).
- Only when the user asked for a baseline: also run the criteria against a build without the change, so you can show
  the checks can fail. Otherwise validate the current branch only.
- Only type the test data you chose. Do not enter real credentials, and do not send mail or sign in to real accounts.
- `xcrun simctl` can launch, install, uninstall (reset state), screenshot, and record, but it cannot tap or type.

Reset state between criteria when they depend on a clean start: `simctl terminate`, `simctl uninstall`, reinstall.

## 3. Record (only if the user asked for a video)

Skip this step by default. When asked, record the device screen for each run (or per criterion if that reads better):

```bash
xcrun simctl io <udid> recordVideo --codec h264 --force "$OUT/<name>.mp4" &   # stop with kill -INT
```

Compress before sharing: `avconvert --source in.mp4 --output out.mp4 --preset Preset960x540`
(roughly 3x smaller; `ffmpeg` is usually not installed). Keep videos in the output folder (see step 5), not in the repo.

## 4. Judge each criterion

- **PASS**: you observed the expected result on screen after performing the steps. Quote what you saw.
- **FAIL**: you performed the steps and the screen shows something else. Give expected vs observed, and the
  screenshot name. A FAIL needs a reproducible step list.
- **BLOCKED**: you could not reach the screen (crash, missing account, backend needed, permission denied,
  navigation not possible). Say exactly what stopped you. BLOCKED is not a pass and not a fail.
- **NOT UI-OBSERVABLE**: see step 1.

Never mark PASS from reading code or from "it should work". Re-check a FAIL once (fresh state) before reporting it,
to rule out a flaky click.

## 5. Report

Choose an output folder `$OUT` once per run: the folder the user names, otherwise `${TMPDIR:-/tmp}/validate-ac/<yyyymmdd-hhmm>`.
Never write screenshots, videos or reports inside the repository, where they could be committed by accident.
Write `$OUT/report.md` and summarise in chat:

```
Build: <branch>@<short sha>, device <name> (<iOS version>)
| # | Criterion | Result | Evidence |
|---|-----------|--------|----------|
| 1 | ...       | PASS   | Settings > Accounts shows "uitest.probe@example.com" (shot-3.png) |
| 2 | ...       | FAIL   | Expected X, saw Y (shot-5.png); steps: ... |
Overall: N passed, M failed, K blocked.
Video: $OUT/<name>-small.mp4        (only if one was requested)
```

Screenshots are the default evidence: save the ones that back each verdict (named in the table) in `$OUT/screenshots/`.
Surface FAILs first. End with what you did **not** verify. Do not file issues, open PRs, or post anywhere unless asked.

## Notes from this project

- `AccountInformation` ("Manual Account Setup") is only reachable from Settings once an account exists, so
  validating first-run flows may need a debug launch argument, or an account added by hand first. Ask before adding
  a launch hook; do not commit one.
- The app can show sample data in the inbox regardless of account state; check Settings > Accounts to see saved accounts.
- Device Hub must not be left set to "Stay On Top" afterwards (Window menu).
