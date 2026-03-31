# PTTracker — App Specification

## 1. Overview

PTTracker is a personal iOS app for tracking progress through the **Muldowney Exercise Protocol (MEP)**, a structured physical therapy program for people with Ehlers-Danlos Syndrome (EDS). The app manages exercise progression through 16 sequential batches across 4 tracks, with intelligent workout planning, a countdown timer, wellness tracking, and full data import/export.

- **Platform:** iOS 26
- **Framework:** SwiftUI + SwiftData
- **Build tool:** xcodegen (project.yml → .xcodeproj)
- **Swift version:** 6.0

---

## 2. Data Models

### 2.1 Track

Top-level grouping of related exercises (e.g., "Mat", "Ball", "Neck", "Lower Extremity").

| Field | Type | Description |
|-------|------|-------------|
| `name` | `String` | Display name |
| `sortOrder` | `Int` | Ordering in lists |
| `levels` | `[Level]` | Child levels (cascade delete) |

### 2.2 Level

A phase within a track, containing a set of exercises that must all reach their max duration to be "complete."

| Field | Type | Description |
|-------|------|-------------|
| `levelNumber` | `Int` | Zero-indexed level within track |
| `track` | `Track?` | Parent track |
| `exercises` | `[Exercise]` | Child exercises (cascade delete) |

**Computed:**
- `displayName` → `"Mat L1"` (track name + 1-indexed level)
- `isComplete` → true when every exercise in the level satisfies `exercise.isComplete`

### 2.3 Exercise

An individual exercise with per-exercise timing parameters.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | `String` | — | Exercise name |
| `sortOrder` | `Int` | — | Ordering within level |
| `currentDuration` | `Int` | 90 | Current target duration (seconds) |
| `startDuration` | `Int` | = currentDuration | Initial duration (for progress bar) |
| `targetMaxDuration` | `Int` | 180 | Duration at which exercise is complete |
| `perSessionIncrement` | `Int` | 10 | Seconds added per successful workout |
| `level` | `Level?` | — | Parent level |

**Computed:**
- `isComplete` → `currentDuration >= targetMaxDuration`

### 2.4 DayLog

A single day's workout or skip record.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `date` | `Date` | — | Start-of-day date |
| `isSkip` | `Bool` | — | Whether the day was skipped |
| `skipReason` | `String?` | nil | Reason for skip (e.g., "PEM", "Increased Pain") |
| `batchNumber` | `Int` | 0 | Batch the user was on |
| `wellnessScore` | `Int?` | nil | Pre-workout wellness score (0–10) |
| `exerciseLogs` | `[ExerciseLog]` | [] | Exercise records (cascade delete) |

### 2.5 ExerciseLog

A single exercise performed within a workout.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `exerciseName` | `String` | — | Name of exercise |
| `durationUsed` | `Int` | — | Target duration for the session (seconds) |
| `completed` | `Bool` | false | Whether the exercise was completed |
| `dayLog` | `DayLog?` | — | Parent log |

### 2.6 WellnessScale

Static label lookup for wellness scores 0–10:

| Score | Label |
|-------|-------|
| 0 | Completely normal |
| 1 | Overall feeling well |
| 2 | Minimal feeling unwell |
| 3 | Mild feeling unwell |
| 4 | Feeling unwell but still functioning |
| 5 | Uncomfortable but can function if must |
| 6 | Very difficult to function |
| 7 | Can't function |
| 8 | Very sick and distressed |
| 9 | Extremely sick and distressed |
| 10 | Worst ever |

---

## 3. Protocol Configuration (PTProtocolConfig)

Single source of truth for the entire Muldowney Protocol. Defines timing constants, tracks, levels, exercises, and the batch schedule.

### 3.1 Default Timing

| Constant | Value | Book reference |
|----------|-------|----------------|
| `startDuration` | 90s | "one and a half minutes" |
| `maxDuration` | 180s | "three minutes" |
| `durationIncrement` | 10s | "add ten seconds per day" |

### 3.2 Per-Exercise Overrides

Each `ExerciseDefinition` can override `startDuration`, `maxDuration`, and `durationIncrement`. Notable overrides:

- **Mat L3, Ball L3, Neck L1, Neck L7** exercises start at **60s** ("one to three minutes")
- **Isometric Neck** (Neck L2): **240s → 480s, +20s/day** ("four to eight minutes")

### 3.3 Tracks

| Track | Levels | Purpose |
|-------|--------|---------|
| Mat | 3 (L1–L3) | SIJ & lumbar spine — stabilize the ilia |
| Ball | 3 (L1–L3) | SIJ & lumbar spine — stabilize the sacrum |
| Neck | 7 (L1–L7) | Neck, mid back & upper extremity |
| Lower Extremity | 7 (L1–L7) | Lower extremity (rep-based, not timed) |

Each level lists exercises that require active progression. Carryover exercises from prior levels are included (e.g., "Ball Squeezes" appears in Mat L1, L2, and L3).

