import Foundation
import FirebaseFirestore

enum MatchStatus: String, CaseIterable, Codable {
    case ongoing = "ongoing"
    case completed = "completed"
    case abandoned = "abandoned"
}

enum Team: String, CaseIterable, Codable {
    case A = "A"
    case B = "B"
    
    var opposite: Team {
        self == .A ? .B : .A
    }
}

enum TossDecision: String, CaseIterable, Codable {
    case bat = "bat"
    case field = "field"
}

struct Match: Identifiable, Codable {
    @DocumentID var id: String?
    let poolId: String
    let createdBy: String
    let teamAName: String
    let teamBName: String
    let oversPerInnings: Int
    let twoInnings: Bool
    let wideNoBallRuns: Bool
    let tossWinner: Team?
    let tossDecision: TossDecision?
    let status: MatchStatus
    let createdAt: Date
    let currentScorerId: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "match_id"
        case poolId = "pool_id"
        case createdBy = "created_by"
        case teamAName = "team_a_name"
        case teamBName = "team_b_name"
        case oversPerInnings = "overs_per_innings"
        case twoInnings = "two_innings"
        case wideNoBallRuns = "wide_no_ball_runs"
        case tossWinner = "toss_winner"
        case tossDecision = "toss_decision"
        case status
        case createdAt = "created_at"
        case currentScorerId = "current_scorer_id"
    }
}

struct MatchTeam: Identifiable, Codable {
    @DocumentID var id: String?
    let matchId: String
    let team: Team
    let playerId: String
    let isCaptain: Bool
    let isCommonPlayer: Bool
    let battingOrder: Int?
    
    enum CodingKeys: String, CodingKey {
        case id = "match_team_id"
        case matchId = "match_id"
        case team
        case playerId = "player_id"
        case isCaptain = "is_captain"
        case isCommonPlayer = "is_common_player"
        case battingOrder = "batting_order"
    }
}

enum InningsStatus: String, CaseIterable, Codable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed = "completed"
    case allOut = "all_out"
    case targetChased = "target_chased"
}

struct Innings: Identifiable, Codable {
    @DocumentID var id: String?
    let matchId: String
    let team: Team
    let inningsNumber: Int
    let runs: Int
    let wickets: Int
    let oversFaced: Double
    let status: InningsStatus
    let target: Int?
    let currentBatter1Id: String?
    let currentBatter2Id: String?
    let currentBowlerId: String?
    let currentOver: Int
    let currentBall: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "innings_id"
        case matchId = "match_id"
        case team
        case inningsNumber = "innings_number"
        case runs
        case wickets
        case oversFaced = "overs_faced"
        case status
        case target
        case currentBatter1Id = "current_batter1_id"
        case currentBatter2Id = "current_batter2_id"
        case currentBowlerId = "current_bowler_id"
        case currentOver = "current_over"
        case currentBall = "current_ball"
    }
    
    var isComplete: Bool {
        status == .completed || status == .allOut || status == .targetChased
    }
    
    var displayScore: String {
        "\(runs)/\(wickets)"
    }
    
    var displayOvers: String {
        let completeOvers = Int(oversFaced)
        let balls = Int((oversFaced - Double(completeOvers)) * 6)
        return balls > 0 ? "\(completeOvers).\(balls)" : "\(completeOvers)"
    }
}

enum WicketType: String, CaseIterable, Codable {
    case bowled = "bowled"
    case caught = "caught"
    case lbw = "lbw"
    case runOut = "run_out"
    case stumped = "stumped"
    case hitWicket = "hit_wicket"
    case retired = "retired"
    case timedOut = "timed_out"
    
    var displayName: String {
        switch self {
        case .bowled: return "Bowled"
        case .caught: return "Caught"
        case .lbw: return "LBW"
        case .runOut: return "Run Out"
        case .stumped: return "Stumped"
        case .hitWicket: return "Hit Wicket"
        case .retired: return "Retired"
        case .timedOut: return "Timed Out"
        }
    }
    
    var creditsToKeeper: Bool {
        self == .stumped
    }
    
    var creditsToBowler: Bool {
        [.bowled, .caught, .lbw, .hitWicket].contains(self)
    }
}

struct BallEvent: Identifiable, Codable {
    @DocumentID var id: String?
    let inningsId: String
    let overNumber: Int
    let ballNumber: Int
    let batterId: String
    let bowlerId: String
    let runsScored: Int
    let isWide: Bool
    let isNoBall: Bool
    let isWicket: Bool
    let wicketType: WicketType?
    let runOutBatterId: String?
    let grantWithoutBall: Bool
    let timestamp: Date
    let ballSequence: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "ball_id"
        case inningsId = "innings_id"
        case overNumber = "over_number"
        case ballNumber = "ball_number"
        case batterId = "batter_id"
        case bowlerId = "bowler_id"
        case runsScored = "runs_scored"
        case isWide = "is_wide"
        case isNoBall = "is_no_ball"
        case isWicket = "is_wicket"
        case wicketType = "wicket_type"
        case runOutBatterId = "run_out_batter_id"
        case grantWithoutBall = "grant_without_ball"
        case timestamp
        case ballSequence = "ball_sequence"
    }
    
    var isLegalDelivery: Bool {
        !isWide && !isNoBall
    }
    
    var totalRuns: Int {
        var total = runsScored
        if isWide || isNoBall {
            total += 1 // Add extra for wide/no-ball
        }
        return total
    }
    
    var displayText: String {
        var text = ""
        
        if isWide {
            text += "Wd"
        }
        if isNoBall {
            text += "Nb"
        }
        
        if runsScored > 0 {
            text += text.isEmpty ? "\(runsScored)" : "+\(runsScored)"
        } else if text.isEmpty {
            text = "0"
        }
        
        if isWicket {
            text += " W"
        }
        
        if grantWithoutBall {
            text += " (GWB)"
        }
        
        return text
    }
}

struct MatchTransfer: Identifiable, Codable {
    @DocumentID var id: String?
    let matchId: String
    let fromUserId: String
    let toUserId: String
    let accepted: Bool
    let requestedAt: Date
    let respondedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "transfer_id"
        case matchId = "match_id"
        case fromUserId = "from_user_id"
        case toUserId = "to_user_id"
        case accepted
        case requestedAt = "requested_at"
        case respondedAt = "responded_at"
    }
}