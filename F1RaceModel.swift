import Foundation

struct F1Race: Codable {
    let id: Int
    let round: Int
    let name: String
    let location: String
    let datetime_fp1: Int64?
    let datetime_fp2: Int64?
    let datetime_fp3: Int64?
    let datetime_sprint: Int64?
    let datetime_qualifying: Int64?
    let datetime_race: Int64?
    let first_place: String?
    let second_place: String?
    let third_place: String?
    let shortname: String
    let datetime_fp1_end: Int64?
    let datetime_fp2_end: Int64?
    let datetime_fp3_end: Int64?
    let datetime_sprint_end: Int64?
    let datetime_qualifying_end: Int64?
    let datetime_race_end: Int64?
    
    struct Session {
        let name: String
        let timestamp: Int64
    }
    
    func nextUpcomingSession() -> Session? {
        let now = Int64(Date().timeIntervalSince1970)
        let sessions: [(String, Int64?)] = [
            ("FP1", datetime_fp1),
            ("FP2", datetime_fp2),
            ("FP3", datetime_fp3),
            ("Sprint", datetime_sprint),
            ("Qualifying", datetime_qualifying),
            ("Race", datetime_race)
        ]
        
        return sessions
            .compactMap { name, timestamp -> Session? in
                guard let timestamp = timestamp else { return nil }
                return Session(name: name, timestamp: timestamp)
            }
            .filter { $0.timestamp > now }
            .min { $0.timestamp < $1.timestamp }
    }
} 