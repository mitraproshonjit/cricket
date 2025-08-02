import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    let email: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case email
        case createdAt = "created_at"
    }
}

struct UserProfile {
    let user: User
    let linkedPlayer: Player?
}