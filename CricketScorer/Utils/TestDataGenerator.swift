import Foundation
import FirebaseFirestore

class TestDataGenerator {
    static let shared = TestDataGenerator()
    private let db = FirebaseConfig.shared.db
    
    private init() {}
    
    func generateTestData() async throws {
        print("🏏 Generating test data...")
        
        // Create test users
        let users = try await createTestUsers()
        print("✅ Created \(users.count) test users")
        
        // Create test player pool
        let poolId = try await createTestPool(adminUserId: users[0].id!)
        print("✅ Created test pool: \(poolId)")
        
        // Add users to pool
        try await addUsersToPool(users: users, poolId: poolId)
        print("✅ Added users to pool")
        
        // Create test players
        let players = try await createTestPlayers(poolId: poolId)
        print("✅ Created \(players.count) test players")
        
        // Create test match
        let matchId = try await createTestMatch(poolId: poolId, createdBy: users[0].id!)
        print("✅ Created test match: \(matchId)")
        
        // Add teams to match
        try await addTeamsToMatch(matchId: matchId, players: players)
        print("✅ Added teams to match")
        
        print("🎉 Test data generation complete!")
    }
    
    private func createTestUsers() async throws -> [User] {
        let testUsers = [
            User(id: "test-user-1", email: "admin@example.com", createdAt: Date()),
            User(id: "test-user-2", email: "moderator@example.com", createdAt: Date()),
            User(id: "test-user-3", email: "user@example.com", createdAt: Date())
        ]
        
        for user in testUsers {
            try await db.collection("Users").document(user.id!).setData(from: user)
        }
        
        return testUsers
    }
    
    private func createTestPool(adminUserId: String) async throws -> String {
        let pool = PlayerPool(
            poolName: "Weekend Warriors CC",
            createdBy: adminUserId,
            createdAt: Date()
        )
        
        let poolRef = try await db.collection("PlayerPools").addDocument(from: pool)
        return poolRef.documentID
    }
    
    private func addUsersToPool(users: [User], poolId: String) async throws {
        let roles: [PoolRole] = [.admin, .moderator, .user]
        
        for (index, user) in users.enumerated() {
            let membership = PoolMembership(
                poolId: poolId,
                userId: user.id!,
                role: roles[index],
                joinedAt: Date()
            )
            
            try await db.collection("PoolMemberships").addDocument(from: membership)
        }
    }
    
    private func createTestPlayers(poolId: String) async throws -> [Player] {
        let testPlayers = [
            // Team A players
            Player(id: nil, poolId: poolId, name: "John Smith", battingHand: .right, bowlingHand: .right, bowlingStyle: .fast, linkedUserId: nil, createdAt: Date()),
            Player(id: nil, poolId: poolId, name: "Mike Johnson", battingHand: .left, bowlingHand: .left, bowlingStyle: .medium, linkedUserId: nil, createdAt: Date()),
            Player(id: nil, poolId: poolId, name: "David Wilson", battingHand: .right, bowlingHand: .right, bowlingStyle: .spin, linkedUserId: nil, createdAt: Date()),
            Player(id: nil, poolId: poolId, name: "Chris Brown", battingHand: .right, bowlingHand: .right, bowlingStyle: .fast, linkedUserId: nil, createdAt: Date()),
            Player(id: nil, poolId: poolId, name: "Tom Davis", battingHand: .left, bowlingHand: .right, bowlingStyle: .medium, linkedUserId: nil, createdAt: Date()),
            Player(id: nil, poolId: poolId, name: "Steve Miller", battingHand: .right, bowlingHand: .right, bowlingStyle: .offSpin, linkedUserId: nil, createdAt: Date()),
            
            // Team B players
            Player(id: nil, poolId: poolId, name: "Alex Turner", battingHand: .left, bowlingHand: .left, bowlingStyle: .fast, linkedUserId: nil, createdAt: Date()),
            Player(id: nil, poolId: poolId, name: "Ben Cooper", battingHand: .right, bowlingHand: .right, bowlingStyle: .legSpin, linkedUserId: nil, createdAt: Date()),
            Player(id: nil, poolId: poolId, name: "Ryan White", battingHand: .right, bowlingHand: .right, bowlingStyle: .medium, linkedUserId: nil, createdAt: Date()),
            Player(id: nil, poolId: poolId, name: "Luke Green", battingHand: .left, bowlingHand: .left, bowlingStyle: .spin, linkedUserId: nil, createdAt: Date()),
            Player(id: nil, poolId: poolId, name: "Sam Taylor", battingHand: .right, bowlingHand: .right, bowlingStyle: .fast, linkedUserId: nil, createdAt: Date()),
            Player(id: nil, poolId: poolId, name: "Jake Moore", battingHand: .right, bowlingHand: .right, bowlingStyle: .offSpin, linkedUserId: nil, createdAt: Date())
        ]
        
        var createdPlayers: [Player] = []
        
        for player in testPlayers {
            let playerRef = try await db.collection("Players").addDocument(from: player)
            var createdPlayer = player
            createdPlayer.id = playerRef.documentID
            createdPlayers.append(createdPlayer)
        }
        
        return createdPlayers
    }
    