### 3.4 Batch Schedule (16 batches)

Batches define which levels are worked on simultaneously. All exercises in a batch must reach max duration before advancing.

**SIJ & Lumbar Spine (batches 0–3):**

| Batch | Levels |
|-------|--------|
| 0 | Mat L1 |
| 1 | Mat L2 + Ball L1 |
| 2 | Mat L3 + Ball L2 |
| 3 | Ball L3 + Neck L1 |

**Neck, Mid Back & Upper Extremity (batches 4–9):**

| Batch | Levels |
|-------|--------|
| 4 | Neck L2 |
| 5 | Neck L3 |
| 6 | Neck L4 |
| 7 | Neck L5 |
| 8 | Neck L6 |
| 9 | Neck L7 + LE L1 |

**Lower Extremity (batches 10–15):**

| Batch | Levels |
|-------|--------|
| 10 | LE L2 |
| 11 | LE L3 |
| 12 | LE L4 |
| 13 | LE L5 |
| 14 | LE L6 |
| 15 | LE L7 |

---

## 4. Progression Engine

Core business logic for workout planning and advancement.

### 4.1 Constants

| Constant | Value | Purpose |
|----------|-------|---------|
| `skipGraceSeconds` | 20 | Seconds remaining at which "skip" counts as completed |
| `repeatAfterDays` | 3 | Days without workout before repeating (no advancement) |
| `resetAfterDays` | 7 | Days without workout before resetting batch to start durations |

### 4.2 Workout Modes

| Mode | Trigger | Behavior |
|------|---------|----------|
| `normal` | ≤2 days since last workout, all exercises completed | Advance durations for completed exercises |
| `repeatAfterGap` | 3–6 days since last workout | Repeat at current durations, no advancement |
| `repeatAfterGap` | 7+ days since last workout | Reset batch to start durations, then repeat |
| `redoIncomplete` | Last workout had incomplete exercises | Redo only those exercises at current durations, no advancement |

### 4.3 Workout Planning Algorithm

```
planWorkout(tracks, dayLogs):
  exercises = activeExercises(tracks)   // all exercises in current batch
  lastWorkout = most recent non-skip DayLog

  if no lastWorkout → return normal(exercises)

  daysSince = days between lastWorkout and today

  if daysSince >= 7:
    resetBatchToStart(tracks)
    return repeatAfterGap(exercises)

  if lastWorkout had incomplete exercises:
    return redoIncomplete(only incomplete exercises)

  if daysSince >= 3:
    return repeatAfterGap(exercises)

  return normal(exercises)
```

### 4.4 Duration Advancement

After a **normal** workout, each completed exercise:
```
exercise.currentDuration = min(
    currentDuration + perSessionIncrement,
    targetMaxDuration
)
```

### 4.5 Batch Advancement

- The current batch is the lowest-numbered batch with any incomplete level
- A level is complete when all its exercises satisfy `isComplete`
- When all levels in a batch are complete, the user advances to the next batch
- When all 16 batches are complete, the program is done

---

## 5. Views

### 5.1 Tab Structure (ContentView)

```
TabView
├── Today (house)        → TodayView
├── Progress (chart.bar) → PTProgressView
├── History (clock)      → HistoryView
└── Settings (gear)      → SettingsView
```

On first launch, `DataSeeder.seedIfNeeded()` creates all tracks/levels/exercises from `PTProtocolConfig`.

### 5.2 Today Tab

Shows the current day's status.

**States:**
1. **Program complete** — trophy icon + congratulations message
2. **Today already logged** — `TodayCompletedCard` showing workout summary or skip reason, wellness score if recorded
3. **Ready to work out** — `CurrentBatchSummary` (e.g., "Mat L2 + Ball L1"), "Start Workout" button, "Log Skip" button

**Skip flow:** confirmation dialog with reasons: PEM, Increased Pain, Other. Creates a `DayLog` with `isSkip = true`.

### 5.3 Workout Session

Full-screen workout interface. Navigation: Today → Start Workout → WorkoutSessionView.

**Flow:**
1. **Wellness prompt overlay** — 0–10 slider with descriptive labels. "Start Workout" proceeds, "Cancel" returns to Today.
2. **Timer view** — large countdown (M:SS), current exercise name, Start/Pause and Skip buttons.
3. **Exercise list** — all exercises with status icons. Tappable when timer is paused to jump to any exercise or re-attempt a completed/skipped one.
4. **Completion** — "Save & Finish" button. If batch advances, shows alert with next batch name.

**Timer behavior:**
- Counts down from exercise's `currentDuration`
- Auto-completes exercise when timer reaches 0
- Skip: if ≤20s remaining → mark completed; if >20s → mark skipped

**Mode banner** (shown at top when applicable):
- Orange: "Repeat workout — it's been a while"
- Yellow: "Redoing incomplete exercises"

**Early exit:** if exercises have been started, confirmation dialog offers Save / Discard / Continue.

### 5.4 Progress Tab

Three sections:

