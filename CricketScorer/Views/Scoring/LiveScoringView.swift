import SwiftUI

struct LiveScoringView: View {
    let matchId: String
    @EnvironmentObject var matchManager: MatchManager
    @EnvironmentObject var poolManager: PoolManager
    @State private var showingBatterSelection = false
    @State private var showingBowlerSelection = false
    @State private var showingWicketSheet = false
    @State private var selectedWicketType: WicketType?
    @State private var pendingBallData: PendingBallData?
    @State private var animateScore = false
    
    var body: some View {
        ZStack {
            // Dynamic cricket field background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.2, blue: 0.1),
                    Color(red: 0.08, green: 0.25, blue: 0.15),
                    Color(red: 0.1, green: 0.3, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Floating cricket elements
            Circle()
                .fill(EmotionalGradient.cricket.opacity(0.06))
                .frame(width: 300)
                .blur(radius: 80)
                .offset(x: -150, y: -400)
                .emotionalPulse()
            
            Circle()
                .fill(EmotionalGradient.sunset.opacity(0.04))
                .frame(width: 200)
                .blur(radius: 60)
                .offset(x: 180, y: 500)
                .emotionalPulse()
            
            ScrollView {
                VStack(spacing: 24) {
                    if let match = matchManager.currentMatch {
                        // Enhanced match header
                        LiquidMatchHeaderView(match: match)
                        
                        if let innings = matchManager.currentInnings {
                            // Enhanced current innings display
                            LiquidCurrentInningsView(innings: innings, animateScore: $animateScore)
                            
                            // Enhanced players view
                            LiquidPlayersView(innings: innings, match: match)
                            
                            // Enhanced scoring buttons
                            if matchManager.canScore {
                                LiquidScoringButtonsView(
                                    onBallScored: { ballData in
                                        HapticManager.shared.impact(.medium)
                                        if ballData.isWicket {
                                            pendingBallData = ballData
                                            showingWicketSheet = true
                                        } else {
                                            Task {
                                                await recordBall(ballData)
                                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                                    animateScore.toggle()
                                                }
                                            }
                                        }
                                    }
                                )
                                
                                // Enhanced action buttons
                                LiquidActionButtonsView()
                            } else {
                                // No permission message
                                VStack(spacing: 12) {
                                    Image(systemName: "lock.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundStyle(EmotionalGradient.neutral)
                                    
                                    Text("You don't have permission to score this match")
                                        .font(.cricketBody)
                                        .foregroundStyle(.white.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.horizontal, 32)
                                .padding(.vertical, 24)
                                .liquidGlass(intensity: 0.4, cornerRadius: 20, borderOpacity: 0.25)
                            }
                            
                            // Enhanced ball history
                            LiquidBallHistoryView(ballEvents: matchManager.ballEvents)
                        } else {
                            // Enhanced no innings view
                            LiquidNoInningsView(match: match)
                        }
                    } else {
                        // Loading state
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text("Loading match...")
                                .font(.cricketBody)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(.vertical, 60)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Live Scoring")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Scoreboard") {
                        // Navigate to scoreboard
                    }
                    Button("Match Summary") {
                        // Navigate to match summary
                    }
                    if matchManager.canScore {
                        Divider()
                        Button("Transfer Match") {
                            // Show transfer sheet
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            await matchManager.loadMatch(matchId: matchId)
        }
        .sheet(isPresented: $showingBatterSelection) {
            BatterSelectionView()
                .environmentObject(matchManager)
                .environmentObject(poolManager)
        }
        .sheet(isPresented: $showingBowlerSelection) {
            BowlerSelectionView()
                .environmentObject(matchManager)
                .environmentObject(poolManager)
        }
        .sheet(isPresented: $showingWicketSheet) {
            WicketSelectionView(
                pendingBallData: $pendingBallData,
                onWicketSelected: { ballData in
                    Task {
                        await recordBall(ballData)
                    }
                }
            )
            .environmentObject(matchManager)
            .environmentObject(poolManager)
        }
    }
    
    private func recordBall(_ ballData: PendingBallData) async {
        guard let innings = matchManager.currentInnings,
              let inningsId = innings.id,
              let batterId = innings.currentBatter1Id,
              let bowlerId = innings.currentBowlerId else {
            return
        }
        
        await matchManager.recordBall(
            inningsId: inningsId,
            batterId: batterId,
            bowlerId: bowlerId,
            runsScored: ballData.runs,
            isWide: ballData.isWide,
            isNoBall: ballData.isNoBall,
            isWicket: ballData.isWicket,
            wicketType: ballData.wicketType,
            runOutBatterId: ballData.runOutBatterId,
            grantWithoutBall: ballData.grantWithoutBall
        )
    }
}

struct PendingBallData {
    let runs: Int
    let isWide: Bool
    let isNoBall: Bool
    let isWicket: Bool
    var wicketType: WicketType?
    var runOutBatterId: String?
    let grantWithoutBall: Bool
}

struct MatchHeaderView: View {
    let match: Match
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(match.teamAName)
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Text("vs")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(match.teamBName)
                    .font(.headline)
                    .foregroundColor(.red)
            }
            
            Text("\(match.oversPerInnings) overs per innings")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct CurrentInningsView: View {
    let innings: Innings
    
    var body: some View {
        VStack(spacing: 12) {
            // Score display
            HStack {
                VStack {
                    Text(innings.displayScore)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack {
                    Text(innings.displayOvers)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Overs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let target = innings.target {
                    Spacer()
                    
                    VStack {
                        Text("\(target - innings.runs)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(target - innings.runs <= 0 ? .green : .primary)
                        Text("Need")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Innings info
            HStack {
                Text("Innings \(innings.inningsNumber)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(innings.team == .A ? "Team A" : "Team B") batting")
                    .font(.subheadline)
                    .foregroundColor(innings.team == .A ? .blue : .red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct PlayersView: View {
    let innings: Innings
    let match: Match
    @EnvironmentObject var poolManager: PoolManager
    @State private var showingBatterSelection = false
    @State private var showingBowlerSelection = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Batters
            HStack {
                Text("Batters")
                    .font(.headline)
                Spacer()
                Button("Change") {
                    showingBatterSelection = true
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
            
            HStack {
                if let batter1Id = innings.currentBatter1Id,
                   let batter1 = poolManager.players.first(where: { $0.id == batter1Id }) {
                    PlayerDisplayView(player: batter1, isStriker: true)
                } else {
                    Button("Select Batter 1") {
                        showingBatterSelection = true
                    }
                    .buttonStyle(.bordered)
                }
                
                if let batter2Id = innings.currentBatter2Id,
                   let batter2 = poolManager.players.first(where: { $0.id == batter2Id }) {
                    PlayerDisplayView(player: batter2, isStriker: false)
                } else {
                    Button("Select Batter 2") {
                        showingBatterSelection = true
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Divider()
            
            // Bowler
            HStack {
                Text("Bowler")
                    .font(.headline)
                Spacer()
                Button("Change") {
                    showingBowlerSelection = true
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
            
            if let bowlerId = innings.currentBowlerId,
               let bowler = poolManager.players.first(where: { $0.id == bowlerId }) {
                PlayerDisplayView(player: bowler, isStriker: false)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Button("Select Bowler") {
                    showingBowlerSelection = true
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showingBatterSelection) {
            BatterSelectionView()
        }
        .sheet(isPresented: $showingBowlerSelection) {
            BowlerSelectionView()
        }
    }
}

struct PlayerDisplayView: View {
    let player: Player
    let isStriker: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if isStriker {
                    Text("Striker")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(3)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ScoringButtonsView: View {
    let onBallScored: (PendingBallData) -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            // Run buttons
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                ForEach(0...6, id: \.self) { runs in
                    Button("\(runs)") {
                        onBallScored(PendingBallData(
                            runs: runs,
                            isWide: false,
                            isNoBall: false,
                            isWicket: false,
                            grantWithoutBall: false
                        ))
                    }
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)
                    .background(runs == 4 ? Color.blue : runs == 6 ? Color.green : Color.gray.opacity(0.2))
                    .foregroundColor(runs == 4 || runs == 6 ? .white : .primary)
                    .cornerRadius(8)
                }
            }
            
            // Special buttons
            HStack(spacing: 10) {
                Button("Wide") {
                    onBallScored(PendingBallData(
                        runs: 0,
                        isWide: true,
                        isNoBall: false,
                        isWicket: false,
                        grantWithoutBall: false
                    ))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button("No Ball") {
                    onBallScored(PendingBallData(
                        runs: 0,
                        isWide: false,
                        isNoBall: true,
                        isWicket: false,
                        grantWithoutBall: false
                    ))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button("Wicket") {
                    onBallScored(PendingBallData(
                        runs: 0,
                        isWide: false,
                        isNoBall: false,
                        isWicket: true,
                        grantWithoutBall: false
                    ))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct ActionButtonsView: View {
    @EnvironmentObject var matchManager: MatchManager
    
    var body: some View {
        HStack(spacing: 15) {
            Button("Undo") {
                Task {
                    await matchManager.undoLastBall()
                }
            }
            .buttonStyle(.bordered)
            .disabled(matchManager.ballEvents.isEmpty)
            
            Spacer()
            
            Button("Grant w/o Ball") {
                // Show grant without ball options
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

struct BallHistoryView: View {
    let ballEvents: [BallEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Balls")
                .font(.headline)
            
            if ballEvents.isEmpty {
                Text("No balls bowled yet")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                    ForEach(ballEvents.suffix(12).reversed(), id: \.id) { ball in
                        Text(ball.displayText)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(ballColor(for: ball))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func ballColor(for ball: BallEvent) -> Color {
        if ball.isWicket {
            return .red
        } else if ball.isWide || ball.isNoBall {
            return .orange
        } else if ball.runsScored == 4 {
            return .blue
        } else if ball.runsScored == 6 {
            return .green
        } else {
            return .gray
        }
    }
}

struct NoInningsView: View {
    let match: Match
    @EnvironmentObject var matchManager: MatchManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cricket.ball")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Match Created")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Ready to start the first innings")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let tossWinner = match.tossWinner, let tossDecision = match.tossDecision {
                let battingTeam = (tossDecision == .bat) ? tossWinner : tossWinner.opposite
                
                Button("Start Innings") {
                    Task {
                        if let matchId = match.id {
                            await matchManager.startInnings(matchId: matchId, battingTeam: battingTeam)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(matchManager.isLoading)
            }
        }
        .padding()
    }
}

// Placeholder views for selection sheets
struct BatterSelectionView: View {
    var body: some View {
        NavigationView {
            Text("Batter Selection")
                .navigationTitle("Select Batters")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct BowlerSelectionView: View {
    var body: some View {
        NavigationView {
            Text("Bowler Selection")
                .navigationTitle("Select Bowler")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct WicketSelectionView: View {
    @Binding var pendingBallData: PendingBallData?
    let onWicketSelected: (PendingBallData) -> Void
    
    var body: some View {
        NavigationView {
            Text("Wicket Selection")
                .navigationTitle("Select Wicket Type")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    LiveScoringView(matchId: "sample-match-id")
        .environmentObject(MatchManager())
        .environmentObject(PoolManager())
}