import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var syncService: SyncService
    @EnvironmentObject private var router: AppRouter
    @State private var isShowingEmailSheet = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                section("Subscription") {
                    infoRow("Plan", subscriptionManager.plan.title)
                    infoRow("AI narratives/day", "\(subscriptionManager.dailyNarrativeLimit)")

                    Button("Manage MemoryInk+") {
                        router.path.append(.subscriptionPreview)
                    }
                    .font(MemoryInkTypography.narrativeCompact)
                    .foregroundStyle(MemoryInkColors.ink)
                }

                section("Account") {
                    accountStatus
                    emailSignIn
                    providerButtons
                }

                section("Sync") {
                    infoRow("State", syncDescription)
                    Button(syncButtonTitle) {
                        Task {
                            await syncService.syncMetadataIfAllowed()
                        }
                    }
                    .font(MemoryInkTypography.narrativeCompact)
                    .foregroundStyle(canStartSync ? MemoryInkColors.ink : MemoryInkColors.tertiaryInk)
                    .disabled(!canStartSync)
                }
            }
            .padding(22)
        }
        .background(MemoryInkColors.parchment.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingEmailSheet) {
            EmailAuthSheet(authService: authService)
                .presentationDetents([.medium])
        }
    }

    private var accountStatus: some View {
        Group {
            switch authService.state {
            case .signedOut:
                infoRow("Status", "Not signed in")
            case let .signedIn(session):
                infoRow("Status", "Signed in as \(session.email ?? session.provider.title)")
            case .unavailableMissingConfig:
                infoRow("Status", "Sync unavailable: configuration missing")
            case .error:
                infoRow("Status", "Couldn't connect right now")
            }
        }
    }

    private var emailSignIn: some View {
        Group {
            switch authService.state {
            case .signedOut, .unavailableMissingConfig, .error:
                Button("Continue with Email") {
                    isShowingEmailSheet = true
                }
                .font(MemoryInkTypography.narrativeCompact)
                .foregroundStyle(MemoryInkColors.ink)
            case .signedIn:
                Button("Sign out") {
                    authService.signOut()
                }
                .font(MemoryInkTypography.narrativeCompact)
                .foregroundStyle(MemoryInkColors.secondaryInk)
            }
        }
    }

    private var providerButtons: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sign in with Apple · Coming soon")

            Text("Google Sign-In · Coming soon")
        }
        .font(MemoryInkTypography.narrativeCompact)
        .foregroundStyle(MemoryInkColors.tertiaryInk)
    }

    private var syncDescription: String {
        switch syncService.state {
        case .idle:
            return "Ready"
        case .notConfigured:
            return "Sync unavailable: configuration missing"
        case .localOnly:
            return "Local only"
        case .signedOut:
            return "Sign in to sync"
        case .syncing:
            return "Syncing"
        case let .completed(date):
            return "Last synced \(date.formatted(date: .omitted, time: .shortened))"
        case .failed:
            return "Couldn't sync right now"
        }
    }

    private var canStartSync: Bool {
        guard case .signedIn = authService.state else { return false }

        switch syncService.state {
        case .notConfigured, .syncing:
            return false
        case .idle, .localOnly, .signedOut, .completed, .failed:
            return true
        }
    }

    private var syncButtonTitle: String {
        guard case .signedIn = authService.state else {
            return "Sign in to Sync"
        }

        switch syncService.state {
        case .notConfigured:
            return "Sync Unavailable"
        case .syncing:
            return "Syncing"
        case .idle, .localOnly, .signedOut, .completed, .failed:
            return "Sync Metadata"
        }
    }

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(MemoryInkTypography.eyebrow)
                .foregroundStyle(MemoryInkColors.tertiaryInk)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(18)
            .background(MemoryInkColors.paper.opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(MemoryInkColors.secondaryInk)
            Spacer()
            Text(value)
                .foregroundStyle(MemoryInkColors.ink)
        }
        .font(MemoryInkTypography.narrativeCompact)
    }
}

private struct EmailAuthSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var message: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Continue with Email")
                        .font(MemoryInkTypography.title)
                        .foregroundStyle(MemoryInkColors.ink)

                    Text("Use an email and password to keep your account ready for private memory sync. V1 will not require email verification.")
                        .font(MemoryInkTypography.narrativeCompact)
                        .foregroundStyle(MemoryInkColors.secondaryInk)
                        .lineSpacing(5)
                }

                VStack(alignment: .leading, spacing: 8) {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .font(MemoryInkTypography.narrativeCompact)
                        .padding(14)
                        .background(MemoryInkColors.paper.opacity(0.88))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(MemoryInkColors.hairline.opacity(0.24), lineWidth: 0.8)
                        }

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .font(MemoryInkTypography.narrativeCompact)
                        .padding(14)
                        .background(MemoryInkColors.paper.opacity(0.88))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(MemoryInkColors.hairline.opacity(0.24), lineWidth: 0.8)
                        }

                    if let message {
                        Text(message)
                            .font(MemoryInkTypography.timestamp)
                            .foregroundStyle(MemoryInkColors.tertiaryInk)
                    }
                }

                Spacer(minLength: 0)

                Button {
                    Task {
                        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        if !authService.isValidEmail(normalizedEmail) {
                            message = "Enter a valid email address."
                        } else if !authService.isValidPassword(password) {
                            message = "Password must be at least 6 characters."
                        } else {
                            let success = await authService.signInWithEmail(email, password: password)
                            if success {
                                dismiss()
                            } else if case let .error(errorMessage) = authService.state {
                                message = errorMessage
                            } else {
                                message = "Couldn't sign in right now. Try again."
                            }
                        }
                    }
                } label: {
                    Text("Continue")
                        .font(MemoryInkTypography.narrativeCompact.weight(.medium))
                        .foregroundStyle(MemoryInkColors.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(MemoryInkColors.paper.opacity(0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(MemoryInkColors.hairline.opacity(0.24), lineWidth: 0.8)
                        }
                }
                .buttonStyle(.plain)
            }
            .padding(22)
            .background(MemoryInkColors.parchment.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(MemoryInkColors.secondaryInk)
                }
            }
        }
    }
}
