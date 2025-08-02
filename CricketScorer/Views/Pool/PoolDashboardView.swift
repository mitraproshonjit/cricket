import SwiftUI

struct PoolDashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var poolManager: PoolManager
    @State private var showingCreatePool = false
    @State private var showingPoolManagement = false
    @State private var showingNewMatch = false
    @State private var animateCards = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic background
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.1, blue: 0.15),
                        Color(red: 0.08, green: 0.18, blue: 0.25),
                        Color(red: 0.12, green: 0.25, blue: 0.35)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Floating background elements
                Circle()
                    .fill(EmotionalGradient.cricket.opacity(0.08))
                    .frame(width: 250)
                    .blur(radius: 60)
                    .offset(x: 150, y: -300)
                    .emotionalPulse()
                
                Circle()
                    .fill(EmotionalGradient.ocean.opacity(0.06))
                    .frame(width: 200)
                    .blur(radius: 50)
                    .offset(x: -120, y: 400)
                    .emotionalPulse()
                
                ScrollView {
                    VStack(spacing: 24) {
                        if poolManager.currentPool == nil {
                            // No pool state with liquid glass
                            VStack(spacing: 24) {
                                Spacer(minLength: 100)
                                
                                VStack(spacing: 20) {
                                    ZStack {
                                        Circle()
                                            .fill(EmotionalGradient.neutral.opacity(0.3))
                                            .frame(width: 100, height: 100)
                                            .blur(radius: 20)
                                        
                                        Image(systemName: "person.3.fill")
                                            .font(.system(size: 50, weight: .semibold))
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                    
                                    VStack(spacing: 12) {
                                        Text("No Player Pool")
                                            .font(.cricketHeadline)
                                            .foregroundStyle(.white)
                                        
                                        Text("Create a new pool or get invited to an existing one to start scoring matches.")
                                            .font(.cricketBody)
                                            .foregroundStyle(.white.opacity(0.7))
                                            .multilineTextAlignment(.center)
                                            .lineLimit(3)
                                    }
                                    
                                    Button("Create New Pool") {
                                        HapticManager.shared.impact(.medium)
                                        showingCreatePool = true
                                    }
                                    .buttonStyle(LiquidButton(gradient: EmotionalGradient.cricket))
                                    .padding(.top, 8)
                                }
                                .padding(.horizontal, 40)
                                .padding(.vertical, 40)
                                .liquidGlass(intensity: 0.4, cornerRadius: 28, borderOpacity: 0.3)
                                .padding(.horizontal, 20)
                                
                                Spacer()
                            }
                        } else {
                            // Pool exists with enhanced liquid glass design
                            VStack(spacing: 24) {
                                // Pool Header with animated gradient
                                VStack(spacing: 16) {
                                    // Pool name with gradient text
                                    Text(poolManager.currentPool?.poolName ?? "Pool")
                                        .font(.cricketTitle)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.white, .white.opacity(0.9)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    // Pool stats row
                                    HStack(spacing: 20) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "person.3.fill")
                                                .foregroundStyle(EmotionalGradient.cricket)
                                            Text("\(poolManager.players.count) Players")
                                                .font(.cricketBody)
                                                .foregroundStyle(.white.opacity(0.8))
                                        }
                                        
                                        Spacer()
                                        
                                        // Role badge with gradient
                                        Text(poolManager.currentMembership?.role.displayName ?? "")
                                            .font(.cricketCaption)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(EmotionalGradient.cricket.opacity(0.8))
                                                    .overlay(
                                                        Capsule()
                                                            .stroke(.white.opacity(0.3), lineWidth: 1)
                                                    )
                                            )
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 24)
                                .liquidGlass(intensity: 0.5, cornerRadius: 20, borderOpacity: 0.3)
                            
                                // Quick Actions with liquid glass cards
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 16) {
                                    LiquidActionCard(
                                        icon: "plus.circle.fill",
                                        title: "New Match",
                                        subtitle: "Start scoring",
                                        gradient: EmotionalGradient.cricket,
                                        action: {
                                            HapticManager.shared.impact(.medium)
                                            showingNewMatch = true
                                        }
                                    )
                                    .scaleEffect(animateCards ? 1.0 : 0.8)
                                    .opacity(animateCards ? 1.0 : 0.0)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateCards)
                                    
                                    LiquidActionCard(
                                        icon: "person.3.sequence.fill",
                                        title: "Manage Pool",
                                        subtitle: "Players & settings",
                                        gradient: EmotionalGradient.ocean,
                                        action: {
                                            HapticManager.shared.impact(.medium)
                                            showingPoolManagement = true
                                        }
                                    )
                                    .scaleEffect(animateCards ? 1.0 : 0.8)
                                    .opacity(animateCards ? 1.0 : 0.0)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateCards)
                                }
                            
                                // Recent Players with liquid glass
                                if !poolManager.players.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack {
                                            Text("Players")
                                                .font(.cricketHeadline)
                                                .foregroundStyle(.white)
                                            
                                            Spacer()
                                            
                                            NavigationLink(destination: PlayerListView()) {
                                                HStack(spacing: 4) {
                                                    Text("View All")
                                                        .font(.cricketCaption)
                                                    Image(systemName: "arrow.right")
                                                        .font(.cricketCaption)
                                                }
                                                .foregroundStyle(EmotionalGradient.cricket)
                                            }
                                        }
                                        
                                        LazyVGrid(columns: [
                                            GridItem(.flexible()),
                                            GridItem(.flexible())
                                        ], spacing: 12) {
                                            ForEach(Array(poolManager.players.prefix(4).enumerated()), id: \.element.id) { index, player in
                                                LiquidPlayerCard(player: player)
                                                    .scaleEffect(animateCards ? 1.0 : 0.8)
                                                    .opacity(animateCards ? 1.0 : 0.0)
                                                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3 + Double(index) * 0.1), value: animateCards)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 24)
                                    .liquidGlass(intensity: 0.4, cornerRadius: 20, borderOpacity: 0.25)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            HapticManager.shared.selection()
                        }) {
                            Label("Profile", systemImage: "person.circle")
                        }
                        
                        Button(action: {
                            HapticManager.shared.selection()
                        }) {
                            Label("Settings", systemImage: "gear")
                        }
                        
                        Divider()
                        
                        Button(action: {
                            HapticManager.shared.impact(.light)
                            authManager.signOut()
                        }) {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial.opacity(0.8))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.3), lineWidth: 1)
                                )
                            
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3)) {
                    animateCards = true
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

struct LiquidActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: LinearGradient
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(gradient.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .blur(radius: 8)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.cricketSubheadline)
                        .foregroundStyle(.white)
                    
                    Text(subtitle)
                        .font(.cricketCaption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
        }
        .buttonStyle(PlainButtonStyle())
        .liquidCard(isPressed: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct LiquidPlayerCard: View {
    let player: Player
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Player name with gradient
            Text(player.name)
                .font(.cricketBody)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .lineLimit(1)
            
            // Player attributes
            VStack(alignment: .leading, spacing: 6) {
                if let battingHand = player.battingHand {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.cricket")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(EmotionalGradient.teamA)
                        
                        Text(battingHand == .left ? "Left-handed" : "Right-handed")
                            .font(.cricketCaption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                
                if let bowlingStyle = player.bowlingStyle {
                    HStack(spacing: 6) {
                        Image(systemName: "baseball.fill")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(EmotionalGradient.teamB)
                        
                        Text(bowlingStyle.displayName)
                            .font(.cricketCaption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                
                if player.battingHand == nil && player.bowlingStyle == nil {
                    Text("No details")
                        .font(.cricketCaption)
                        .foregroundStyle(.white.opacity(0.5))
                        .italic()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.3),
                                    .clear,
                                    .white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            HapticManager.shared.selection()
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: {})
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