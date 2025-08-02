import Foundation
import FirebaseFirestore
import Combine

@MainActor
class MatchManager: ObservableObject {
    @Published var currentMatch: Match?
    @Published var currentInnings: Innings?
    @Published var teamA: [MatchTeam] = []
    @Published var teamB: [MatchTeam] = []
    @Published var ballEvents: [BallEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = FirebaseConfig.shared.db
    private var matchListener: ListenerRegistration?
    private var inningsListener: ListenerRegistration?
    private var ballEventsListener: ListenerRegistration?
    private var teamsListener: ListenerRegistration?
    
    deinit {
        removeListeners()
    }
    
    private func removeListeners() {
        matchListener?.remove()
        inningsListener?.remove()
        ballEventsListener?.remove()
        teamsListener?.remove()
    }
    
    func createMatch(
        poolId: String,
        createdBy: String,
        teamAName: String,
        teamBName: String,
        oversPerInnings: Int,
        twoInnings: Bool,
        wideNoBallRuns: Bool
    ) async -> String? {
        isLoading = true
        errorMessage = nil
        
        do {
            let match = Match(
                poolId: poolId,
                createdBy: createdBy,
                teamAName: teamAName,
                teamBName: teamBName,
                oversPerInnings: oversPerInnings,
                twoInnings: twoInnings,
                wideNoBallRuns: wideNoBallRuns,
                tossWinner: nil,
                tossDecision: nil,
                status: .ongoing,
                createdAt: Date(),
                currentScorerId: createdBy
            )
            
            let matchRef = try await db.collection("Matches").addDocument(from: match)
            isLoading = false
            return matchRef.documentID
        } catch {
            self.errorMessage = error.localizedDescription
            isLoading = false
            return nil
        }
    }
    
    func loadMatch(matchId: String) async {
        removeListeners()
        
        do {
            let matchDoc = try await db.collection("Matches").document(matchId).getDocument()
            let match = try matchDoc.data(as: Match.self)
            
            self.currentMatch = match
            setupListeners(matchId: matchId)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    private func setupListeners(matchId: String) {
        // Listen to match updates
        matchListener = db.collection("Matches").document(matchId)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    if let snapshot = snapshot, snapshot.exists {
                        do {
                            self?.currentMatch = try snapshot.data(as: Match.self)
                        } catch {
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        
        // Listen to teams
        teamsListener = db.collection("MatchTeams")
            .whereField("match_id", isEqualTo: matchId)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    guard let documents = snapshot?.documents else { return }
                    
                    let teams = documents.compactMap { doc in
                        try? doc.data(as: MatchTeam.self)
                    }
                    
                    self?.teamA = teams.filter { $0.team == .A }.sorted { ($0.battingOrder ?? 99) < ($1.battingOrder ?? 99) }
                    self?.teamB = teams.filter { $0.team == .B }.sorted { ($0.battingOrder ?? 99) < ($1.battingOrder ?? 99) }
                }
            }
        
        // Listen to current innings
        loadCurrentInnings(matchId: matchId)
    }
    
    private func loadCurrentInnings(matchId: String) {
        inningsListener = db.collection("Innings")
            .whereField("match_id", isEqualTo: matchId)
            .whereField("status", in: [InningsStatus.inProgress.rawValue, InningsStatus.notStarted.rawValue])
            .limit(to: 1)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    if let document = snapshot?.documents.first {
                        do {
                            let innings = try document.data(as: Innings.self)
                            self?.currentInnings = innings
                            self?.setupBallEventsListener(inningsId: innings.id!)
                        } catch {
                            self?.errorMessage = error.localizedDescription
                        }
                    } else {
                        self?.currentInnings = nil
                        self?.ballEvents = []
                    }
                }
            }
    }
    
    private func setupBallEventsListener(inningsId: String) {
        ballEventsListener?.remove()
        
        ballEventsListener = db.collection("BallEvents")
            .whereField("innings_id", isEqualTo: inningsId)
            .order(by: "ball_sequence")
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    guard let documents = snapshot?.documents else { return }
                    
                    self?.ballEvents = documents.compactMap { doc in
                        try? doc.data(as: BallEvent.self)
                    }
                }
            }
    }
    
    func addPlayerToTeam(matchId: String, playerId: String, team: Team, isCaptain: Bool = false, isCommonPlayer: Bool = false) async {
        do {
            let matchTeam = MatchTeam(
                matchId: matchId,
                team: team,
                playerId: playerId,
                isCaptain: isCaptain,
                isCommonPlayer: isCommonPlayer,
                battingOrder: nil
            )
            
            try await db.collection("MatchTeams").addDocument(from: matchTeam)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func removePlayerFromTeam(matchTeamId: String) async {
        do {
            try await db.collection("MatchTeams").document(matchTeamId).delete()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func setBattingOrder(matchTeamId: String, order: Int) async {
        do {
            try await db.collection("MatchTeams").document(matchTeamId).updateData([
                "batting_order": order
            ])
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func setToss(matchId: String, winner: Team, decision: TossDecision) async {
        do {
            try await db.collection("Matches").document(matchId).updateData([
                "toss_winner": winner.rawValue,
                "toss_decision": decision.rawValue
            ])
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func startInnings(matchId: String, battingTeam: Team, target: Int? = nil) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Determine innings number
            let existingInnings = try await db.collection("Innings")
                .whereField("match_id", isEqualTo: matchId)
                .getDocuments()
            
            let inningsNumber = existingInnings.documents.count + 1
            
            let innings = Innings(
                matchId: matchId,
                team: battingTeam,
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
            
            try await db.collection("Innings").addDocument(from: innings)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func recordBall(
        inningsId: String,
        batterId: String,
        bowlerId: String,
        runsScored: Int,
        isWide: Bool = false,
        isNoBall: Bool = false,
        isWicket: Bool = false,
        wicketType: WicketType? = nil,
        runOutBatterId: String? = nil,
        grantWithoutBall: Bool = false
    ) async {
        guard let innings = currentInnings else {
            errorMessage = "No active innings"
            return
        }
        
        do {
            let ballSequence = ballEvents.count + 1
            let currentBall = innings.currentBall + (isWide || isNoBall ? 0 : 1)
            let currentOver = currentBall == 6 ? innings.currentOver + 1 : innings.currentOver
            let ballInOver = currentBall == 6 ? 0 : currentBall
            
            let ballEvent = BallEvent(
                inningsId: inningsId,
                overNumber: currentOver,
                ballNumber: ballInOver,
                batterId: batterId,
                bowlerId: bowlerId,
                runsScored: runsScored,
                isWide: isWide,
                isNoBall: isNoBall,
                isWicket: isWicket,
                wicketType: wicketType,
                runOutBatterId: runOutBatterId,
                grantWithoutBall: grantWithoutBall,
                timestamp: Date(),
                ballSequence: ballSequence
            )
            
            try await db.collection("BallEvents").addDocument(from: ballEvent)
            
            // Update innings
            let newRuns = innings.runs + ballEvent.totalRuns
            let newWickets = innings.wickets + (isWicket ? 1 : 0)
            let newOversFaced = Double(currentOver) + (Double(ballInOver) / 6.0)
            
            var updates: [String: Any] = [
                "runs": newRuns,
                "wickets": newWickets,
                "overs_faced": newOversFaced,
                "current_over": currentOver,
                "current_ball": ballInOver
            ]
            
            // Check if innings should end
            if let match = currentMatch {
                let maxOvers = Double(match.oversPerInnings)
                let maxWickets = 10 // Assuming 11 players, 10 wickets to get all out
                
                if newWickets >= maxWickets {
                    updates["status"] = InningsStatus.allOut.rawValue
                } else if newOversFaced >= maxOvers {
                    updates["status"] = InningsStatus.completed.rawValue
                } else if let target = innings.target, newRuns >= target {
                    updates["status"] = InningsStatus.targetChased.rawValue
                }
            }
            
            try await db.collection("Innings").document(inningsId).updateData(updates)
            
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func undoLastBall() async {
        guard let lastBall = ballEvents.last,
              let ballId = lastBall.id,
              let innings = currentInnings,
              let inningsId = innings.id else {
            errorMessage = "No ball to undo"
            return
        }
        
        do {
            // Delete the ball event
            try await db.collection("BallEvents").document(ballId).delete()
            
            // Update innings to previous state
            let newRuns = max(0, innings.runs - lastBall.totalRuns)
            let newWickets = max(0, innings.wickets - (lastBall.isWicket ? 1 : 0))
            
            // Recalculate overs based on remaining balls
            let remainingBalls = ballEvents.count - 1
            let legalBalls = ballEvents.dropLast().filter { $0.isLegalDelivery }.count
            let completeOvers = legalBalls / 6
            let ballsInCurrentOver = legalBalls % 6
            let newOversFaced = Double(completeOvers) + (Double(ballsInCurrentOver) / 6.0)
            
            let updates: [String: Any] = [
                "runs": newRuns,
                "wickets": newWickets,
                "overs_faced": newOversFaced,
                "current_over": completeOvers,
                "current_ball": ballsInCurrentOver,
                "status": InningsStatus.inProgress.rawValue
            ]
            
            try await db.collection("Innings").document(inningsId).updateData(updates)
            
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func setBatters(inningsId: String, batter1Id: String, batter2Id: String) async {
        do {
            try await db.collection("Innings").document(inningsId).updateData([
                "current_batter1_id": batter1Id,
                "current_batter2_id": batter2Id
            ])
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func setBowler(inningsId: String, bowlerId: String) async {
        do {
            try await db.collection("Innings").document(inningsId).updateData([
                "current_bowler_id": bowlerId
            ])
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func transferMatch(matchId: String, toUserId: String) async {
        guard let fromUserId = currentMatch?.currentScorerId else {
            errorMessage = "No current scorer to transfer from"
            return
        }
        
        do {
            let transfer = MatchTransfer(
                matchId: matchId,
                fromUserId: fromUserId,
                toUserId: toUserId,
                accepted: false,
                requestedAt: Date(),
                respondedAt: nil
            )
            
            try await db.collection("MatchTransfers").addDocument(from: transfer)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func acceptTransfer(transferId: String) async {
        do {
            try await db.collection("MatchTransfers").document(transferId).updateData([
                "accepted": true,
                "responded_at": Date()
            ])
            
            // Update match with new scorer
            if let transfer = try await db.collection("MatchTransfers").document(transferId).getDocument().data(as: MatchTransfer.self) {
                try await db.collection("Matches").document(transfer.matchId).updateData([
                    "current_scorer_id": transfer.toUserId
                ])
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    var canScore: Bool {
        guard let match = currentMatch,
              let currentUserId = FirebaseConfig.shared.auth.currentUser?.uid else {
            return false
        }
        return match.currentScorerId == currentUserId
    }
}