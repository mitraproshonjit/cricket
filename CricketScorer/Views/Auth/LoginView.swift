import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUpMode = false
    @State private var showingForgotPassword = false
    @State private var resetEmail = ""
    @State private var isLogoAnimating = true
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.15, blue: 0.2),
                        Color(red: 0.1, green: 0.25, blue: 0.35),
                        Color(red: 0.15, green: 0.35, blue: 0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Floating elements for depth
                Circle()
                    .fill(EmotionalGradient.cricket.opacity(0.1))
                    .frame(width: 200)
                    .blur(radius: 50)
                    .offset(x: -100, y: -200)
                    .emotionalPulse()
                
                Circle()
                    .fill(EmotionalGradient.sunset.opacity(0.08))
                    .frame(width: 150)
                    .blur(radius: 40)
                    .offset(x: 120, y: 300)
                    .emotionalPulse()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // App Logo/Title with liquid glass
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(EmotionalGradient.cricket.opacity(0.3))
                                .frame(width: 120, height: 120)
                                .blur(radius: 20)
                                .emotionalPulse(isActive: isLogoAnimating)
                            
                            Image(systemName: "cricket.ball.fill")
                                .font(.system(size: 50, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, .white.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Cricket Scorer")
                                .font(.cricketTitle)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, .white.opacity(0.9)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("Score weekend amateur cricket matches")
                                .font(.cricketCaption)
                                .foregroundStyle(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 30)
                    .liquidGlass(intensity: 0.3, cornerRadius: 30, borderOpacity: 0.3)
                
                    // Login Form with liquid glass
                    VStack(spacing: 20) {
                        VStack(spacing: 16) {
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.cricketCaption)
                                    .foregroundStyle(.white.opacity(0.8))
                                
                                TextField("Enter your email", text: $email)
                                    .font(.cricketBody)
                                    .foregroundStyle(.white)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial.opacity(0.3))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.cricketCaption)
                                    .foregroundStyle(.white.opacity(0.8))
                                
                                SecureField("Enter your password", text: $password)
                                    .font(.cricketBody)
                                    .foregroundStyle(.white)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial.opacity(0.3))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                            }
                            
                            if let errorMessage = authManager.errorMessage {
                                Text(errorMessage)
                                    .font(.cricketCaption)
                                    .foregroundStyle(.red.opacity(0.9))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.red.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(.red.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                            }
                        }
                        
                        // Main action button
                        Button(action: {
                            HapticManager.shared.impact(.medium)
                            Task {
                                if isSignUpMode {
                                    await authManager.signUp(email: email, password: password)
                                } else {
                                    await authManager.signIn(email: email, password: password)
                                }
                            }
                        }) {
                            HStack(spacing: 12) {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text(isSignUpMode ? "Create Account" : "Sign In")
                                    .font(.cricketSubheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(LiquidButton(gradient: EmotionalGradient.cricket))
                        .disabled(authManager.isLoading || email.isEmpty || password.isEmpty)
                        
                        // Secondary actions
                        VStack(spacing: 12) {
                            Button(action: {
                                HapticManager.shared.selection()
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    isSignUpMode.toggle()
                                    authManager.errorMessage = nil
                                }
                            }) {
                                Text(isSignUpMode ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                    .font(.cricketCaption)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            
                            if !isSignUpMode {
                                Button("Forgot Password?") {
                                    HapticManager.shared.selection()
                                    showingForgotPassword = true
                                }
                                .font(.cricketCaption)
                                .foregroundStyle(EmotionalGradient.sunset.opacity(0.9))
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 32)
                    .liquidGlass(intensity: 0.4, cornerRadius: 24, borderOpacity: 0.25)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView(resetEmail: $resetEmail)
                .environmentObject(authManager)
        }
    }
}

struct ForgotPasswordView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var resetEmail: String
    @Environment(\.presentationMode) var presentationMode
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Reset Password")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                Text("Enter your email address and we'll send you a link to reset your password.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextField("Email", text: $resetEmail)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal)
                
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: {
                    Task {
                        await authManager.resetPassword(email: resetEmail)
                        if authManager.errorMessage == nil {
                            showingSuccess = true
                        }
                    }
                }) {
                    HStack {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text("Send Reset Link")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(authManager.isLoading || resetEmail.isEmpty)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert("Reset Link Sent", isPresented: $showingSuccess) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Check your email for password reset instructions.")
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}