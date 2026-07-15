import GoogleSignIn
import SwiftUI

struct ContentView: View {
    @StateObject private var authStore = AuthStore()
    @StateObject private var taskStore = TaskStore()
    @StateObject private var settings = AppSettings()
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                LaunchAnimationView()
            } else if authStore.isAuthenticated {
                MainAppView()
                    .environmentObject(authStore)
                    .environmentObject(taskStore)
                    .environmentObject(settings)
            } else {
                AuthView()
                    .environmentObject(authStore)
                    .environmentObject(settings)
            }
        }
        .onOpenURL { url in
            GIDSignIn.sharedInstance.handle(url)
        }
        .task {
            try? await Task.sleep(for: .seconds(1.4))
            withAnimation(.easeInOut(duration: 0.35)) {
                isLoading = false
            }
        }
        .tint(AppTheme.blue)
        .preferredColorScheme(settings.appearance.colorScheme)
    }
}

struct MainAppView: View {
    @State private var selectedTab: AppTab = .overview
    @State private var showingNewTask = false
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.background.ignoresSafeArea()

            Group {
                switch selectedTab {
                case .overview:
                    DashboardView()
                case .tasks:
                    TaskListView()
                case .stats:
                    AnalysisView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            AppTabBar(selectedTab: $selectedTab, showingAddTask: $showingNewTask)
        }
        .sheet(isPresented: $showingNewTask) {
            AddTaskView()
                .environmentObject(taskStore)
                .environmentObject(settings)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .tint(AppTheme.blue)
    }
}

struct LaunchAnimationView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .stroke(AppTheme.blue.opacity(0.18), lineWidth: 12)
                        .frame(width: 112, height: 112)
                    Circle()
                        .trim(from: 0, to: animate ? 0.82 : 0.12)
                        .stroke(AppTheme.blue, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 112, height: 112)
                        .rotationEffect(.degrees(animate ? 330 : -80))
                    Image(systemName: "checklist")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(AppTheme.blue)
                }

                Text("Todo List")
                    .font(.system(size: 32, weight: .bold))
                Text("Overview  Tasks  Stats  Settings")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.mutedText)
            }
            .scaleEffect(animate ? 1 : 0.92)
            .opacity(animate ? 1 : 0.25)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.05).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct AuthView: View {
    @EnvironmentObject private var authStore: AuthStore
    @State private var isSignUp = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isSigningInWithGoogle = false
    @State private var googleSignInError: String?

    var body: some View {
        ZStack {
            AuthBackgroundView()

            VStack(spacing: 22) {
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.surface.opacity(0.72))
                            .frame(width: 78, height: 78)
                        Image(systemName: isSignUp ? "person.crop.circle.badge.plus" : "checkmark.seal.fill")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundStyle(AppTheme.blue)
                    }
                    .shadow(color: AppTheme.blue.opacity(0.16), radius: 14, y: 8)

                    Text(isSignUp ? "Create account" : "Sign in")
                        .font(.system(size: 36, weight: .bold))
                        .multilineTextAlignment(.center)
                    Text(isSignUp ? "Save tasks, reminders, and settings securely." : "Welcome back to your task workspace.")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.mutedText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                }

                HStack(spacing: 8) {
                    AuthModeButton(title: "Sign In", isSelected: !isSignUp) {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            isSignUp = false
                        }
                    }
                    AuthModeButton(title: "Sign Up", isSelected: isSignUp) {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            isSignUp = true
                        }
                    }
                }
                .padding(5)
                .background(AppTheme.surface.opacity(0.42))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AppTheme.rail.opacity(0.6), lineWidth: 1)
                }

                VStack(spacing: 14) {
                    if isSignUp {
                        AuthTextField(iconName: "person.fill", placeholder: "Name", text: $name, contentType: .name)
                    }

                    AuthTextField(iconName: "envelope.fill", placeholder: "Email", text: $email, contentType: .emailAddress, keyboardType: .emailAddress)
                    AuthSecureField(iconName: "lock.fill", placeholder: "Password", text: $password, contentType: isSignUp ? .newPassword : .password)
                }

                Button {
                    let fallbackName = email.components(separatedBy: "@").first ?? ""
                    authStore.signIn(name: isSignUp ? name : fallbackName, email: email, password: password, mode: isSignUp ? .signUp : .signIn)
                } label: {
                    Text(isSignUp ? "Sign Up" : "Sign In")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(canSubmit ? AppTheme.blue : Color.gray.opacity(0.45))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)

                GoogleSignInButton(isLoading: isSigningInWithGoogle) {
                    signInWithGoogle()
                }
            }
            .frame(maxWidth: 420)
            .padding(.horizontal, 24)
        }
        .alert("Google Sign-In", isPresented: Binding(
            get: { googleSignInError != nil },
            set: { if !$0 { googleSignInError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(googleSignInError ?? "Unable to sign in with Google.")
        }
    }

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        (!isSignUp || !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private func signInWithGoogle() {
        guard !isSigningInWithGoogle else { return }

        guard
            let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
            !clientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            googleSignInError = "Google Sign-In is not configured yet. Add GIDClientID and the reversed client ID URL scheme to the app target."
            return
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        guard let rootViewController = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
        else {
            googleSignInError = "The Google account window could not be opened. Please try again."
            return
        }

        isSigningInWithGoogle = true

        // Clear the SDK session so tapping the button always presents Google's
        // account chooser instead of silently reusing the previous account.
        GIDSignIn.sharedInstance.signOut()
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            Task { @MainActor in
                isSigningInWithGoogle = false

                if let error {
                    let signInError = error as NSError
                    if signInError.code != GIDSignInError.canceled.rawValue {
                        googleSignInError = signInError.localizedDescription
                    }
                    return
                }

                guard let profile = result?.user.profile else {
                    googleSignInError = "Google did not return an account profile. Please try another account."
                    return
                }

                authStore.signIn(
                    name: profile.name,
                    email: profile.email,
                    password: "google-oauth",
                    mode: .signIn
                )
            }
        }
    }
}

struct GoogleSignInButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .frame(width: 28, height: 28)
                } else {
                    Text("G")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(red: 0.91, green: 0.25, blue: 0.20))
                        .frame(width: 28, height: 28)
                        .background(.white)
                        .clipShape(Circle())
                }

                Text(isLoading ? "Opening Google..." : "Continue with Google")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.text)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(AppTheme.surface.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppTheme.rail.opacity(0.8), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

struct AuthModeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isSelected ? .white : AppTheme.text.opacity(0.72))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(isSelected ? AppTheme.blue : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct AuthTextField: View {
    let iconName: String
    let placeholder: String
    @Binding var text: String
    var contentType: UITextContentType?
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.blue)
                .frame(width: 22)
            TextField(placeholder, text: $text)
                .textContentType(contentType)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(contentType == .emailAddress ? .never : .words)
                .font(.system(size: 16, weight: .semibold))
        }
        .authFieldStyle()
    }
}

