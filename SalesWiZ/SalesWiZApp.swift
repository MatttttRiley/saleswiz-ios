import SwiftUI

/// SalesWiZ — the Riley AI Consulting CRM on your phone.
/// Same data as the web CRM (https://crm.129-146-5-140.sslip.io/), same
/// login (the shared CRM password), no web views.
@main
struct SalesWiZApp: App {
    @StateObject private var api = APIClient()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(api)
                .tint(Color.salesNavy)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var api: APIClient
    @State private var checkingSession = true
    @State private var attemptedSilentLogin = false

    var body: some View {
        Group {
            if checkingSession {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("SalesWiZ")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            } else if api.loggedIn {
                MainTabs()
            } else {
                LoginView()
            }
        }
        .task {
            guard !attemptedSilentLogin else { return }
            attemptedSilentLogin = true
            _ = await api.trySilentLogin()
            checkingSession = false
        }
    }
}

struct MainTabs: View {
    var body: some View {
        TabView {
            NavigationStack { DashboardView() }
                .tabItem { Label("Dashboard", systemImage: "gauge.with.needle") }
            NavigationStack { CallListView() }
                .tabItem { Label("Calls", systemImage: "phone.fill") }
            NavigationStack { LeadsView() }
                .tabItem { Label("Leads", systemImage: "person.2.fill") }
            NavigationStack { InboxView() }
                .tabItem { Label("Inbox", systemImage: "envelope.fill") }
            NavigationStack { InterestView() }
                .tabItem { Label("Interest", systemImage: "star.fill") }
            NavigationStack { ActionsView() }
                .tabItem { Label("Actions", systemImage: "checklist") }
        }
    }
}

// MARK: - Login

struct LoginView: View {
    @EnvironmentObject var api: APIClient
    @State private var password = ""
    @FocusState private var passwordFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 48)

                // App mark: navy rounded square, white W, copper rule.
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.salesNavy)
                        .frame(width: 112, height: 112)
                    VStack(spacing: 6) {
                        Text("W")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundStyle(.white)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.salesCopper)
                            .frame(width: 44, height: 6)
                    }
                }

                VStack(spacing: 6) {
                    Text("SalesWiZ")
                        .font(.largeTitle.weight(.bold))
                    Text("One home for every lead.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .focused($passwordFocused)
                        .submitLabel(.go)
                        .onSubmit { Task { await logIn() } }
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    if let error = api.authError {
                        Text(error)
                            .font(.callout)
                            .foregroundStyle(.red)
                    }

                    Button(action: { Task { await logIn() } }) {
                        if api.isAuthenticating {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        } else {
                            Text("Log in")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(password.isEmpty || api.isAuthenticating)
                }
                .padding(.horizontal, 32)

                Text("Shared login for Matt + Philbert.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()
            }
        }
        .onAppear { passwordFocused = true }
    }

    private func logIn() async {
        guard !password.isEmpty else { return }
        _ = await api.login(password: password)
    }
}

// MARK: - Brand colors

extension Color {
    /// Deep navy from the web CRM.
    static let salesNavy = Color(red: 27 / 255, green: 47 / 255, blue: 74 / 255)
    /// Copper accent from the web CRM.
    static let salesCopper = Color(red: 232 / 255, green: 163 / 255, blue: 76 / 255)
}
