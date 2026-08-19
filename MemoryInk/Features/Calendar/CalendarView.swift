import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var repository: JournalEntryRepository
    @StateObject private var viewModel = CalendarViewModel()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let dayLabels = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                monthHeader
                    .memoryInkEntrance()
                dayLabelRow
                VStack(alignment: .leading, spacing: 12) {
                    monthGrid
                    heatmapLegend
                }
                .memoryInkEntrance(delay: 0.06)
                memoryList
                    .memoryInkEntrance(delay: 0.12)
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 34)
        }
        .background(MemoryInkAmbientBackdrop(mood: nil, intensity: 0.85).ignoresSafeArea())
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var monthHeader: some View {
        HStack(spacing: 14) {
            Button {
                MemoryInkHaptics.selection()
                withAnimation(.easeInOut(duration: 0.22)) {
                    viewModel.navigateMonth(by: -1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MemoryInkColors.secondaryInk)
                    .frame(width: 34, height: 34)
                    .background(MemoryInkColors.paper.opacity(0.72))
                    .clipShape(Circle())
            }
            .buttonStyle(MemoryInkPressStyle())

            Button {
                MemoryInkHaptics.light()
                withAnimation(.easeInOut(duration: 0.22)) {
                    viewModel.selectedDate = nil
                }
            } label: {
                Text(viewModel.displayMonth.formatted(.dateTime.month(.wide).year()))
                    .font(MemoryInkTypography.title)
                    .foregroundStyle(MemoryInkColors.ink)
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .buttonStyle(MemoryInkPressStyle())

            Button {
                MemoryInkHaptics.selection()
                withAnimation(.easeInOut(duration: 0.22)) {
                    viewModel.navigateMonth(by: 1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MemoryInkColors.secondaryInk)
                    .frame(width: 34, height: 34)
                    .background(MemoryInkColors.paper.opacity(0.72))
                    .clipShape(Circle())
            }
            .buttonStyle(MemoryInkPressStyle())
        }
    }

    private var dayLabelRow: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(dayLabels, id: \.self) { label in
                Text(label)
                    .font(MemoryInkTypography.timestamp)
                    .foregroundStyle(MemoryInkColors.tertiaryInk)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var monthGrid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Array(viewModel.daysInMonth().enumerated()), id: \.offset) { _, date in
                dayCell(for: date)
            }
        }
        .padding(14)
        .background(MemoryInkColors.paper.opacity(0.66))
        .clipShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous)
                .stroke(MemoryInkColors.hairline.opacity(0.24), lineWidth: 0.8)
        }
    }

    @ViewBuilder
    private func dayCell(for date: Date?) -> some View {
        if let date {
            let mood = viewModel.primaryMood(for: date, in: repository.entries)
            let intensity = viewModel.intensity(for: date, in: repository.entries)

            Button {
                MemoryInkHaptics.selection()
                withAnimation(.easeInOut(duration: 0.22)) {
                    viewModel.selectedDate = date
                }
            } label: {
                Text(dayNumber(for: date))
                    .font(MemoryInkTypography.narrativeCompact)
                    .foregroundStyle(intensity > 0 ? MemoryInkColors.ink : MemoryInkColors.tertiaryInk)
                    .frame(maxWidth: .infinity, minHeight: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill((mood?.tint ?? MemoryInkColors.taupe).opacity(intensity))
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                isSelected(date) ? MemoryInkColors.ink.opacity(0.55) : Color.clear,
                                lineWidth: 1.4
                            )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(MemoryInkPressStyle())
        } else {
            Color.clear
                .frame(minHeight: 42)
        }
    }

    /// Explains the colour ramp so the density reads as deliberate rather than decorative.
    private var heatmapLegend: some View {
        HStack(spacing: 8) {
            Text("Quieter")
                .font(MemoryInkTypography.timestamp)
                .foregroundStyle(MemoryInkColors.tertiaryInk)

            HStack(spacing: 4) {
                ForEach([0.12, 0.20, 0.34, 0.48, 0.62], id: \.self) { level in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(MemoryInkColors.taupe.opacity(level))
                        .frame(width: 16, height: 10)
                }
            }

            Text("Fuller")
                .font(MemoryInkTypography.timestamp)
                .foregroundStyle(MemoryInkColors.tertiaryInk)

            Spacer()
        }
    }

    private var memoryList: some View {
        let entries = viewModel.entriesForVisibleRange(in: repository.entries)

        return LazyVStack(alignment: .leading, spacing: 12) {
            Text(listTitle)
                .font(MemoryInkTypography.eyebrow)
                .foregroundStyle(MemoryInkColors.tertiaryInk)
                .textCase(.uppercase)

            if entries.isEmpty {
                EmptyStateView(message: "No memories here yet.")
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            } else {
                ForEach(entries) { entry in
                    Button {
                        MemoryInkHaptics.light()
                        router.path.append(.memoryDetail(id: entry.id))
                    } label: {
                        compactMemoryCard(for: entry)
                    }
                    .buttonStyle(MemoryInkPressStyle())
                }
            }
        }
    }

    private func compactMemoryCard(for entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(entry.mood.title)
                    .font(MemoryInkTypography.badge)
                    .foregroundStyle(MemoryInkColors.secondaryInk)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())

                Spacer()

                Text(entry.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(MemoryInkTypography.timestamp)
                    .foregroundStyle(MemoryInkColors.tertiaryInk)
            }

            Text(entry.aiNarrative?.isEmpty == false ? entry.aiNarrative ?? "" : entry.rawNote ?? "A memory from this day.")
                .font(MemoryInkTypography.narrativeCompact)
                .foregroundStyle(MemoryInkColors.ink)
                .lineSpacing(5)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    MemoryInkColors.paper.opacity(0.92),
                    MemoryInkColors.paperWarm.opacity(0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous)
                .stroke(MemoryInkColors.hairline.opacity(0.26), lineWidth: 0.8)
        }
    }

    private var listTitle: String {
        if let selectedDate = viewModel.selectedDate {
            return selectedDate.formatted(.dateTime.month(.abbreviated).day())
        }

        return "This month"
    }

    private func isSelected(_ date: Date) -> Bool {
        guard let selectedDate = viewModel.selectedDate else { return false }
        return Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }

    private func dayNumber(for date: Date) -> String {
        String(Calendar.current.component(.day, from: date))
    }
}