struct AuthSecureField: View {
    let iconName: String
    let placeholder: String
    @Binding var text: String
    var contentType: UITextContentType?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.blue)
                .frame(width: 22)
            SecureField(placeholder, text: $text)
                .textContentType(contentType)
                .font(.system(size: 16, weight: .semibold))
        }
        .authFieldStyle()
    }
}

struct AuthBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                HStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppTheme.surface.opacity(0.52))
                        .frame(width: 144, height: 144)
                        .rotationEffect(.degrees(14))
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    Circle()
                        .fill(AppTheme.blue.opacity(0.10))
                        .frame(width: 210, height: 210)
                }
            }
            .padding(32)
        }
    }

    private var backgroundColors: [Color] {
        if colorScheme == .dark {
            [
                Color(red: 0.04, green: 0.05, blue: 0.08),
                Color(red: 0.07, green: 0.09, blue: 0.14),
                Color(red: 0.10, green: 0.08, blue: 0.14)
            ]
        } else {
            [
                Color(red: 0.90, green: 0.95, blue: 1.0),
                Color(red: 0.97, green: 0.99, blue: 0.94),
                Color(red: 1.0, green: 0.94, blue: 0.96)
            ]
        }
    }
}

private extension View {
    func authFieldStyle() -> some View {
        self
            .font(.system(size: 16, weight: .semibold))
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(AppTheme.surface.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppTheme.rail.opacity(0.85), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
    }
}

#Preview {
    ContentView()
}