    private func createTestMatch(poolId: String, createdBy: String) async throws -> String {
        let match = Match(
            poolId: poolId,
            createdBy: createdBy,
            teamAName: "Thunderbolts",
            teamBName: "Lightning",
            oversPerInnings: 20,
            twoInnings: false,
            wideNoBallRuns: true,
            tossWinner: .A,
            tossDecision: .bat,
            status: .ongoing,
            createdAt: Date(),
            currentScorerId: createdBy
        )
        
        let matchRef = try await db.collection("Matches").addDocument(from: match)
        return matchRef.documentID
    }
    
    private func addTeamsToMatch(matchId: String, players: [Player]) async throws {
        // Team A (first 6 players)
        for (index, player) in players.prefix(6).enumerated() {
            let matchTeam = MatchTeam(
                matchId: matchId,
                team: .A,
                playerId: player.id!,
                isCaptain: index == 0,
                isCommonPlayer: false,
                battingOrder: index + 1
            )
            
            try await db.collection("MatchTeams").addDocument(from: matchTeam)
        }
        
        // Team B (last 6 players)
        for (index, player) in players.suffix(6).enumerated() {
            let matchTeam = MatchTeam(
                matchId: matchId,
                team: .B,
                playerId: player.id!,
                isCaptain: index == 0,
                isCommonPlayer: false,
                battingOrder: index + 1
            )
            
            try await db.collection("MatchTeams").addDocument(from: matchTeam)
        }
    }
    
    func simulateMatch(matchId: String) async throws {
        print("🏏 Simulating match...")
        
        // Get match data
        let matchDoc = try await db.collection("Matches").document(matchId).getDocument()
        let match = try matchDoc.data(as: Match.self)
        
        // Get teams
        let teamsSnapshot = try await db.collection("MatchTeams")
            .whereField("match_id", isEqualTo: matchId)
            .getDocuments()
        
        let teamA = teamsSnapshot.documents.compactMap { try? $0.data(as: MatchTeam.self) }
            .filter { $0.team == .A }
            .sorted { ($0.battingOrder ?? 99) < ($1.battingOrder ?? 99) }
        
        let teamB = teamsSnapshot.documents.compactMap { try? $0.data(as: MatchTeam.self) }
            .filter { $0.team == .B }
            .sorted { ($0.battingOrder ?? 99) < ($1.battingOrder ?? 99) }
        
        // Simulate first innings (Team A batting)
        let firstInningsId = try await createInnings(matchId: matchId, team: .A, inningsNumber: 1)
        let firstInningsScore = try await simulateInnings(
            inningsId: firstInningsId,
            battingTeam: teamA,
            bowlingTeam: teamB,
            maxOvers: match.oversPerInnings
        )
        
        print("✅ First innings completed: \(firstInningsScore) runs")
        
        // Simulate second innings (Team B batting)
        let secondInningsId = try await createInnings(matchId: matchId, team: .B, inningsNumber: 2, target: firstInningsScore + 1)
        let secondInningsScore = try await simulateInnings(
            inningsId: secondInningsId,
            battingTeam: teamB,
            bowlingTeam: teamA,
            maxOvers: match.oversPerInnings,
            target: firstInningsScore + 1
        )
        
        print("✅ Second innings completed: \(secondInningsScore) runs")
        print("🎉 Match simulation complete!")
    }
    
