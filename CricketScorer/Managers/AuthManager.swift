import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class AuthManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let db = FirebaseConfig.shared.db
    
    init() {
        addAuthStateListener()
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    private func addAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, firebaseUser in
            Task { @MainActor in
                if let firebaseUser = firebaseUser {
                    await self?.loadUserProfile(firebaseUser: firebaseUser)
                } else {
                    self?.user = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    func checkAuthState() {
        if let firebaseUser = Auth.auth().currentUser {
            Task {
                await loadUserProfile(firebaseUser: firebaseUser)
            }
        }
    }
    
    private func loadUserProfile(firebaseUser: FirebaseAuth.User) async {
        do {
            let document = try await db.collection("Users").document(firebaseUser.uid).getDocument()
            if document.exists {
                let userData = try document.data(as: User.self)
                self.user = userData
                self.isAuthenticated = true
            } else {
                // Create user profile if it doesn't exist
                await createUserProfile(firebaseUser: firebaseUser)
            }
        } catch {
            print("Error loading user profile: \(error)")
            self.errorMessage = "Failed to load user profile"
        }
    }
    
    private func createUserProfile(firebaseUser: FirebaseAuth.User) async {
        do {
            let newUser = User(
                id: firebaseUser.uid,
                email: firebaseUser.email ?? "",
                createdAt: Date()
            )
            
            try await db.collection("Users").document(firebaseUser.uid).setData(from: newUser)
            self.user = newUser
            self.isAuthenticated = true
        } catch {
            print("Error creating user profile: \(error)")
            self.errorMessage = "Failed to create user profile"
        }
    }
    
    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            await createUserProfile(firebaseUser: result.user)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            await loadUserProfile(firebaseUser: result.user)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            user = nil
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
}