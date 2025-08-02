import SwiftUI

struct PoolDashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var poolManager: PoolManager
    @State private var showingCreatePool = false
    @State private var showingPoolManagement = false
    @State private var showingNewMatch = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if poolManager.currentPool == nil {
                    // No pool state
                    VStack(spacing: 20) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Player Pool")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Create a new pool or get invited to an existing one to start scoring matches.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Create New Pool") {
                            showingCreatePool = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    // Pool exists
                    ScrollView {
                        VStack(spacing: 20) {
                            // Pool Header
                            VStack(spacing: 8) {
                                Text(poolManager.currentPool?.poolName ?? "Pool")
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                HStack {
                                    Image(systemName: "person.3.fill")
                                    Text("\(poolManager.players.count) Players")
                                    Spacer()
                                    Text(poolManager.currentMembership?.role.displayName ?? "")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(8)
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            
                            // Quick Actions
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 15) {
                                Button(action: {
                                    showingNewMatch = true
                                }) {
                                    ActionCard(
                                        icon: "plus.circle.fill",
                                        title: "New Match",
                                        subtitle: "Start scoring"
                                    )
                                }
                                
                                Button(action: {
                                    showingPoolManagement = true
                                }) {
                                    ActionCard(
                                        icon: "person.3.sequence.fill",
                                        title: "Manage Pool",
                                        subtitle: "Players & settings"
                                    )
                                }
                            }
                            
                            // Recent Players
                            if !poolManager.players.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Players")
                                            .font(.headline)
                                        Spacer()
                                        NavigationLink("View All", destination: PlayerListView())
                                            .font(.caption)
                                    }
                                    
                                    LazyVGrid(columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: 10) {
                                        ForEach(Array(poolManager.players.prefix(4))) { player in
                                            PlayerCard(player: player)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Cricket Scorer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Profile") {
                            // Navigate to profile
                        }
                        Button("Settings") {
                            // Navigate to settings
                        }
                        Divider()
                        Button("Sign Out") {
                            authManager.signOut()
                        }
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
            }
            .sheet(isPresented: $showingCreatePool) {
                CreatePoolView()
                    .environmentObject(poolManager)
            }
            .sheet(isPresented: $showingPoolManagement) {
                PoolManagementView()
                    .environmentObject(poolManager)
            }
            .sheet(isPresented: $showingNewMatch) {
                MatchSetupView()
                    .environmentObject(poolManager)
            }
        }
        .task {
            if let userId = authManager.currentUserId {
                await poolManager.loadUserPools(userId: userId)
            }
        }
    }
}

struct ActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.blue)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct PlayerCard: View {
    let player: Player
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(player.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
            
            HStack {
                if let battingHand = player.battingHand {
                    Text(battingHand == .left ? "LH" : "RH")
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
                
                if let bowlingStyle = player.bowlingStyle {
                    Text(bowlingStyle.rawValue.capitalized)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Spacer()
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

struct CreatePoolView: View {
    @EnvironmentObject var poolManager: PoolManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    @State private var poolName = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Create Player Pool")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                Text("Create a shared pool of players that can be used across multiple matches. You'll be the admin.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextField("Pool Name", text: $poolName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                if let errorMessage = poolManager.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: {
                    Task {
                        if let userId = authManager.currentUserId {
                            await poolManager.createPool(name: poolName, userId: userId)
                            if poolManager.errorMessage == nil {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                }) {
                    HStack {
                        if poolManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text("Create Pool")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(poolManager.isLoading || poolName.isEmpty)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

#Preview {
    PoolDashboardView()
        .environmentObject(AuthManager())
        .environmentObject(PoolManager())
}