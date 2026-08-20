import SwiftUI

struct MemoryViewerView: View {
    let startingId: UUID

    @EnvironmentObject private var repository: JournalEntryRepository
    @EnvironmentObject private var router: AppRouter

    @State private var currentId: UUID

    init(startingId: UUID) {
        self.startingId = startingId
        self._currentId = State(initialValue: startingId)
    }

    private var entries: [JournalEntry] { repository.entries }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentId) {
                ForEach(entries) { entry in
                    MemoryViewerPage(entry: entry)
                        .tag(entry.id)
                        .ignoresSafeArea()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            VStack {
                HStack {
                    Button {
                        router.path.removeLast()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    if let index = entries.firstIndex(where: { $0.id == currentId }) {
                        Text("\(index + 1) / \(entries.count)")
                            .font(MemoryInkTypography.timestamp.weight(.medium))
                            .foregroundStyle(.white.opacity(0.80))
                    }

                    Spacer()

                    Button {
                        router.path.append(.memoryDetail(id: currentId))
                    } label: {
                        HStack(spacing: 4) {
                            Text("Details")
                                .font(MemoryInkTypography.timestamp.weight(.semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)

                Spacer()

                if entries.count <= 20 {
                    HStack(spacing: 5) {
                        ForEach(entries) { entry in
                            Circle()
                                .fill(entry.id == currentId ? Color.white : Color.white.opacity(0.35))
                                .frame(width: entry.id == currentId ? 7 : 5, height: entry.id == currentId ? 7 : 5)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentId)
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct MemoryViewerPage: View {
    let entry: JournalEntry

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack(alignment: .bottom) {
                // Background: photo or mood gradient, explicitly sized to geo dimensions
                Group {
                    if let img = ImagePipelineService.image(forRelativePath: entry.thumbnailPath) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    } else {
                        LinearGradient(
                            colors: [entry.mood.tint, entry.mood.tint.opacity(0.38)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
                .frame(width: w, height: h)
                .clipped()

                // Scrim: explicitly sized, no ignoresSafeArea needed
                LinearGradient(
                    colors: [.clear, .clear, .black.opacity(0.70)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: w, height: h)

                // Text overlay: width comes from GeometryReader — guaranteed correct
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(entry.mood.tint)
                            .frame(width: 6, height: 6)

                        Text(entry.mood.title.uppercased())
                            .font(MemoryInkTypography.badge)
                            .kerning(0.6)
                            .foregroundStyle(MemoryInkColors.ink)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())

                    if let narrative = entry.aiNarrative, !narrative.isEmpty {
                        Text(narrative)
                            .font(MemoryInkTypography.narrative)
                            .foregroundStyle(.white.opacity(0.92))
                            .lineSpacing(6)
                            .lineLimit(4)
                            .multilineTextAlignment(.leading)
                    }

                    Text(entry.createdAt.formatted(date: .long, time: .omitted))
                        .font(MemoryInkTypography.timestamp)
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 80)
                .frame(width: w, alignment: .leading)   // w from GeometryReader = actual screen width
            }
            .frame(width: w, height: h)   // ZStack explicitly sized — no ambiguity
        }
        .ignoresSafeArea()
    }
}
