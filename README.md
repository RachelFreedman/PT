# PT Tracker

A personal iOS app for tracking progress through the Muldowney Exercise Protocol — a structured physical therapy program.

## Requirements

- macOS with Xcode 26+ installed
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- An iPhone (or the iOS Simulator)

## Building

```bash
# Generate the Xcode project from project.yml
xcodegen generate

# Build for simulator
xcodebuild -project PTTracker.xcodeproj -scheme PTTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Or open `PTTracker.xcodeproj` in Xcode and press **Cmd+R**.

## Deploying to iPhone

1. Open the project in Xcode
2. Plug in your iPhone via USB
3. Select your iPhone as the run destination (top toolbar)
4. In **Signing & Capabilities**, set Team to your Apple ID
5. Press **Cmd+R** to build and run
6. On first install, go to **Settings > General > VPN & Device Management** on your iPhone and trust the developer profile

After the first USB pairing you can enable **Window > Devices and Simulators > Connect via network** for wireless deploys.

> With a free Apple ID the app expires after 7 days and needs re-deploying. Your data is preserved between re-deploys.

## Using the App

**Today** — Start a workout or log a skip. Before each workout you'll rate your wellness (0–10). The timer counts down each exercise; press play/pause or skip. Tap any exercise to jump to it.

**Progress** — Timeline chart of your workout history, current batch details, and drill-down into all tracks and levels.

**History** — All past workouts and skips. Swipe to delete entries. Tap the share button to export everything as CSV.

**Settings** — Set your starting batch, import data from CSV, or reset everything.

### Progression Rules

- Exercises start at 90 seconds and gain +10s per completed workout, capping at 180s
- When all exercises in a batch reach their target, you advance to the next batch
- If 3+ days pass without a fully completed workout, you repeat at current durations
- If 7+ days pass, the batch resets to starting durations
- Skipping an exercise with ≤20 seconds remaining counts as completed

### Data

All data is stored locally on the device. Use **History > Export** to back up as CSV, and **Settings > Import** to restore.

## Running Tests

```bash
xcodebuild -project PTTracker.xcodeproj -scheme PTTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## Documentation

See [spec.md](spec.md) for full technical documentation of the app architecture, data models, and protocol configuration.
