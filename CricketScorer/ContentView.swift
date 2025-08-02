import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                PoolDashboardView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            authManager.checkAuthState()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
        .environmentObject(PoolManager())
        .environmentObject(MatchManager())
}