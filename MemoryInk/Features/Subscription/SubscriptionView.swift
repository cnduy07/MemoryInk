import SwiftUI

struct SubscriptionView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var analyticsService: AnalyticsService

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                planSection
                featureList
                actionSection
                configurationNote
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 34)
        }
        .background(MemoryInkColors.parchment.ignoresSafeArea())
        .navigationTitle("MemoryInk+")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            analyticsService.track(.paywallShown)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MemoryInk+")
                .font(MemoryInkTypography.title)
                .foregroundStyle(MemoryInkColors.ink)

            Text("A quieter way to keep your memories close, with private metadata sync and more room for narratives.")
                .font(MemoryInkTypography.narrative)
                .foregroundStyle(MemoryInkColors.secondaryInk)
                .lineSpacing(6)
        }
    }

    private var planSection: some View {
        VStack(spacing: 12) {
            planCard(title: "Monthly", subtitle: "$5.99/month after 7 days", plan: .monthly)
            planCard(title: "Yearly", subtitle: "$39.99/year after 7 days", plan: .yearly)
        }
    }

    private func planCard(title: String, subtitle: String, plan: SubscriptionPlan) -> some View {
        Button {
            Task {
                await subscriptionManager.purchase(plan)
                analyticsService.track(plan == .monthly ? .monthlyConverted : .yearlyConverted)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(MemoryInkTypography.subtitle)
                        .foregroundStyle(MemoryInkColors.ink)

                    Text(subtitle)
                        .font(MemoryInkTypography.timestamp)
                        .foregroundStyle(MemoryInkColors.secondaryInk)
                }

                Spacer()

                Text("Start Trial")
                    .font(MemoryInkTypography.timestamp.weight(.medium))
                    .foregroundStyle(MemoryInkColors.ink)
            }
            .padding(18)
            .background(MemoryInkColors.paper.opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(MemoryInkColors.hairline.opacity(0.24), lineWidth: 0.8)
            }
        }
        .buttonStyle(.plain)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Included")
                .font(MemoryInkTypography.eyebrow)
                .foregroundStyle(MemoryInkColors.tertiaryInk)

            ForEach([
                "Metadata cloud sync",
                "Increased AI narrative limits",
                "Voice journaling",
                "Premium recap styles"
            ], id: \.self) { feature in
                Text(feature)
                    .font(MemoryInkTypography.narrativeCompact)
                    .foregroundStyle(MemoryInkColors.ink)
            }
        }
    }

    private var actionSection: some View {
        Button {
            Task {
                await subscriptionManager.restorePurchases()
            }
        } label: {
            Text("Restore Purchases")
                .font(MemoryInkTypography.timestamp.weight(.medium))
                .foregroundStyle(MemoryInkColors.secondaryInk)
        }
        .buttonStyle(.plain)
    }

    private var configurationNote: some View {
        Text(subscriptionManager.isRevenueCatConfigured ? "Purchases are ready to connect." : "Purchase configuration is not connected yet.")
            .font(MemoryInkTypography.timestamp)
            .foregroundStyle(MemoryInkColors.tertiaryInk)
    }
}
