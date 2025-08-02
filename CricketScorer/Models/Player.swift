import Foundation
import FirebaseFirestore

enum BattingHand: String, CaseIterable, Codable {
    case left = "left"
    case right = "right"
    
    var displayName: String {
        switch self {
        case .left: return "Left-handed"
        case .right: return "Right-handed"
        }
    }
}

enum BowlingHand: String, CaseIterable, Codable {
    case left = "left"
    case right = "right"
    
    var displayName: String {
        switch self {
        case .left: return "Left-arm"
        case .right: return "Right-arm"
        }
    }
}

enum BowlingStyle: String, CaseIterable, Codable {
    case fast = "fast"
    case medium = "medium"
    case spin = "spin"
    case offSpin = "off_spin"
    case legSpin = "leg_spin"
    
    var displayName: String {
        switch self {
        case .fast: return "Fast"
        case .medium: return "Medium"
        case .spin: return "Spin"
        case .offSpin: return "Off Spin"
        case .legSpin: return "Leg Spin"
        }
    }
}

struct Player: Identifiable, Codable {
    @DocumentID var id: String?
    let poolId: String
    let name: String
    let battingHand: BattingHand?
    let bowlingHand: BowlingHand?
    let bowlingStyle: BowlingStyle?
    let linkedUserId: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "player_id"
        case poolId = "pool_id"
        case name
        case battingHand = "batting_hand"
        case bowlingHand = "bowling_hand"
        case bowlingStyle = "bowling_style"
        case linkedUserId = "linked_user_id"
        case createdAt = "created_at"
    }
}

struct PlayerStats: Codable {
    let playerId: String
    let matches: Int
    let innings: Int
    let runs: Int
    let ballsFaced: Int
    let wickets: Int
    let oversBowled: Double
    let runsConceded: Int
    let fours: Int
    let sixes: Int
    let lastUpdated: Date
    
    enum CodingKeys: String, CodingKey {
        case playerId = "player_id"
        case matches
        case innings
        case runs
        case ballsFaced = "balls_faced"
        case wickets
        case oversBowled = "overs_bowled"
        case runsConceded = "runs_conceded"
        case fours
        case sixes
        case lastUpdated = "last_updated"
    }
    
    var battingAverage: Double {
        guard innings > 0 else { return 0.0 }
        return Double(runs) / Double(innings)
    }
    
    var strikeRate: Double {
        guard ballsFaced > 0 else { return 0.0 }
        return (Double(runs) / Double(ballsFaced)) * 100
    }
    
    var bowlingAverage: Double {
        guard wickets > 0 else { return 0.0 }
        return Double(runsConceded) / Double(wickets)
    }
    
    var economy: Double {
        guard oversBowled > 0 else { return 0.0 }
        return Double(runsConceded) / oversBowled
    }
}