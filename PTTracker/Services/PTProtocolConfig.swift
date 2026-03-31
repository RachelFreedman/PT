import Foundation

enum PTProtocolConfig {

    // MARK: - Default Timing

    /// Default starting duration for each exercise (seconds) — "one and a half minutes"
    static let startDuration: Int = 90

    /// Default maximum duration — exercise is "complete" at this point (seconds) — "three minutes"
    static let maxDuration: Int = 180

    /// Default duration added per successful workout (seconds) — "add ten seconds per day"
    static let durationIncrement: Int = 10

    // MARK: - Tracks & Exercises

    struct ExerciseDefinition {
        let name: String
        /// Override the default start duration for this exercise (seconds).
        let startDuration: Int?
        /// Override the default max duration for this exercise (seconds).
        let maxDuration: Int?
        /// Override the default increment for this exercise (seconds).
        let durationIncrement: Int?

        init(
            name: String,
            startDuration: Int? = nil,
            maxDuration: Int? = nil,
            durationIncrement: Int? = nil
        ) {
            self.name = name
            self.startDuration = startDuration
            self.maxDuration = maxDuration
            self.durationIncrement = durationIncrement
        }

        var resolvedStartDuration: Int { startDuration ?? PTProtocolConfig.startDuration }
        var resolvedMaxDuration: Int { maxDuration ?? PTProtocolConfig.maxDuration }
        var resolvedDurationIncrement: Int { durationIncrement ?? PTProtocolConfig.durationIncrement }
    }

    /// Shorthand for a carryover exercise already at 3 minutes (180s). Still shown in
    /// workouts as a reminder, but starts complete so it doesn't block progression.
    private static func carryover(_ name: String) -> ExerciseDefinition {
        ExerciseDefinition(name: name, startDuration: 180, maxDuration: 180)
    }

    /// Shorthand for a fixed-duration exercise that never progresses (e.g., TMJ Isometrics at 60s).
    private static func fixed(_ name: String, duration: Int) -> ExerciseDefinition {
        ExerciseDefinition(name: name, startDuration: duration, maxDuration: duration)
    }

    struct LevelDefinition {
        let exercises: [ExerciseDefinition]
    }

    struct TrackDefinition {
        let name: String
        let levels: [LevelDefinition]
    }

    // ===================================================================
    // Exercise lists are taken from the Muldowney Exercise Protocol
    // appendices (Appendix A, B, C). Alternate/modified positions omitted.
    //
    // Timing key (book → seconds):
    //   "one and a half to three minutes" = 90s start, 180s max, +10s/day
    //   "one to three minutes"            = 60s start, 180s max, +10s/day
    //   "four to eight minutes"           = 240s start, 480s max, +20s/day
    //   "For Three Minutes"               = carryover, already at 180s
    //   "One Minute Each Way"             = fixed at 60s, no progression
    // ===================================================================

