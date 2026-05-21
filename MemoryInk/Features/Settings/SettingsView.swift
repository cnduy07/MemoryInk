import AuthenticationServices
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var syncService: SyncService
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var notificationService: NotificationService
    @State private var isShowingEmailSheet = false
    @State private var emailSheetMode: AuthMode = .signIn
    @State private var isAuthLoading = false
    @State private var toastMessage: String?
    @State private var toastIsError = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                section("Subscription") {
                    infoRow("Plan", subscriptionManager.plan.title, icon: "sparkles")
                    infoRow("AI narratives/day", "\(subscriptionManager.dailyNarrativeLimit)", icon: "wand.and.sparkles")

                    Button {
                        router.path.append(.subscriptionPreview)
                    } label: {
                        HStack(spacing: 6) {
                            Text("Manage MemoryInk+")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                        }
                    }
                    .font(MemoryInkTypography.narrativeCompact)
                    .foregroundStyle(MemoryInkColors.ink)
                    .buttonStyle(.plain)
                }

                section("Account") {
                    accountSection
                }

                section("Sync") {
                    infoRow("Sync", syncDescription, icon: "arrow.triangle.2.circlepath")
                    Button(syncButtonTitle) {
                        Task {
                            await syncService.syncMetadataIfAllowed()
                        }
                    }
                    .font(MemoryInkTypography.narrativeCompact)
                    .foregroundStyle(canStartSync ? MemoryInkColors.ink : MemoryInkColors.tertiaryInk)
                    .disabled(!canStartSync)
                }

                section("Daily Reminder") {
                    dailyReminderSection
                }
            }
            .padding(22)
        }
        .background(MemoryInkColors.parchment.ignoresSafeArea())
        .navigationTitle("Account & Settings")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            if let toastMessage {
                ToastView(message: toastMessage, isError: toastIsError)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: toastMessage)
        .sheet(isPresented: $isShowingEmailSheet) {
            EmailAuthSheet(authService: authService, mode: emailSheetMode) { result in
                switch result {
                case .success:
                    showToast("Signed in.", isError: false)
                case let .failure(message):
                    showToast(message, isError: true)
                }
            }
                .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private var accountSection: some View {
        switch authService.state {
        case .signedOut, .unavailableMissingConfig, .error:
            infoRow("Status", accountStatusText, icon: "person.circle")

            if isAuthLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    appleSignInButton

                    Button {
                        emailSheetMode = .signIn
                        isShowingEmailSheet = true
                    } label: {
                        HStack(spacing: 9) {
                            Image(systemName: "envelope")
                                .font(.system(size: 14, weight: .medium))

                            Text("Continue with Email")
                                .font(MemoryInkTypography.narrativeCompact.weight(.medium))
                        }
                        .foregroundStyle(MemoryInkColors.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(MemoryInkColors.paper.opacity(0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(MemoryInkColors.hairline.opacity(0.24), lineWidth: 0.8)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

        case let .signedIn(session):
            infoRow("Signed in as", session.email ?? session.provider.title, icon: "person.circle.fill")

            Button("Sign out") {
                authService.signOut()
            }
            .font(MemoryInkTypography.narrativeCompact)
            .foregroundStyle(Color.red.opacity(0.75))
        }
    }

    private var accountStatusText: String {
        switch authService.state {
        case .signedOut:
            return "Not signed in"
        case let .signedIn(session):
            return "Signed in as \(session.email ?? session.provider.title)"
        case .unavailableMissingConfig:
            return "Sync unavailable: configuration missing"
        case .error:
            return "Couldn't connect right now"
        }
    }

    private var appleSignInButton: some View {
        Button {
            authService.presentationAnchor = currentPresentationAnchor()
            isAuthLoading = true
            Task {
                let result = await authService.signInWithApple()
                isAuthLoading = false
                switch result {
                case .success:
                    showToast("Signed in.", isError: false)
                case let .failure(message):
                    showToast(message, isError: true)
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "applelogo")
                    .font(.system(size: 16, weight: .medium))

                Text("Sign in with Apple")
                    .font(MemoryInkTypography.narrativeCompact.weight(.medium))
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var dailyReminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "bell")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(MemoryInkColors.tertiaryInk)
                    .frame(width: 22, height: 22)
                    .background(MemoryInkColors.parchment.opacity(0.70))
                    .clipShape(Circle())

                Toggle(
                    "Remind me daily",
                    isOn: Binding(
                        get: { notificationService.isEnabled },
                        set: { isEnabled in
                            if isEnabled {
                                Task {
                                    await notificationService.requestAndEnable()
                                }
                            } else {
                                notificationService.disable()
                            }
                        }
                    )
                )
                .font(MemoryInkTypography.narrativeCompact)
                .foregroundStyle(MemoryInkColors.secondaryInk)
                .tint(MemoryInkColors.sage)
            }

            if notificationService.isEnabled {
                DatePicker(
                    "Time",
                    selection: $notificationService.reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .font(MemoryInkTypography.narrativeCompact)
                .foregroundStyle(MemoryInkColors.secondaryInk)
                .tint(MemoryInkColors.sage)
                .onChange(of: notificationService.reminderTime) { newValue in
                    notificationService.updateTime(newValue)
                }
            }
        }
    }

    private func currentPresentationAnchor() -> ASPresentationAnchor? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
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
            return "Last synced \(date.formatted(date: .abbreviated, time: .shortened))"
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
        case .completed:
            return "Sync again"
        case .idle, .localOnly, .signedOut, .failed:
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
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(MemoryInkColors.paper.opacity(0.88))
                    .shadow(color: MemoryInkColors.filmShadow.opacity(0.07), radius: 16, x: 0, y: 8)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(MemoryInkColors.hairline.opacity(0.20), lineWidth: 0.7)
            }
        }
    }

    private func infoRow(_ title: String, _ value: String, icon: String? = nil) -> some View {
        HStack(spacing: 10) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(MemoryInkColors.tertiaryInk)
                    .frame(width: 22, height: 22)
                    .background(MemoryInkColors.parchment.opacity(0.70))
                    .clipShape(Circle())
            }

            Text(title)
                .foregroundStyle(MemoryInkColors.secondaryInk)
            Spacer()
            Text(value)
                .foregroundStyle(MemoryInkColors.ink)
        }
        .font(MemoryInkTypography.narrativeCompact)
    }

    private func showToast(_ message: String, isError: Bool) {
        toastMessage = message
        toastIsError = isError
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            toastMessage = nil
        }
    }
}

