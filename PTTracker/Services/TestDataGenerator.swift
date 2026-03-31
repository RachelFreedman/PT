import Foundation

/// Generates a test CSV with ~50 days of realistic workout history progressing
/// through batches 0–3, with skips for fatigue, pain, and other reasons,
/// plus varied wellness scores. Uses fixed absolute dates for reproducibility.
enum TestDataGenerator {

    static func generateTestCSV() -> String {
        var csv = "RecordType,Track,Level,Exercise,CurrentDuration,Date,LogType,SkipReason,DurationUsed,Completed,BatchNumber,WellnessScore\n"

        // --- Progress rows: user is partway through Batch 2 (Mat L3 + Ball L2) ---

        // Mat L0: fully complete
        for name in ["Supine Marches", "Prone Alternating Hip Extension", "Bridges", "Ball Squeezes", "Clam With Yellow Tubing"] {
            csv += "Progress,Mat,0,\(name),180,,,,,,,,\n"
        }

        // Mat L1: fully complete
        for name in ["Supine Kickouts", "Prone Swimmer", "Bridges With Ball Squeezes", "Clam With Green Tubing"] {
            csv += "Progress,Mat,1,\(name),180,,,,,,,,\n"
        }
        csv += "Progress,Mat,1,Ball Squeezes,180,,,,,,,,\n"

        // Mat L2: in progress
        for (name, dur) in [("Dying Bug", 120), ("Bridges With Kickouts", 110), ("Clam With Blue Tubing", 100)] as [(String, Int)] {
            csv += "Progress,Mat,2,\(name),\(dur),,,,,,,,\n"
        }
        csv += "Progress,Mat,2,Prone Swimmer,180,,,,,,,,\n"
        csv += "Progress,Mat,2,Ball Squeezes,180,,,,,,,,\n"

        // Ball L0: fully complete
        for name in ["Seated Alternating Heel Ups", "Bridging With Legs On Ball", "Ball Multifidus"] {
            csv += "Progress,Ball,0,\(name),180,,,,,,,,\n"
        }

        // Ball L1: in progress
        for (name, dur) in [("Seated On Ball Marches", 130), ("Roll Out On The Ball", 120), ("Bridging On Ball Arms Across Chest", 110), ("Hug Ball Kickout Toe Touching", 120)] as [(String, Int)] {
            csv += "Progress,Ball,1,\(name),\(dur),,,,,,,,\n"
        }

        // Ball L2: still at start
        for name in ["Seated On Ball Kickouts", "Ball Roll Outs With Heel Ups", "Hugging The Ball With Kickouts"] {
            csv += "Progress,Ball,2,\(name),60,,,,,,,,\n"
        }
        csv += "Progress,Ball,2,Bridging On Ball Arms Across Chest,180,,,,,,,,\n"

        // Neck L0: still at start
        for name in ["Supine Chin Tucks", "Supine Shoulder Extensions"] {
            csv += "Progress,Neck,0,\(name),60,,,,,,,,\n"
        }

        // --- Log rows with absolute dates ---

        let matL0Ex = ["Supine Marches", "Prone Alternating Hip Extension", "Bridges", "Ball Squeezes", "Clam With Yellow Tubing"]

        // Batch 0 (Mat L1): Feb 9–18, progressing 90→180
        let batch0Dates = ["2026-02-09", "2026-02-10", "2026-02-11", "2026-02-12", "2026-02-13",
                           "2026-02-14", "2026-02-15", "2026-02-16", "2026-02-17", "2026-02-18"]
        let batch0Wellness = [1, 2, 1, 3, 2, 1, 2, 1, 2, 1]
        for (i, date) in batch0Dates.enumerated() {
            let dur = min(90 + i * 10, 180)
            csv += workout(date: date, batch: 0, exercises: matL0Ex, duration: dur, wellness: batch0Wellness[i])
        }

        // Feb 19: skip (fatigue)
        csv += "Log,,,,,2026-02-19,Skip,PEM,,,0,\n"

        // Batch 0 completion: Feb 20–22
        for date in ["2026-02-20", "2026-02-21", "2026-02-22"] {
            csv += workout(date: date, batch: 0, exercises: matL0Ex, duration: 180, wellness: 1)
        }

        // Batch 1 (Mat L2 + Ball L1): Feb 23–Mar 4
        let batch1Ex = ["Supine Kickouts", "Prone Swimmer", "Bridges With Ball Squeezes", "Ball Squeezes", "Clam With Green Tubing",
                        "Seated Alternating Heel Ups", "Bridging With Legs On Ball", "Ball Multifidus"]
        let batch1Dates = ["2026-02-23", "2026-02-24", "2026-02-25", "2026-02-26", "2026-02-27",
                           "2026-02-28", "2026-03-01", "2026-03-02", "2026-03-03", "2026-03-04"]
        let batch1Wellness = [2, 3, 2, 4, 3, 2, 2, 3, 2, 2]
        for (i, date) in batch1Dates.enumerated() {
            let dur = min(90 + i * 10, 180)
            csv += workout(date: date, batch: 1, exercises: batch1Ex, duration: dur, wellness: batch1Wellness[i])
        }

        // Mar 5–6: skip (pain)
        csv += "Log,,,,,2026-03-05,Skip,Increased Pain,,,1,\n"
        csv += "Log,,,,,2026-03-06,Skip,Increased Pain,,,1,\n"

        // Batch 1 continued: Mar 7–11
        for date in ["2026-03-07", "2026-03-08", "2026-03-09", "2026-03-10", "2026-03-11"] {
            csv += workout(date: date, batch: 1, exercises: batch1Ex, duration: 180, wellness: 2)
        }

        // Mar 12: skip (fatigue)
        csv += "Log,,,,,2026-03-12,Skip,PEM,,,1,\n"

        // Batch 1 finish: Mar 13–15
        for date in ["2026-03-13", "2026-03-14", "2026-03-15"] {
            csv += workout(date: date, batch: 1, exercises: batch1Ex, duration: 180, wellness: 1)
        }

        // Batch 2 (Mat L3 + Ball L2): Mar 16–22
        let batch2Ex = ["Dying Bug", "Prone Swimmer", "Bridges With Kickouts", "Clam With Blue Tubing", "Ball Squeezes",
                        "Seated On Ball Marches", "Roll Out On The Ball", "Bridging On Ball Arms Across Chest", "Hug Ball Kickout Toe Touching"]
        let batch2Dates = ["2026-03-16", "2026-03-17", "2026-03-18", "2026-03-19", "2026-03-20", "2026-03-21", "2026-03-22"]
        let batch2Wellness = [3, 2, 4, 3, 2, 5, 3]
        for (i, date) in batch2Dates.enumerated() {
            let dur = min(60 + i * 10, 180)
            csv += workout(date: date, batch: 2, exercises: batch2Ex, duration: dur, wellness: batch2Wellness[i])
        }

        // Mar 23: skip (other)
        csv += "Log,,,,,2026-03-23,Skip,Travel,,,2,\n"

        // Mar 24: skip (fatigue)
        csv += "Log,,,,,2026-03-24,Skip,PEM,,,2,\n"

        // Batch 2 continued: Mar 25–27
        let batch2Dates2 = ["2026-03-25", "2026-03-26", "2026-03-27"]
        let batch2Wellness2 = [4, 3, 3]
        for (i, date) in batch2Dates2.enumerated() {
            let dur = min(60 + (7 + i) * 10, 180)
            csv += workout(date: date, batch: 2, exercises: batch2Ex, duration: dur, wellness: batch2Wellness2[i])
        }

        // Mar 28: partial workout (first 6 completed, last 3 not)
        for (i, name) in batch2Ex.enumerated() {
            let completed = i < 6
            let b = i == 0 ? "2" : ""
            let w = i == 0 ? "5" : ""
            csv += "Log,,,,\(name),2026-03-28,Workout,,130,\(completed),\(b),\(w)\n"
        }

        // Mar 29: redo incomplete exercises
        for (i, name) in batch2Ex.suffix(3).enumerated() {
            let b = i == 0 ? "2" : ""
            let w = i == 0 ? "3" : ""
            csv += "Log,,,,\(name),2026-03-29,Workout,,130,true,\(b),\(w)\n"
        }

        return csv
    }

    private static func workout(date: String, batch: Int, exercises: [String], duration: Int, wellness: Int) -> String {
        var result = ""
        for (i, name) in exercises.enumerated() {
            let b = i == 0 ? "\(batch)" : ""
            let w = i == 0 ? "\(wellness)" : ""
            result += "Log,,,,\(name),\(date),Workout,,\(duration),true,\(b),\(w)\n"
        }
        return result
    }
}