    static let tracks: [TrackDefinition] = [

        // ---------------------------------------------------------------
        // SIJ & Lumbar Spine — Mat Exercises (stabilize the ilia)
        // ---------------------------------------------------------------
        TrackDefinition(name: "Mat", levels: [
            // Level 1 Mat — 1.5 to 3 minutes
            LevelDefinition(exercises: [
                ExerciseDefinition(name: "Supine Marches"),
                ExerciseDefinition(name: "Prone Alternating Hip Extension"),
                ExerciseDefinition(name: "Bridges"),
                ExerciseDefinition(name: "Ball Squeezes"),
                ExerciseDefinition(name: "Clam With Yellow Tubing"),
            ]),
            // Level 2 Mat — 1.5 to 3 minutes
            LevelDefinition(exercises: [
                ExerciseDefinition(name: "Supine Kickouts"),
                ExerciseDefinition(name: "Prone Swimmer"),
                ExerciseDefinition(name: "Bridges With Ball Squeezes"),
                carryover("Ball Squeezes"),                                 // "For Three Minutes"
                ExerciseDefinition(name: "Clam With Green Tubing"),
            ]),
            // Level 3 Mat — 1 to 3 minutes
            // Note: Clam progresses Blue→Black sequentially (not simultaneous).
            // Black replaces Blue after Blue reaches 3 min, but for tracking we
            // only list Blue here. The final home program uses Black.
            LevelDefinition(exercises: [
                ExerciseDefinition(name: "Dying Bug", startDuration: 60),
                carryover("Prone Swimmer"),                                 // "For Three Minutes"
                ExerciseDefinition(name: "Bridges With Kickouts", startDuration: 60),
                ExerciseDefinition(name: "Clam With Blue Tubing", startDuration: 60),
                carryover("Ball Squeezes"),                                 // "For Three Minutes"
            ]),
        ]),

        // ---------------------------------------------------------------
        // SIJ & Lumbar Spine — Ball Exercises (stabilize the sacrum)
        // ---------------------------------------------------------------
        TrackDefinition(name: "Ball", levels: [
            // Level 1 Ball — 1.5 to 3 minutes
            LevelDefinition(exercises: [
                ExerciseDefinition(name: "Seated Alternating Heel Ups"),
                ExerciseDefinition(name: "Bridging With Legs On Ball"),
                ExerciseDefinition(name: "Ball Multifidus"),
            ]),
            // Level 2 Ball — 1.5 to 3 minutes
            LevelDefinition(exercises: [
                ExerciseDefinition(name: "Seated On Ball Marches"),
                ExerciseDefinition(name: "Roll Out On The Ball"),
                ExerciseDefinition(name: "Bridging On Ball Arms Across Chest"),
                ExerciseDefinition(name: "Hug Ball Kickout Toe Touching"),
            ]),
            // Level 3 Ball — 1 to 3 minutes
            LevelDefinition(exercises: [
                ExerciseDefinition(name: "Seated On Ball Kickouts", startDuration: 60),
                ExerciseDefinition(name: "Ball Roll Outs With Heel Ups", startDuration: 60),
                carryover("Bridging On Ball Arms Across Chest"),            // "For Three Minutes"
                ExerciseDefinition(name: "Hugging The Ball With Kickouts", startDuration: 60),
            ]),
        ]),

        // ---------------------------------------------------------------
        // Neck, Mid Back & Upper Extremity
        // ---------------------------------------------------------------
        TrackDefinition(name: "Neck", levels: [
            // Level 1 Neck — 1 to 3 minutes (introduced alongside Ball L3)
            LevelDefinition(exercises: [
                ExerciseDefinition(name: "Supine Chin Tucks", startDuration: 60),
                ExerciseDefinition(name: "Supine Shoulder Extensions", startDuration: 60),
            ]),
            // Level 2 Neck — 1.5 to 3 minutes (except Isometric Neck: 4→8 min)
            LevelDefinition(exercises: [
                ExerciseDefinition(name: "Isometric Neck", startDuration: 240, maxDuration: 480, durationIncrement: 20),
                ExerciseDefinition(name: "T/Y/I's With No Weights"),
                ExerciseDefinition(name: "Shoulder Internal Rotation With No Weights"),
                ExerciseDefinition(name: "Shoulder External Rotation With No Weights"),
                ExerciseDefinition(name: "Full Can With No Weights"),
                ExerciseDefinition(name: "Chicken Dance"),
                ExerciseDefinition(name: "Hand Ball Squeezes"),
                ExerciseDefinition(name: "Four Way Wrist With No Weights"),
            ]),
            // Level 3 Neck — 1.5 to 3 minutes
            LevelDefinition(exercises: [
                ExerciseDefinition(name: "Prone Chin Tucks"),
                ExerciseDefinition(name: "T/Y/I's With 1 lb"),
                ExerciseDefinition(name: "Shoulder Internal Rotation With Yellow Tubing"),
                ExerciseDefinition(name: "Shoulder External Rotation With Yellow Tubing"),
                ExerciseDefinition(name: "Full Can With 1 lb"),
                ExerciseDefinition(name: "Shoulder Abduction With No Weight"),
                carryover("Hand Ball Squeezes"),                            // "For Three Minutes (Tues/Fri)"
                ExerciseDefinition(name: "Four Way Wrist With 1 lb"),
                ExerciseDefinition(name: "Bicep Curl With 1 lb"),
                ExerciseDefinition(name: "Triceps Push Downs With Yellow Tubing"),
            ]),
            // Level 4 Neck — 1.5 to 3 minutes
            LevelDefinition(exercises: [
                ExerciseDefinition(name: "T/Y/I's With Chin Tucks With 1 lb"),
                ExerciseDefinition(name: "Shoulder Internal Rotation With Red Tubing"),
                ExerciseDefinition(name: "Shoulder External Rotation With Red Tubing"),
                ExerciseDefinition(name: "Full Can With 2 lbs"),
                ExerciseDefinition(name: "Shoulder Abduction With 1 lb"),
                carryover("Hand Ball Squeezes"),                            // "For Three Minutes (Tues/Fri)"
                ExerciseDefinition(name: "Four Way Wrist With 2 lbs"),
                ExerciseDefinition(name: "Bicep Curl With 2 lbs"),
                ExerciseDefinition(name: "Triceps Push Downs With Red Tubing"),
            ]),
            // Level 5 Neck — 1.5 to 3 minutes
            LevelDefinition(exercises: [
                ExerciseDefinition(name: "T/Y/I's With Chin Tucks With 2 lbs"),
                ExerciseDefinition(name: "Shoulder Internal Rotation With Green Tubing"),
                ExerciseDefinition(name: "Shoulder External Rotation With Green Tubing"),
                ExerciseDefinition(name: "Full Can With 3 lbs"),
                ExerciseDefinition(name: "Shoulder Abduction With 2 lbs"),
                carryover("Hand Ball Squeezes"),                            // "For Three Minutes (Tues/Fri)"
                ExerciseDefinition(name: "Four Way Wrist With 3 lbs"),
                ExerciseDefinition(name: "Bicep Curl With 3 lbs"),
                ExerciseDefinition(name: "Triceps Push Downs With Green Tubing"),
                ExerciseDefinition(name: "Criss-Cross Eyes"),
                ExerciseDefinition(name: "Eyebrow Raises"),
                ExerciseDefinition(name: "Ear Wiggles"),
                fixed("TMJ Isometrics", duration: 60),                     // "One Minute Each Way" — never progresses
            ]),
            // Level 6 Neck — 1.5 to 3 minutes
            LevelDefinition(exercises: [
                ExerciseDefinition(name: "T/Y/I's With Chin Tucks With 3 lbs"),
                ExerciseDefinition(name: "Shoulder Internal Rotation With Blue Tubing"),
                ExerciseDefinition(name: "Shoulder External Rotation With Blue Tubing"),
                ExerciseDefinition(name: "Full Can With 4 lbs"),
                ExerciseDefinition(name: "Shoulder Abduction With 3 lbs"),
                carryover("Hand Ball Squeezes"),                            // "For Three Minutes (Tues/Fri)"
                carryover("Four Way Wrist With 3 lbs"),                     // "For Three Minutes (Tues/Fri)"
                ExerciseDefinition(name: "Bicep Curl With 4 lbs"),
                ExerciseDefinition(name: "Triceps Push Downs With Blue Tubing"),
                carryover("Criss-Cross Eyes"),                              // "For Three Minutes (Tues/Fri)"
                carryover("Eyebrow Raises"),                                // "For Three Minutes (Tues/Fri)"
                carryover("Ear Wiggles"),                                   // "For Three Minutes (Tues/Fri)"
                fixed("TMJ Isometrics", duration: 60),                      // "One Minute Each Way (Tues/Fri)"
            ]),
            // Level 7 Neck — 1 to 3 minutes
            LevelDefinition(exercises: [
                carryover("T/Y/I's With Chin Tucks With 3 lbs"),            // "For Three Minutes (Tues/Fri)"
                ExerciseDefinition(name: "Shoulder Internal Rotation With Black Tubing", startDuration: 60),
                ExerciseDefinition(name: "Shoulder External Rotation With Black Tubing", startDuration: 60),
                ExerciseDefinition(name: "Full Can With 5 lbs", startDuration: 60),
                ExerciseDefinition(name: "Shoulder Abduction With 4 lbs", startDuration: 60),
                carryover("Hand Ball Squeezes"),                            // "For Three Minutes (Tues/Fri)"
                carryover("Four Way Wrist With 3 lbs"),                     // "For Three Minutes (Tues/Fri)"
                ExerciseDefinition(name: "Bicep Curl With 5 lbs", startDuration: 60),
                ExerciseDefinition(name: "Triceps Push Downs With Black Tubing", startDuration: 60),
                carryover("Criss-Cross Eyes"),                              // "For Three Minutes (Tues/Fri)"
                carryover("Eyebrow Raises"),                                // "For Three Minutes (Tues/Fri)"
                carryover("Ear Wiggles"),                                   // "For Three Minutes (Tues/Fri)"
                fixed("TMJ Isometrics", duration: 60),                      // "One Minute Each Way (Tues/Fri)"
            ]),
        ]),

        // ---------------------------------------------------------------
        // Lower Extremity
        // NOTE: These exercises use repetitions (10→26 reps/laps), not
        // timed holds. The app's time-based progression does not apply
        // to most of these. Some balance exercises are timed (1.5→3 min).
        // ---------------------------------------------------------------
        TrackDefinition(name: "Lower Extremity", levels: [
            // Level 1 LE (introduced when Neck L7 begins)
            LevelDefinition(exercises: [
                ExerciseDefinition(name: "Side Stepping"),
                ExerciseDefinition(name: "Walk Forward And Backwards"),
                ExerciseDefinition(name: "Hamstring Curl"),
                ExerciseDefinition(name: "Heel And Toe Raises"),
            ]),
            // Level 2 LE
            LevelDefinition(exercises: [
                ExerciseDefinition(name: "Side Stepping With Yellow Band"),
                ExerciseDefinition(name: "Walk Forward And Backwards With Yellow Band"),
                ExerciseDefinition(name: "Hamstring Curl With Yellow Band"),
                ExerciseDefinition(name: "Heel And Toe Raises"),             // carryover, 26→50 reps
                ExerciseDefinition(name: "Quarter Squats"),
            ]),
            // Level 3 LE
            LevelDefinition(exercises: [
                ExerciseDefinition(name: "Side Stepping With Green Band"),
                ExerciseDefinition(name: "Walk Forward And Backwards With Green Band"),
                ExerciseDefinition(name: "Hamstring Curl With Green Band"),
                ExerciseDefinition(name: "Single Leg Heel And Toe Raises"),
                ExerciseDefinition(name: "Partial Lunges"),
                ExerciseDefinition(name: "Stand Feet Together On Floor"),
            ]),
            // Level 4 LE
            LevelDefinition(exercises: [
                ExerciseDefinition(name: "Side Stepping With Blue Band"),
                ExerciseDefinition(name: "Walk Forward And Backwards With Blue Band"),
                ExerciseDefinition(name: "Hamstring Curl With Blue Band"),
                ExerciseDefinition(name: "Single Leg Heel And Toe Raises"),  // carryover, 26→50 reps
                ExerciseDefinition(name: "Deeper Lunges"),
                ExerciseDefinition(name: "Step Ups Forward On 4-Inch Step"),
                ExerciseDefinition(name: "Step Ups To Side On 4-Inch Step"),
                ExerciseDefinition(name: "Standing Feet Together Eyes Closed"),
                ExerciseDefinition(name: "Stand On Pillow Feet Together Eyes Open"),
            ]),
            // Level 5 LE
            LevelDefinition(exercises: [
                ExerciseDefinition(name: "Side Stepping With Black Band"),
                ExerciseDefinition(name: "Walk Forward And Backwards With Black Band"),
                ExerciseDefinition(name: "Hamstring Curl With Black Band"),
                ExerciseDefinition(name: "Single Leg Heel And Toe Raises"),  // carryover, 50 reps
                ExerciseDefinition(name: "Deeper Lunges"),                   // carryover, 26 reps
                ExerciseDefinition(name: "Step Ups Forward On 8-Inch Step"),
                ExerciseDefinition(name: "Step Ups To Side On 8-Inch Step"),
                ExerciseDefinition(name: "Standing On Pillow Feet Together Eyes Closed"),
                ExerciseDefinition(name: "Single Leg Stance On Floor Eyes Open"),
                ExerciseDefinition(name: "Recumbent Bike"),
            ]),
            // Level 6 LE
            LevelDefinition(exercises: [
                ExerciseDefinition(name: "Side Stepping With Black Band"),           // carryover
                ExerciseDefinition(name: "Walk Forward And Backwards With Black Band"), // carryover
                ExerciseDefinition(name: "Hamstring Curl With Black Band"),          // carryover
                ExerciseDefinition(name: "Single Leg Heel And Toe Raises"),          // carryover
                ExerciseDefinition(name: "Deep Lunges"),                             // carryover
                ExerciseDefinition(name: "Step Lowering Forward On 4-Inch Step"),
                ExerciseDefinition(name: "Step Lowering To Side On 4-Inch Step"),
                ExerciseDefinition(name: "Single Leg Stance On Floor Eyes Closed"),
                ExerciseDefinition(name: "Single Leg Stance On Pillow Eyes Open"),
                ExerciseDefinition(name: "Standing Feet Together On Pillow Eyes Closed"), // carryover
                ExerciseDefinition(name: "Recumbent Bike"),                          // carryover
            ]),
            // Level 7 LE
            LevelDefinition(exercises: [
                ExerciseDefinition(name: "Side Stepping With Black Band"),           // carryover
                ExerciseDefinition(name: "Walk Forward And Backwards With Black Band"), // carryover
                ExerciseDefinition(name: "Hamstring Curl With Black Band"),          // carryover
                ExerciseDefinition(name: "Single Leg Heel And Toe Raises"),          // carryover
                ExerciseDefinition(name: "Deep Lunges"),                             // carryover
                ExerciseDefinition(name: "Step Lowering Forward On 8-Inch Step"),
                ExerciseDefinition(name: "Step Lowering To Side On 8-Inch Step"),
                ExerciseDefinition(name: "Single Leg Stance On Floor Eyes Closed"),  // carryover
                ExerciseDefinition(name: "Single Leg Stance On Pillow Eyes Open"),   // carryover
                ExerciseDefinition(name: "Standing Feet Together On Pillow Eyes Closed"),
                ExerciseDefinition(name: "Recumbent Bike"),                          // carryover
            ]),
        ]),
    ]

