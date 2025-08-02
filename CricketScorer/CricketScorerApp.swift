import SwiftUI
import Firebase

@main
struct CricketScorerApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var poolManager = PoolManager()
    @StateObject private var matchManager = MatchManager()
    
    init() {
        FirebaseConfig.shared.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(poolManager)
                .environmentObject(matchManager)
                .onAppear {
                    authManager.checkAuthState()
                }
        }
    }
}