**Timeline** — `ProgressChartView`: a SwiftUI Charts scatter plot.
- X-axis: dates (day numbers, month name on 1st of month)
- Y-axis: batch level 1–16
- 30-day visible window, horizontally scrollable
- Point styles:
  - **Filled circle** (workout): purple (#a478f1) for core batches 0–3, pink (#f24389) for upper batches 4–9, orange (#f0a13a) for lower batches 10–15
  - **Open circle** (skip): cyan (#61cef2) for fatigue/PEM, green (#adfda2) for pain, gray for other

**Current Batch** — each active level expanded with `ExerciseProgressRow` components showing name, current duration, and a progress bar from startDuration to targetMaxDuration.

**All Tracks** — list of 4 tracks with "X/Y levels" completed. Tappable for drill-down.

**Drill-down navigation:**
- Track → `TrackDetailView`: all levels with status icon (green checkmark = complete, blue dotted circle = in progress, gray circle = not started)
- Level → `LevelDetailView`: all exercises with `ExerciseProgressRow`

### 5.5 History Tab

Reverse-chronological list of all `DayLog` entries.

**Each row shows:**
- Status icon (green checkmark or orange X)
- Date
- Summary: "X/Y exercises · Wellness N/10" or "Skipped — reason"

**Features:**
- Swipe to delete any entry
- Tap to view `DayDetailView` (full exercise list with durations, wellness score, delete button)
- Export button (toolbar) → `ShareLink` with CSV file

### 5.6 Settings Tab

**Set Start Point** — pick a batch; all exercises in prior batches are set to their max duration. Confirmation dialog warns this can't be undone.

**Import Data from CSV** — file picker for `.csv`/`.txt` files. Confirmation warns all history will be replaced. On success, updates exercise durations and recreates all DayLogs from the CSV. Shows success or error alert.

---

## 6. CSV Import/Export Format

### 6.1 Format

Header:
```
RecordType,Track,Level,Exercise,CurrentDuration,Date,LogType,SkipReason,DurationUsed,Completed,BatchNumber,WellnessScore
```

**Progress rows** (one per exercise, captures current state):
```
Progress,Mat,0,Supine Marches,180,,,,,,,,
```

**Log rows — workout** (one per exercise in the workout):
```
Log,,,,Supine Marches,2026-03-20,Workout,,170,true,0,2
Log,,,,Bridges,2026-03-20,Workout,,170,true,,
```
BatchNumber and WellnessScore appear only on the first exercise row for each day.

**Log rows — skip:**
```
Log,,,,,2026-03-21,Skip,PEM,,,0,
```

### 6.2 Export

`CSVService.writeExportFile()` generates a complete CSV with:
1. One `Progress` row per exercise in every track/level (current durations)
2. One or more `Log` rows per DayLog (workout exercises or skip entry)

Shared via `ShareLink` from the History toolbar.

### 6.3 Import

`CSVService.parseCSV()` parses the CSV into `ProgressRow` and `LogRow` arrays.

`CSVService.applyImport()`:
1. Updates each exercise's `currentDuration` from matching Progress rows
2. Deletes all existing DayLogs
3. Groups Log rows by date, creates new DayLogs with ExerciseLogs
4. Preserves batchNumber and wellnessScore

Backward-compatible: missing BatchNumber or WellnessScore columns default to 0 / nil.

---

## 7. Data Seeding

`DataSeeder.seedIfNeeded()` runs on first launch (when no Track records exist). It iterates through `PTProtocolConfig.tracks` and creates the full Track → Level → Exercise hierarchy, setting each exercise's timing from the config's resolved values.

The app entry point (`PTTrackerApp`) handles SwiftData schema migration failures by deleting the old store and re-creating it. This is acceptable during development.

---

## 8. File Structure

```
PTTracker/
├── PTTrackerApp.swift
├── ContentView.swift
├── Models/
│   ├── Track.swift
│   ├── Level.swift
│   ├── Exercise.swift
│   ├── DayLog.swift
│   └── ExerciseLog.swift
├── ViewModels/
│   └── WorkoutViewModel.swift
├── Views/
│   ├── TodayView.swift
│   ├── WorkoutSessionView.swift
│   ├── PTProgressView.swift
│   ├── HistoryView.swift
│   ├── SettingsView.swift
│   ├── TrackDetailView.swift
│   ├── LevelDetailView.swift
│   ├── DayDetailView.swift
│   └── Components/
│       ├── CurrentBatchSummary.swift
│       ├── TodayCompletedCard.swift
│       ├── ExerciseProgressRow.swift
│       └── ProgressChartView.swift
├── Services/
│   ├── PTProtocolConfig.swift
│   ├── ProgressionEngine.swift
│   ├── CSVService.swift
│   └── DataSeeder.swift
├── Utilities/
│   └── DateExtensions.swift
└── Preview Content/
    └── PreviewSampleData.swift

PTTrackerTests/
├── PTTrackerTests.swift
└── CSVServiceTests.swift
```