    // MARK: - Batch Schedule

    struct BatchEntry {
        let trackName: String
        let levelNumber: Int
    }

    /// Staggered batch schedule per the Muldowney Protocol:
    ///
    /// SIJ & Lumbar Spine progression:
    ///   Batch  0: Mat L1
    ///   Batch  1: Mat L2 + Ball L1  (Ball introduced when Mat L2 begins)
    ///   Batch  2: Mat L3 + Ball L2
    ///   Batch  3: Ball L3 + Neck L1 (Neck introduced when Ball L3 begins)
    ///
    /// Neck, Mid Back & Upper Extremity progression:
    ///   Batch  4: Neck L2
    ///   Batch  5: Neck L3
    ///   Batch  6: Neck L4
    ///   Batch  7: Neck L5
    ///   Batch  8: Neck L6
    ///   Batch  9: Neck L7 + LE L1   (LE introduced when Neck L7 begins)
    ///
    /// Lower Extremity progression:
    ///   Batch 10: LE L2
    ///   Batch 11: LE L3
    ///   Batch 12: LE L4
    ///   Batch 13: LE L5
    ///   Batch 14: LE L6
    ///   Batch 15: LE L7
    static let batches: [[BatchEntry]] = [
        // SIJ & Lumbar Spine
        [BatchEntry(trackName: "Mat", levelNumber: 0)],
        [BatchEntry(trackName: "Mat", levelNumber: 1), BatchEntry(trackName: "Ball", levelNumber: 0)],
        [BatchEntry(trackName: "Mat", levelNumber: 2), BatchEntry(trackName: "Ball", levelNumber: 1)],
        [BatchEntry(trackName: "Ball", levelNumber: 2), BatchEntry(trackName: "Neck", levelNumber: 0)],
        // Neck, Mid Back & Upper Extremity
        [BatchEntry(trackName: "Neck", levelNumber: 1)],
        [BatchEntry(trackName: "Neck", levelNumber: 2)],
        [BatchEntry(trackName: "Neck", levelNumber: 3)],
        [BatchEntry(trackName: "Neck", levelNumber: 4)],
        [BatchEntry(trackName: "Neck", levelNumber: 5)],
        [BatchEntry(trackName: "Neck", levelNumber: 6), BatchEntry(trackName: "Lower Extremity", levelNumber: 0)],
        // Lower Extremity
        [BatchEntry(trackName: "Lower Extremity", levelNumber: 1)],
        [BatchEntry(trackName: "Lower Extremity", levelNumber: 2)],
        [BatchEntry(trackName: "Lower Extremity", levelNumber: 3)],
        [BatchEntry(trackName: "Lower Extremity", levelNumber: 4)],
        [BatchEntry(trackName: "Lower Extremity", levelNumber: 5)],
        [BatchEntry(trackName: "Lower Extremity", levelNumber: 6)],
    ]
}
