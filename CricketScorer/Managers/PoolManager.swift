import Foundation
import FirebaseFirestore
import Combine

@MainActor
class PoolManager: ObservableObject {
    @Published var currentPool: PlayerPool?
    @Published var currentMembership: PoolMembership?
    @Published var players: [Player] = []
    @Published var poolMembers: [PoolMembership] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = FirebaseConfig.shared.db
    private var playersListener: ListenerRegistration?
    private var membersListener: ListenerRegistration?
    
    deinit {
        removeListeners()
    }
    
    private func removeListeners() {
        playersListener?.remove()
        membersListener?.remove()
    }
    
    func loadUserPools(userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let memberships = try await db.collection("PoolMemberships")
                .whereField("user_id", isEqualTo: userId)
                .getDocuments()
            
            if let firstMembership = memberships.documents.first {
                let membership = try firstMembership.data(as: PoolMembership.self)
                await loadPool(poolId: membership.poolId, membership: membership)
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadPool(poolId: String, membership: PoolMembership) async {
        do {
            let poolDoc = try await db.collection("PlayerPools").document(poolId).getDocument()
            let pool = try poolDoc.data(as: PlayerPool.self)
            
            self.currentPool = pool
            self.currentMembership = membership
            
            setupListeners(poolId: poolId)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    private func setupListeners(poolId: String) {
        // Listen to players in this pool
        playersListener = db.collection("Players")
            .whereField("pool_id", isEqualTo: poolId)
            .order(by: "name")
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    guard let documents = snapshot?.documents else { return }
                    
                    self?.players = documents.compactMap { doc in
                        try? doc.data(as: Player.self)
                    }
                }
            }
        
        // Listen to pool members
        membersListener = db.collection("PoolMemberships")
            .whereField("pool_id", isEqualTo: poolId)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    guard let documents = snapshot?.documents else { return }
                    
                    self?.poolMembers = documents.compactMap { doc in
                        try? doc.data(as: PoolMembership.self)
                    }
                }
            }
    }
    
    func createPool(name: String, userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Create player pool
            let pool = PlayerPool(
                poolName: name,
                createdBy: userId,
                createdAt: Date()
            )
            
            let poolRef = try await db.collection("PlayerPools").addDocument(from: pool)
            
            // Create admin membership
            let membership = PoolMembership(
                poolId: poolRef.documentID,
                userId: userId,
                role: .admin,
                joinedAt: Date()
            )
            
            try await db.collection("PoolMemberships").addDocument(from: membership)
            
            // Load the new pool
            var createdPool = pool
            createdPool.id = poolRef.documentID
            
            var createdMembership = membership
            createdMembership.poolId = poolRef.documentID
            
            await loadPool(poolId: poolRef.documentID, membership: createdMembership)
            
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func addPlayer(name: String, battingHand: BattingHand?, bowlingHand: BowlingHand?, bowlingStyle: BowlingStyle?) async {
        guard let poolId = currentPool?.id,
              let membership = currentMembership,
              membership.role.canManagePlayers else {
            errorMessage = "No permission to add players"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let player = Player(
                poolId: poolId,
                name: name,
                battingHand: battingHand,
                bowlingHand: bowlingHand,
                bowlingStyle: bowlingStyle,
                linkedUserId: nil,
                createdAt: Date()
            )
            
            try await db.collection("Players").addDocument(from: player)
            
            // Initialize player stats
            let stats = PlayerStats(
                playerId: "", // Will be updated by Cloud Function
                matches: 0,
                innings: 0,
                runs: 0,
                ballsFaced: 0,
                wickets: 0,
                oversBowled: 0.0,
                runsConceded: 0,
                fours: 0,
                sixes: 0,
                lastUpdated: Date()
            )
            
            try await db.collection("PlayerStats").addDocument(from: stats)
            
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func removePlayer(playerId: String) async {
        guard let membership = currentMembership,
              membership.role.canManagePlayers else {
            errorMessage = "No permission to remove players"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await db.collection("Players").document(playerId).delete()
            // Also delete player stats
            let statsQuery = try await db.collection("PlayerStats")
                .whereField("player_id", isEqualTo: playerId)
                .getDocuments()
            
            for doc in statsQuery.documents {
                try await doc.reference.delete()
            }
            
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func linkPlayerToUser(playerId: String, userId: String) async {
        guard let membership = currentMembership,
              membership.role.canManagePlayers else {
            errorMessage = "No permission to link players"
            return
        }
        
        do {
            try await db.collection("Players").document(playerId).updateData([
                "linked_user_id": userId
            ])
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func inviteUser(email: String, role: PoolRole) async {
        guard let poolId = currentPool?.id,
              let membership = currentMembership else {
            errorMessage = "No active pool"
            return
        }
        
        // Check permissions
        if role == .moderator && !membership.role.canAssignModerators {
            errorMessage = "No permission to assign moderators"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Find user by email
            let usersQuery = try await db.collection("Users")
                .whereField("email", isEqualTo: email)
                .getDocuments()
            
            guard let userDoc = usersQuery.documents.first else {
                errorMessage = "User not found"
                isLoading = false
                return
            }
            
            let userId = userDoc.documentID
            
            // Check if user is already a member
            let existingMembership = try await db.collection("PoolMemberships")
                .whereField("pool_id", isEqualTo: poolId)
                .whereField("user_id", isEqualTo: userId)
                .getDocuments()
            
            if !existingMembership.documents.isEmpty {
                errorMessage = "User is already a member of this pool"
                isLoading = false
                return
            }
            
            // Create membership
            let newMembership = PoolMembership(
                poolId: poolId,
                userId: userId,
                role: role,
                joinedAt: Date()
            )
            
            try await db.collection("PoolMemberships").addDocument(from: newMembership)
            
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func removeUser(membershipId: String) async {
        guard let membership = currentMembership,
              membership.role.canRemoveUsers else {
            errorMessage = "No permission to remove users"
            return
        }
        
        do {
            try await db.collection("PoolMemberships").document(membershipId).delete()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func updateUserRole(membershipId: String, newRole: PoolRole) async {
        guard let membership = currentMembership,
              membership.role.canAssignModerators || (newRole != .moderator && newRole != .admin) else {
            errorMessage = "No permission to assign this role"
            return
        }
        
        do {
            try await db.collection("PoolMemberships").document(membershipId).updateData([
                "role": newRole.rawValue
            ])
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    var canManagePlayers: Bool {
        currentMembership?.role.canManagePlayers ?? false
    }
    
    var canManageUsers: Bool {
        currentMembership?.role.canRemoveUsers ?? false
    }
    
    var canAssignModerators: Bool {
        currentMembership?.role.canAssignModerators ?? false
    }
}