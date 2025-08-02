import Foundation
import FirebaseFirestore

struct PlayerPool: Identifiable, Codable {
    @DocumentID var id: String?
    let poolName: String
    let createdBy: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "pool_id"
        case poolName = "pool_name"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}

enum PoolRole: String, CaseIterable, Codable {
    case admin = "admin"
    case moderator = "moderator"
    case user = "user"
    
    var displayName: String {
        switch self {
        case .admin: return "Admin"
        case .moderator: return "Moderator"
        case .user: return "User"
        }
    }
    
    var canManagePlayers: Bool {
        self == .admin || self == .moderator
    }
    
    var canAssignModerators: Bool {
        self == .admin
    }
    
    var canRemoveUsers: Bool {
        self == .admin
    }
}

struct PoolMembership: Identifiable, Codable {
    @DocumentID var id: String?
    let poolId: String
    let userId: String
    let role: PoolRole
    let joinedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "membership_id"
        case poolId = "pool_id"
        case userId = "user_id"
        case role
        case joinedAt = "joined_at"
    }
}