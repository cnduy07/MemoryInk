import SwiftUI

struct SubscriptionView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var analyticsService: AnalyticsService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header
                planSection
                featureList
                actionSection
                footerNote
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 34)
        }
        .background(
            LinearGradient(
                colors: [
                    MemoryInkColors.parchment,
                    MemoryInkColors.paperWarm,
                    MemoryInkColors.parchmentDeep.opacity(0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("MemoryInk+")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Close") {
                    dismiss()
                }
                .font(MemoryInkTypography.timestamp.weight(.medium))
                .foregroundStyle(MemoryInkColors.secondaryInk)
            }
        }
        .onAppear {
            analyticsService.track(.paywallShown)
        }
        .task {
            await subscriptionManager.loadDefaultOffering()
            await subscriptionManager.refreshEntitlements()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("7-day free trial")
                    .font(MemoryInkTypography.badge)
                    .foregroundStyle(MemoryInkColors.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(MemoryInkColors.sunlit.opacity(0.22))
                    .clipShape(Capsule())

                Spacer()
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("MemoryInk+")
                    .font(.system(size: 40, weight: .semibold, design: .default))
                    .foregroundStyle(MemoryInkColors.ink)

                Text("Keep your memories close with private metadata sync, richer narratives, and quieter ways to reflect.")
                    .font(MemoryInkTypography.narrative)
                    .foregroundStyle(MemoryInkColors.secondaryInk)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(MemoryInkColors.paper.opacity(0.82))
                .shadow(color: MemoryInkColors.filmShadow.opacity(0.10), radius: 24, x: 0, y: 14)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(MemoryInkColors.hairline.opacity(0.26), lineWidth: 0.8)
        }
    }

    private var planSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose your plan")
                .font(MemoryInkTypography.eyebrow)
                .foregroundStyle(MemoryInkColors.tertiaryInk)
                .textCase(.uppercase)

            VStack(spacing: 12) {
                planCard(
                    title: "Monthly",
                    price: "$5.99/month",
                    note: "7-day free trial",
                    plan: .monthly,
                    isHighlighted: false
                )

                planCard(
                    title: "Yearly",
                    price: "$39.99/year",
                    note: "7-day free trial",
                    plan: .yearly,
                    isHighlighted: true
                )
            }
        }
    }

    private func planCard(
        title: String,
        price: String,
        note: String,
        plan: SubscriptionPlan,
        isHighlighted: Bool
    ) -> some View {
        Button {
            Task {
                await subscriptionManager.purchase(plan)
                analyticsService.track(plan == .monthly ? .monthlyConverted : .yearlyConverted)
            }
        } label: {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(MemoryInkTypography.subtitle.weight(.medium))
                        .foregroundStyle(MemoryInkColors.ink)

                    Text(price)
                        .font(.system(size: 22, weight: .semibold, design: .default))
                        .foregroundStyle(MemoryInkColors.ink)

                    Text(note)
                        .font(MemoryInkTypography.timestamp.weight(.medium))
                        .foregroundStyle(MemoryInkColors.secondaryInk)
                }

                Spacer()

                Text("Start")
                    .font(MemoryInkTypography.timestamp.weight(.medium))
                    .foregroundStyle(MemoryInkColors.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(MemoryInkColors.parchment.opacity(0.72))
                    .clipShape(Capsule())
            }
            .padding(20)
            .background(planBackground(isHighlighted: isHighlighted))
            .overlay { planStroke(isHighlighted: isHighlighted) }
        }
        .buttonStyle(.plain)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Premium features")
                .font(MemoryInkTypography.eyebrow)
                .foregroundStyle(MemoryInkColors.tertiaryInk)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 12) {
                featureRow(icon: "icloud", title: "Private memory sync")
                featureRow(icon: "sparkles", title: "More daily AI narratives")
                featureRow(icon: "waveform", title: "Voice journaling")
                featureRow(icon: "calendar", title: "Premium recap styles")
            }
            .padding(18)
            .background(MemoryInkColors.paper.opacity(0.70))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(MemoryInkColors.hairline.opacity(0.20), lineWidth: 0.8)
            }
        }
    }

    private var actionSection: some View {
        VStack(spacing: 14) {
            Text("7-day free trial included with each plan.")
                .font(MemoryInkTypography.timestamp)
                .foregroundStyle(MemoryInkColors.secondaryInk)

            Button {
                Task {
                    await subscriptionManager.restorePurchases()
                }
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

    private var footerNote: some View {
        Text("Premium sync is metadata-only. Photos and voice notes stay on device.")
            .font(MemoryInkTypography.timestamp)
            .foregroundStyle(MemoryInkColors.tertiaryInk)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func featureRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(MemoryInkColors.secondaryInk)
                .frame(width: 26, height: 26)
                .background(MemoryInkColors.parchment.opacity(0.64))
                .clipShape(Circle())

            Text(title)
                .font(MemoryInkTypography.narrativeCompact)
                .foregroundStyle(MemoryInkColors.ink)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }

    private func planBackground(isHighlighted: Bool) -> some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(isHighlighted ? MemoryInkColors.paper.opacity(0.95) : MemoryInkColors.paper.opacity(0.78))
            .shadow(
                color: MemoryInkColors.filmShadow.opacity(isHighlighted ? 0.12 : 0.07),
                radius: isHighlighted ? 18 : 10,
                x: 0,
                y: isHighlighted ? 10 : 6
            )
    }

    private func planStroke(isHighlighted: Bool) -> some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(
                isHighlighted ? MemoryInkColors.sunlit.opacity(0.34) : MemoryInkColors.hairline.opacity(0.22),
                lineWidth: isHighlighted ? 1.1 : 0.8
            )
    }
}