private struct EmailAuthSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authService: AuthService
    let mode: AuthMode
    let onComplete: (AuthResult) -> Void
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var message: String?
    @State private var isSignIn: Bool
    @State private var isLoading = false

    init(
        authService: AuthService,
        mode: AuthMode = .signIn,
        onComplete: @escaping (AuthResult) -> Void = { _ in }
    ) {
        self.authService = authService
        self.mode = mode
        self.onComplete = onComplete
        _isSignIn = State(initialValue: mode == .signIn)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                authModeToggle

                VStack(alignment: .leading, spacing: 10) {
                    Text(isSignIn ? "Sign In" : "Create Account")
                        .font(MemoryInkTypography.title)
                        .foregroundStyle(MemoryInkColors.ink)

                    Text(isSignIn ? "Sign in to enable private memory sync across your devices." : "Create a free account to keep your memories safe. No email verification required.")
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
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(MemoryInkColors.hairline.opacity(0.24), lineWidth: 0.8)
                        }
                        .disabled(isLoading)

                    SecureField("Password", text: $password)
                        .textContentType(isSignIn ? .password : .newPassword)
                        .font(MemoryInkTypography.narrativeCompact)
                        .padding(14)
                        .background(MemoryInkColors.paper.opacity(0.88))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(MemoryInkColors.hairline.opacity(0.24), lineWidth: 0.8)
                        }
                        .disabled(isLoading)

                    if !isSignIn {
                        SecureField("Confirm password", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .font(MemoryInkTypography.narrativeCompact)
                            .padding(14)
                            .background(MemoryInkColors.paper.opacity(0.88))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(MemoryInkColors.hairline.opacity(0.24), lineWidth: 0.8)
                            }
                            .disabled(isLoading)
                    }

                    if let message {
                        Text(message)
                            .font(MemoryInkTypography.timestamp)
                            .foregroundStyle(MemoryInkColors.ink)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(MemoryInkColors.rosewood.opacity(0.10))
                            .clipShape(Capsule())
                    }
                }

                Spacer(minLength: 0)

                Button {
                    Task {
                        await submit()
                    }
                } label: {
                    Group {
                        if isLoading {
                            LoadingIndicator()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Continue")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .font(MemoryInkTypography.narrativeCompact.weight(.medium))
                    .foregroundStyle(MemoryInkColors.ink)
                    .frame(height: 52)
                    .background(MemoryInkColors.paper.opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(MemoryInkColors.hairline.opacity(0.24), lineWidth: 0.8)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }
            .padding(22)
            .background(MemoryInkColors.parchment.ignoresSafeArea())
            .navigationTitle("MemoryInk")
            .navigationBarTitleDisplayMode(.inline)
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

    private var authModeToggle: some View {
        HStack {
            authModeButton("Sign In", isSelected: isSignIn) {
                isSignIn = true
                message = nil
            }

            Spacer()

            authModeButton("Create Account", isSelected: !isSignIn) {
                isSignIn = false
                message = nil
            }
        }
        .frame(maxWidth: .infinity)
        .disabled(isLoading)
    }

    private func authModeButton(
        _ title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Text(title)
                    .font(MemoryInkTypography.narrativeCompact.weight(.medium))
                    .foregroundStyle(isSelected ? MemoryInkColors.ink : MemoryInkColors.tertiaryInk)

                Rectangle()
                    .fill(MemoryInkColors.ink.opacity(isSelected ? 1 : 0))
                    .frame(height: 2)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(.plain)
    }

    private func submit() async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !authService.isValidEmail(normalizedEmail) {
            message = "Enter a valid email address."
            return
        }

        if !authService.isValidPassword(password) {
            message = "Password must be at least 6 characters."
            return
        }

        if !isSignIn && password != confirmPassword {
            message = "Passwords don't match."
            return
        }

        let result = isSignIn
            ? await authService.signInWithEmail(normalizedEmail, password: password)
            : await authService.createAccount(email: normalizedEmail, password: password)

        switch result {
        case .success:
            onComplete(result)
            dismiss()
        case let .failure(errorMessage):
            message = errorMessage
        }
    }
}
