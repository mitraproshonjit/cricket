import SwiftUI

struct PoolManagementView: View {
    @EnvironmentObject var poolManager: PoolManager
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Management", selection: $selectedTab) {
                    Text("Players").tag(0)
                    Text("Members").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    PlayerManagementView()
                } else {
                    MemberManagementView()
                }
            }
            .navigationTitle("Manage Pool")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct PlayerManagementView: View {
    @EnvironmentObject var poolManager: PoolManager
    @State private var showingAddPlayer = false
    
    var body: some View {
        List {
            if poolManager.canManagePlayers {
                Button(action: {
                    showingAddPlayer = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                        Text("Add Player")
                    }
                }
            }
            
            ForEach(poolManager.players) { player in
                PlayerRowView(player: player)
            }
        }
        .sheet(isPresented: $showingAddPlayer) {
            AddPlayerView()
                .environmentObject(poolManager)
        }
    }
}

struct PlayerRowView: View {
    let player: Player
    @EnvironmentObject var poolManager: PoolManager
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(player.name)
                    .font(.headline)
                
                HStack {
                    if let battingHand = player.battingHand {
                        Label(battingHand.displayName, systemImage: "figure.cricket")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    if let bowlingStyle = player.bowlingStyle {
                        Label(bowlingStyle.displayName, systemImage: "baseball.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                if player.linkedUserId != nil {
                    Label("Linked to user", systemImage: "person.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            if poolManager.canManagePlayers {
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 2)
        .alert("Delete Player", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    if let playerId = player.id {
                        await poolManager.removePlayer(playerId: playerId)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete \(player.name)? This cannot be undone.")
        }
    }
}

struct AddPlayerView: View {
    @EnvironmentObject var poolManager: PoolManager
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var battingHand: BattingHand?
    @State private var bowlingHand: BowlingHand?
    @State private var bowlingStyle: BowlingStyle?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Player Name", text: $name)
                }
                
                Section(header: Text("Batting")) {
                    Picker("Batting Hand", selection: $battingHand) {
                        Text("Not specified").tag(nil as BattingHand?)
                        ForEach(BattingHand.allCases, id: \.self) { hand in
                            Text(hand.displayName).tag(hand as BattingHand?)
                        }
                    }
                }
                
                Section(header: Text("Bowling")) {
                    Picker("Bowling Hand", selection: $bowlingHand) {
                        Text("Not specified").tag(nil as BowlingHand?)
                        ForEach(BowlingHand.allCases, id: \.self) { hand in
                            Text(hand.displayName).tag(hand as BowlingHand?)
                        }
                    }
                    
                    Picker("Bowling Style", selection: $bowlingStyle) {
                        Text("Not specified").tag(nil as BowlingStyle?)
                        ForEach(BowlingStyle.allCases, id: \.self) { style in
                            Text(style.displayName).tag(style as BowlingStyle?)
                        }
                    }
                }
                
                if let errorMessage = poolManager.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Player")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Add") {
                    Task {
                        await poolManager.addPlayer(
                            name: name,
                            battingHand: battingHand,
                            bowlingHand: bowlingHand,
                            bowlingStyle: bowlingStyle
                        )
                        if poolManager.errorMessage == nil {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                .disabled(name.isEmpty || poolManager.isLoading)
            )
        }
    }
}

struct MemberManagementView: View {
    @EnvironmentObject var poolManager: PoolManager
    @State private var showingInviteUser = false
    
    var body: some View {
        List {
            if poolManager.canManageUsers || poolManager.canAssignModerators {
                Button(action: {
                    showingInviteUser = true
                }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.blue)
                        Text("Invite User")
                    }
                }
            }
            
            ForEach(poolManager.poolMembers) { membership in
                MemberRowView(membership: membership)
            }
        }
        .sheet(isPresented: $showingInviteUser) {
            InviteUserView()
                .environmentObject(poolManager)
        }
    }
}

struct MemberRowView: View {
    let membership: PoolMembership
    @EnvironmentObject var poolManager: PoolManager
    @State private var showingRoleSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("User ID: \(String(membership.userId.prefix(8)))...")
                    .font(.headline)
                
                Text("Role: \(membership.role.displayName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Joined: \(membership.joinedAt, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if poolManager.canAssignModerators {
                Button("Change Role") {
                    showingRoleSheet = true
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
            
            if poolManager.canManageUsers {
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 2)
        .actionSheet(isPresented: $showingRoleSheet) {
            ActionSheet(
                title: Text("Change Role"),
                buttons: PoolRole.allCases.map { role in
                    .default(Text(role.displayName)) {
                        Task {
                            if let membershipId = membership.id {
                                await poolManager.updateUserRole(membershipId: membershipId, newRole: role)
                            }
                        }
                    }
                } + [.cancel()]
            )
        }
        .alert("Remove Member", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                Task {
                    if let membershipId = membership.id {
                        await poolManager.removeUser(membershipId: membershipId)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to remove this member from the pool?")
        }
    }
}

struct InviteUserView: View {
    @EnvironmentObject var poolManager: PoolManager
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var selectedRole: PoolRole = .user
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("User Information")) {
                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section(header: Text("Role")) {
                    Picker("Role", selection: $selectedRole) {
                        ForEach(PoolRole.allCases, id: \.self) { role in
                            Text(role.displayName).tag(role)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(footer: Text("The user will be added to the pool immediately if they have an account.")) {
                    EmptyView()
                }
                
                if let errorMessage = poolManager.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Invite User")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Invite") {
                    Task {
                        await poolManager.inviteUser(email: email, role: selectedRole)
                        if poolManager.errorMessage == nil {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                .disabled(email.isEmpty || poolManager.isLoading)
            )
        }
    }
}

struct PlayerListView: View {
    @EnvironmentObject var poolManager: PoolManager
    
    var body: some View {
        List(poolManager.players) { player in
            PlayerRowView(player: player)
        }
        .navigationTitle("All Players")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    PoolManagementView()
        .environmentObject(PoolManager())
}