    private func createInnings(matchId: String, team: Team, inningsNumber: Int, target: Int? = nil) async throws -> String {
        let innings = Innings(
            matchId: matchId,
            team: team,
            inningsNumber: inningsNumber,
            runs: 0,
            wickets: 0,
            oversFaced: 0.0,
            status: .inProgress,
            target: target,
            currentBatter1Id: nil,
            currentBatter2Id: nil,
            currentBowlerId: nil,
            currentOver: 0,
            currentBall: 0
        )
        
        let inningsRef = try await db.collection("Innings").addDocument(from: innings)
        return inningsRef.documentID
    }
    
    private func simulateInnings(
        inningsId: String,
        battingTeam: [MatchTeam],
        bowlingTeam: [MatchTeam],
        maxOvers: Int,
        target: Int? = nil
    ) async throws -> Int {
        var totalRuns = 0
        var wickets = 0
        var ballSequence = 0
        var currentBatterIndex = 0
        var currentBowlerIndex = 0
        var overCount = 0
        var ballInOver = 0
        
        let maxBalls = maxOvers * 6
        let maxWickets = battingTeam.count - 1
        
        while overCount < maxOvers && wickets < maxWickets {
            // Change bowler at start of each over
            if ballInOver == 0 {
                currentBowlerIndex = (currentBowlerIndex + 1) % bowlingTeam.count
            }
            
            // Simulate ball
            let isWide = Double.random(in: 0...1) < 0.05
            let isNoBall = Double.random(in: 0...1) < 0.03
            let isWicket = !isWide && !isNoBall && Double.random(in: 0...1) < 0.08
            
            var runs = 0
            if !isWicket {
                let rand = Double.random(in: 0...1)
                if rand < 0.4 {
                    runs = 0
                } else if rand < 0.6 {
                    runs = 1
                } else if rand < 0.75 {
                    runs = 2
                } else if rand < 0.85 {
                    runs = 3
                } else if rand < 0.95 {
                    runs = 4
                } else {
                    runs = 6
                }
            }
            
            if isWide || isNoBall {
                runs += 1
            }
            
            totalRuns += runs
            ballSequence += 1
            
            // Create ball event
            let ballEvent = BallEvent(
                inningsId: inningsId,
                overNumber: overCount,
                ballNumber: ballInOver,
                batterId: battingTeam[currentBatterIndex].playerId,
                bowlerId: bowlingTeam[currentBowlerIndex].playerId,
                runsScored: runs - (isWide || isNoBall ? 1 : 0),
                isWide: isWide,
                isNoBall: isNoBall,
                isWicket: isWicket,
                wicketType: isWicket ? .bowled : nil,
                runOutBatterId: nil,
                grantWithoutBall: false,
                timestamp: Date(),
                ballSequence: ballSequence
            )
            
            try await db.collection("BallEvents").addDocument(from: ballEvent)
            
            if isWicket {
                wickets += 1
                currentBatterIndex = min(currentBatterIndex + 1, battingTeam.count - 1)
            }
            
            // Update ball count
            if !isWide && !isNoBall {
                ballInOver += 1
                if ballInOver == 6 {
                    overCount += 1
                    ballInOver = 0
                }
            }
            
            // Check if target is reached
            if let target = target, totalRuns >= target {
                break
            }
        }
        
        // Update innings status
        let status: InningsStatus
        if let target = target, totalRuns >= target {
            status = .targetChased
        } else if wickets >= maxWickets {
            status = .allOut
        } else {
            status = .completed
        }
        
        try await db.collection("Innings").document(inningsId).updateData([
            "runs": totalRuns,
            "wickets": wickets,
            "overs_faced": Double(overCount) + (Double(ballInOver) / 6.0),
            "status": status.rawValue
        ])
        
        return totalRuns
    }
    
    func clearTestData() async throws {
        print("🧹 Clearing test data...")
        
        let collections = ["BallEvents", "Innings", "MatchTeams", "Matches", "PlayerStats", "Players", "PoolMemberships", "PlayerPools", "Users"]
        
        for collectionName in collections {
            let snapshot = try await db.collection(collectionName).getDocuments()
            
            for document in snapshot.documents {
                try await document.reference.delete()
            }
            
            print("✅ Cleared \(collectionName)")
        }
        
        print("🎉 Test data cleared!")
    }
}