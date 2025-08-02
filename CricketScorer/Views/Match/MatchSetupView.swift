import SwiftUI

struct MatchSetupView: View {
    @EnvironmentObject var poolManager: PoolManager
    @EnvironmentObject var matchManager: MatchManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var currentStep = 0
    @State private var teamAName = "Team A"
    @State private var teamBName = "Team B"
    @State private var selectedTeamA: [Player] = []
    @State private var selectedTeamB: [Player] = []
    @State private var oversPerInnings = 20
    @State private var twoInnings = false
    @State private var wideNoBallRuns = true
    @State private var tossWinner: Team?
    @State private var tossDecision: TossDecision?
    @State private var createdMatchId: String?
    
    let oversOptions = [5, 10, 15, 20, 25, 30, 40, 50]
    let steps = ["Teams", "Settings", "Toss", "Start"]
    
    var body: some View {
        NavigationView {
            VStack {
                // Progress indicator
                ProgressView(value: Double(currentStep), total: Double(steps.count - 1))
                    .padding()
                
                Text("Step \(currentStep + 1) of \(steps.count): \(steps[currentStep])")
                    .font(.headline)
                    .padding(.bottom)
                
                // Step content
                Group {
                    switch currentStep {
                    case 0:
                        TeamSelectionView(
                            teamAName: $teamAName,
                            teamBName: $teamBName,
                            selectedTeamA: $selectedTeamA,
                            selectedTeamB: $selectedTeamB
                        )
                    case 1:
                        MatchSettingsView(
                            oversPerInnings: $oversPerInnings,
                            twoInnings: $twoInnings,
                            wideNoBallRuns: $wideNoBallRuns
                        )
                    case 2:
                        TossView(
                            teamAName: teamAName,
                            teamBName: teamBName,
                            tossWinner: $tossWinner,
                            tossDecision: $tossDecision
                        )
                    case 3:
                        MatchStartView(
                            teamAName: teamAName,
                            teamBName: teamBName,
                            selectedTeamA: selectedTeamA,
                            selectedTeamB: selectedTeamB,
                            oversPerInnings: oversPerInnings,
                            twoInnings: twoInnings,
                            wideNoBallRuns: wideNoBallRuns,
                            tossWinner: tossWinner,
                            tossDecision: tossDecision,
                            createdMatchId: $createdMatchId
                        )
                    default:
                        EmptyView()
                    }
                }
                
                Spacer()
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Previous") {
                            currentStep -= 1
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    if currentStep < steps.count - 1 {
                        Button("Next") {
                            currentStep += 1
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canProceed)
                    } else if createdMatchId != nil {
                        NavigationLink("Start Match", destination: ScoringView(matchId: createdMatchId!))
                            .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
            .navigationTitle("New Match")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0:
            return !selectedTeamA.isEmpty && !selectedTeamB.isEmpty && !teamAName.isEmpty && !teamBName.isEmpty
        case 1:
            return oversPerInnings > 0
        case 2:
            return tossWinner != nil && tossDecision != nil
        default:
            return true
        }
    }
}

struct TeamSelectionView: View {
    @Binding var teamAName: String
    @Binding var teamBName: String
    @Binding var selectedTeamA: [Player]
    @Binding var selectedTeamB: [Player]
    @EnvironmentObject var poolManager: PoolManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Team names
                VStack(spacing: 15) {
                    TextField("Team A Name", text: $teamAName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Team B Name", text: $teamBName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                // Team selection
                HStack(alignment: .top, spacing: 20) {
                    // Team A
                    VStack(alignment: .leading) {
                        Text(teamAName)
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text("\(selectedTeamA.count) players")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        LazyVStack {
                            ForEach(selectedTeamA) { player in
                                PlayerSelectionRow(
                                    player: player,
                                    isSelected: true,
                                    isCaptain: selectedTeamA.first == player,
                                    onTap: {
                                        selectedTeamA.removeAll { $0.id == player.id }
                                    }
                                )
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Team B
                    VStack(alignment: .leading) {
                        Text(teamBName)
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Text("\(selectedTeamB.count) players")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        LazyVStack {
                            ForEach(selectedTeamB) { player in
                                PlayerSelectionRow(
                                    player: player,
                                    isSelected: true,
                                    isCaptain: selectedTeamB.first == player,
                                    onTap: {
                                        selectedTeamB.removeAll { $0.id == player.id }
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Available players
                VStack(alignment: .leading) {
                    Text("Available Players")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVStack {
                        ForEach(availablePlayers) { player in
                            PlayerSelectionRow(
                                player: player,
                                isSelected: false,
                                isCaptain: false,
                                onTap: {
                                    // Show team selection sheet
                                }
                            )
                            .onTapGesture {
                                showTeamSelectionSheet(for: player)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var availablePlayers: [Player] {
        poolManager.players.filter { player in
            !selectedTeamA.contains { $0.id == player.id } &&
            !selectedTeamB.contains { $0.id == player.id }
        }
    }
    
    private func showTeamSelectionSheet(for player: Player) {
        // In a real implementation, this would show an action sheet
        // For now, we'll add to Team A by default
        if selectedTeamA.isEmpty {
            selectedTeamA.append(player)
        } else if selectedTeamB.isEmpty {
            selectedTeamB.append(player)
        } else {
            // Alternate between teams
            if selectedTeamA.count <= selectedTeamB.count {
                selectedTeamA.append(player)
            } else {
                selectedTeamB.append(player)
            }
        }
    }
}

struct PlayerSelectionRow: View {
    let player: Player
    let isSelected: Bool
    let isCaptain: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(player.name)
                        .font(.subheadline)
                        .fontWeight(isCaptain ? .bold : .regular)
                    
                    if isCaptain {
                        Text("(C)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                HStack {
                    if let battingHand = player.battingHand {
                        Text(battingHand == .left ? "LH" : "RH")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(3)
                    }
                    
                    if let bowlingStyle = player.bowlingStyle {
                        Text(bowlingStyle.rawValue.capitalized)
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(3)
                    }
                }
            }
            
            Spacer()
            
            Button(action: onTap) {
                Image(systemName: isSelected ? "minus.circle.fill" : "plus.circle")
                    .foregroundColor(isSelected ? .red : .green)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isSelected ? Color.gray.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}

struct MatchSettingsView: View {
    @Binding var oversPerInnings: Int
    @Binding var twoInnings: Bool
    @Binding var wideNoBallRuns: Bool
    
    let oversOptions = [5, 10, 15, 20, 25, 30, 40, 50]
    
    var body: some View {
        Form {
            Section(header: Text("Match Format")) {
                Picker("Overs per Innings", selection: $oversPerInnings) {
                    ForEach(oversOptions, id: \.self) { overs in
                        Text("\(overs) overs").tag(overs)
                    }
                }
                
                Toggle("Two Innings per Side", isOn: $twoInnings)
            }
            
            Section(header: Text("Scoring Rules")) {
                Toggle("Wides/No-balls count for runs", isOn: $wideNoBallRuns)
            }
            
            Section(footer: Text("These settings will apply to the entire match and cannot be changed once the match starts.")) {
                EmptyView()
            }
        }
    }
}

struct TossView: View {
    let teamAName: String
    let teamBName: String
    @Binding var tossWinner: Team?
    @Binding var tossDecision: TossDecision?
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Toss Result")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 20) {
                Text("Who won the toss?")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    Button(action: {
                        tossWinner = .A
                    }) {
                        Text(teamAName)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(tossWinner == .A ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(tossWinner == .A ? .white : .primary)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        tossWinner = .B
                    }) {
                        Text(teamBName)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(tossWinner == .B ? Color.red : Color.gray.opacity(0.2))
                            .foregroundColor(tossWinner == .B ? .white : .primary)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
            
            if tossWinner != nil {
                VStack(spacing: 20) {
                    Text("What did they choose?")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            tossDecision = .bat
                        }) {
                            Text("Bat First")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(tossDecision == .bat ? Color.green : Color.gray.opacity(0.2))
                                .foregroundColor(tossDecision == .bat ? .white : .primary)
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            tossDecision = .field
                        }) {
                            Text("Field First")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(tossDecision == .field ? Color.orange : Color.gray.opacity(0.2))
                                .foregroundColor(tossDecision == .field ? .white : .primary)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct MatchStartView: View {
    let teamAName: String
    let teamBName: String
    let selectedTeamA: [Player]
    let selectedTeamB: [Player]
    let oversPerInnings: Int
    let twoInnings: Bool
    let wideNoBallRuns: Bool
    let tossWinner: Team?
    let tossDecision: TossDecision?
    @Binding var createdMatchId: String?
    
    @EnvironmentObject var poolManager: PoolManager
    @EnvironmentObject var matchManager: MatchManager
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Match Summary")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 15) {
                MatchSummaryRow(title: "Teams", value: "\(teamAName) vs \(teamBName)")
                MatchSummaryRow(title: "Format", value: "\(oversPerInnings) overs\(twoInnings ? " (2 innings)" : "")")
                MatchSummaryRow(title: "Players", value: "\(selectedTeamA.count) vs \(selectedTeamB.count)")
                
                if let tossWinner = tossWinner, let tossDecision = tossDecision {
                    let winnerName = tossWinner == .A ? teamAName : teamBName
                    let decisionText = tossDecision == .bat ? "chose to bat first" : "chose to field first"
                    MatchSummaryRow(title: "Toss", value: "\(winnerName) \(decisionText)")
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            if createdMatchId == nil {
                Button("Create Match") {
                    Task {
                        await createMatch()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(matchManager.isLoading)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("Match Created Successfully!")
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }
            
            if let errorMessage = matchManager.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func createMatch() async {
        guard let poolId = poolManager.currentPool?.id,
              let userId = authManager.currentUserId else {
            return
        }
        
        let matchId = await matchManager.createMatch(
            poolId: poolId,
            createdBy: userId,
            teamAName: teamAName,
            teamBName: teamBName,
            oversPerInnings: oversPerInnings,
            twoInnings: twoInnings,
            wideNoBallRuns: wideNoBallRuns
        )
        
        if let matchId = matchId {
            createdMatchId = matchId
            
            // Add players to teams
            for (index, player) in selectedTeamA.enumerated() {
                if let playerId = player.id {
                    await matchManager.addPlayerToTeam(
                        matchId: matchId,
                        playerId: playerId,
                        team: .A,
                        isCaptain: index == 0
                    )
                }
            }
            
            for (index, player) in selectedTeamB.enumerated() {
                if let playerId = player.id {
                    await matchManager.addPlayerToTeam(
                        matchId: matchId,
                        playerId: playerId,
                        team: .B,
                        isCaptain: index == 0
                    )
                }
            }
            
            // Set toss result
            if let tossWinner = tossWinner, let tossDecision = tossDecision {
                await matchManager.setToss(matchId: matchId, winner: tossWinner, decision: tossDecision)
            }
        }
    }
}

struct MatchSummaryRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// Placeholder for ScoringView
struct ScoringView: View {
    let matchId: String
    
    var body: some View {
        Text("Scoring View for Match: \(matchId)")
            .navigationTitle("Live Scoring")
    }
}

#Preview {
    MatchSetupView()
        .environmentObject(PoolManager())
        .environmentObject(MatchManager())
        .environmentObject(AuthManager())
}