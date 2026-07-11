import SwiftUI

struct SubscriptionView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var analyticsService: AnalyticsService
    @Environment(\.dismiss) private var dismiss

    @State private var showPostPurchaseSyncPrompt = false

    private var isSubscribed: Bool { subscriptionManager.hasPremiumEntitlement }
    private var activePlan: SubscriptionPlan { subscriptionManager.plan }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header
                planSection
                featureList
                if !isSubscribed {
                    actionSection
                }
                footerNote
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 34)
        }
        .background(backgroundGradient.ignoresSafeArea())
        .navigationTitle("MemoryInk+")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Close") { dismiss() }
                    .font(MemoryInkTypography.timestamp.weight(.medium))
                    .foregroundStyle(MemoryInkColors.secondaryInk)
            }
        }
        .alert("Sync Available", isPresented: $showPostPurchaseSyncPrompt) {
            Button("Got it", role: .cancel) {}
        } message: {
            Text("Sign in from Settings anytime to sync your memories across your devices.")
        }
        .onAppear { analyticsService.track(.paywallShown) }
        .task {
            await subscriptionManager.loadDefaultOffering()
            await subscriptionManager.refreshEntitlements()
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundGradient: some View {
        if isSubscribed {
            LinearGradient(
                colors: [
                    MemoryInkColors.amber.opacity(0.22),
                    MemoryInkColors.sunlit.opacity(0.18),
                    MemoryInkColors.paperWarm,
                    MemoryInkColors.parchment
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            LinearGradient(
                colors: [
                    MemoryInkColors.parchment,
                    MemoryInkColors.paperWarm,
                    MemoryInkColors.parchmentDeep.opacity(0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                if isSubscribed {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Active Member")
                            .font(MemoryInkTypography.badge)
                    }
                    .foregroundStyle(MemoryInkColors.amber)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(MemoryInkColors.amber.opacity(0.14))
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .stroke(MemoryInkColors.amber.opacity(0.35), lineWidth: 0.8)
                    }
                } else {
                    Text("7-day free trial")
                        .font(MemoryInkTypography.badge)
                        .foregroundStyle(MemoryInkColors.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(MemoryInkColors.sunlit.opacity(0.22))
                        .clipShape(Capsule())
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("MemoryInk+")
                    .font(.system(size: 40, weight: .semibold, design: .default))
                    .foregroundStyle(MemoryInkColors.ink)

                Text(isSubscribed
                    ? "Thank you for being a member. Your memories sync privately and your AI narratives are unlimited."
                    : "Keep your memories close with private metadata sync, richer narratives, and quieter ways to reflect.")
                    .font(MemoryInkTypography.narrative)
                    .foregroundStyle(MemoryInkColors.secondaryInk)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(isSubscribed ? MemoryInkColors.amber.opacity(0.08) : MemoryInkColors.paper.opacity(0.82))
                .shadow(color: MemoryInkColors.filmShadow.opacity(0.10), radius: 24, x: 0, y: 14)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    isSubscribed ? MemoryInkColors.amber.opacity(0.30) : MemoryInkColors.hairline.opacity(0.26),
                    lineWidth: isSubscribed ? 1.0 : 0.8
                )
        }
    }

    // MARK: - Plan Section

    private var planSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isSubscribed ? "Your plan" : "Choose your plan")
                .font(MemoryInkTypography.eyebrow)
                .foregroundStyle(MemoryInkColors.tertiaryInk)
                .textCase(.uppercase)

            VStack(spacing: 12) {
                let monthlyActive = isSubscribed && activePlan == .monthly
                let yearlyActive  = isSubscribed && activePlan == .yearly

                planCard(
                    title: "Monthly",
                    price: "$5.99/month",
                    note: monthlyActive ? "Your current plan" : "7-day free trial",
                    plan: .monthly,
                    isHighlighted: false,
                    isCurrentPlan: monthlyActive,
                    isDisabled: isSubscribed          // any active sub disables monthly
                )

                planCard(
                    title: "Yearly",
                    price: "$39.99/year",
                    note: yearlyActive ? "Your current plan" : "Best value · 7-day trial",
                    plan: .yearly,
                    isHighlighted: true,
                    isCurrentPlan: yearlyActive,
                    isDisabled: yearlyActive           // only disable yearly if already on yearly
                )
            }
        }
    }

    private func planCard(
        title: String,
        price: String,
        note: String,
        plan: SubscriptionPlan,
        isHighlighted: Bool,
        isCurrentPlan: Bool,
        isDisabled: Bool
    ) -> some View {
        Button {
            guard !isDisabled else { return }
            Task {
                let wasSubscribed = subscriptionManager.hasPremiumEntitlement
                await subscriptionManager.purchase(plan)
                guard !wasSubscribed, subscriptionManager.hasPremiumEntitlement else { return }
                if case .signedIn = authService.state { return }
                showPostPurchaseSyncPrompt = true
            }
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(MemoryInkTypography.subtitle.weight(.medium))
                        .foregroundStyle(isDisabled && !isCurrentPlan ? MemoryInkColors.tertiaryInk : MemoryInkColors.ink)

                    Text(price)
                        .font(.system(size: 22, weight: .semibold, design: .default))
                        .foregroundStyle(isDisabled && !isCurrentPlan ? MemoryInkColors.tertiaryInk : MemoryInkColors.ink)

                    Text(note)
                        .font(MemoryInkTypography.timestamp.weight(.medium))
                        .foregroundStyle(isCurrentPlan ? MemoryInkColors.amber : MemoryInkColors.secondaryInk)
                }

                Spacer()

                if isCurrentPlan {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(MemoryInkColors.amber)
                } else if !isDisabled {
                    Text("Start")
                        .font(MemoryInkTypography.timestamp.weight(.medium))
                        .foregroundStyle(MemoryInkColors.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(MemoryInkColors.parchment.opacity(0.72))
                        .clipShape(Capsule())
                }
            }
            .padding(20)
            .background(planBackground(isHighlighted: isHighlighted, isCurrentPlan: isCurrentPlan))
            .overlay { planStroke(isHighlighted: isHighlighted, isCurrentPlan: isCurrentPlan) }
            .opacity(isDisabled && !isCurrentPlan ? 0.40 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled && !isCurrentPlan)
    }

    // MARK: - Feature List

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Premium features")
                .font(MemoryInkTypography.eyebrow)
                .foregroundStyle(MemoryInkColors.tertiaryInk)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 12) {
                featureRow(icon: "icloud",    title: "Private memory sync")
                featureRow(icon: "sparkles",  title: "More daily AI narratives")
                featureRow(icon: "waveform",  title: "Voice journaling")
                featureRow(icon: "calendar",  title: "Premium recap styles")
            }
            .padding(18)
            .background(
                isSubscribed ? MemoryInkColors.amber.opacity(0.06) : MemoryInkColors.paper.opacity(0.70)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        isSubscribed ? MemoryInkColors.amber.opacity(0.22) : MemoryInkColors.hairline.opacity(0.20),
                        lineWidth: 0.8
                    )
            }
        }
    }

    // MARK: - Action Section (free users only)

    private var actionSection: some View {
        VStack(spacing: 14) {
            Text("7-day free trial included with each plan.")
                .font(MemoryInkTypography.timestamp)
                .foregroundStyle(MemoryInkColors.secondaryInk)

            Button {
                Task { await subscriptionManager.restorePurchases() }
            } label: {
                Text("Restore Purchases")
                    .font(MemoryInkTypography.timestamp.weight(.medium))
                    .foregroundStyle(MemoryInkColors.ink)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }

    // MARK: - Footer

    private var footerNote: some View {
        VStack(spacing: 10) {
            Text("Premium sync is metadata-only. Photos and voice notes stay on device.")
                .font(MemoryInkTypography.timestamp)
                .foregroundStyle(MemoryInkColors.tertiaryInk)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 20) {
                Link("Privacy Policy", destination: URL(string: "https://sites.google.com/view/memoryink-app/home/privacy-policy")!)
                Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            }
            .font(MemoryInkTypography.timestamp.weight(.medium))
            .foregroundStyle(MemoryInkColors.secondaryInk)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }

    // MARK: - Helpers

    private func featureRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: isSubscribed ? "checkmark" : icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(isSubscribed ? MemoryInkColors.amber : MemoryInkColors.secondaryInk)
                .frame(width: 26, height: 26)
                .background(
                    isSubscribed ? MemoryInkColors.amber.opacity(0.12) : MemoryInkColors.parchment.opacity(0.64)
                )
                .clipShape(Circle())

            Text(title)
                .font(MemoryInkTypography.narrativeCompact)
                .foregroundStyle(MemoryInkColors.ink)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }

    private func planBackground(isHighlighted: Bool, isCurrentPlan: Bool) -> some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(
                isCurrentPlan
                    ? MemoryInkColors.amber.opacity(0.08)
                    : isHighlighted ? MemoryInkColors.paper.opacity(0.95) : MemoryInkColors.paper.opacity(0.78)
            )
            .shadow(
                color: MemoryInkColors.filmShadow.opacity(isHighlighted ? 0.12 : 0.07),
                radius: isHighlighted ? 18 : 10,
                x: 0,
                y: isHighlighted ? 10 : 6
            )
    }

    private func planStroke(isHighlighted: Bool, isCurrentPlan: Bool) -> some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(
                isCurrentPlan
                    ? MemoryInkColors.amber.opacity(0.50)
                    : isHighlighted ? MemoryInkColors.sunlit.opacity(0.34) : MemoryInkColors.hairline.opacity(0.22),
                lineWidth: isCurrentPlan ? 1.2 : isHighlighted ? 1.1 : 0.8
            )
    }
}
