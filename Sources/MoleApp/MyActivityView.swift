import SwiftUI

/// My Activity — shows a log of recent Mole actions (cleanups, scans, maintenance tasks).
/// Reads from ActionHistoryStore which persists actions to UserDefaults.
public struct MyActivityView: View {
    @ObservedObject var viewModel: MaintenanceViewModel
    @State private var history: [ActivityRecord] = []

    public var body: some View {
        HStack(spacing: 0) {
            // Main List
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Activity")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Recent Mole actions — cleanups, scans, and maintenance tasks.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 12)

                Divider()

                if history.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No activity yet.")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Run a Smart Care scan, cleanup, or maintenance task to see history here.")
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 1) {
                            ForEach(history) { record in
                                activityRow(record)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            history = ActivityHistoryStore.shared.recent(limit: 100)
        }
        // Refresh when a new action result comes in
        .onChange(of: viewModel.lastActionResult) { _, _ in
            history = ActivityHistoryStore.shared.recent(limit: 100)
        }
    }

    private func activityRow(_ record: ActivityRecord) -> some View {
        HStack(spacing: 14) {
            Image(systemName: record.icon)
                .font(.title3)
                .foregroundColor(record.color)
                .frame(width: 36, height: 36)
                .background(record.color.opacity(0.10))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(record.detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Text(relativeTime(record.date))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.01))
    }

    private func relativeTime(_ date: Date) -> String {
        let seconds = -date.timeIntervalSinceNow
        if seconds < 60 { return "Just now" }
        if seconds < 3600 { return "\(Int(seconds / 60))m ago" }
        if seconds < 86400 { return "\(Int(seconds / 3600))h ago" }
        return Formatters.shortDate(date)
    }
}

// MARK: - Activity Record Model

public struct ActivityRecord: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let detail: String
    public let iconName: String
    public let colorName: String
    public let date: Date

    public init(id: UUID = UUID(), title: String, detail: String, iconName: String, colorName: String, date: Date = Date()) {
        self.id = id
        self.title = title
        self.detail = detail
        self.iconName = iconName
        self.colorName = colorName
        self.date = date
    }

    public var icon: String { iconName }
    public var color: Color {
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "teal": return .teal
        default: return .secondary
        }
    }
}

// MARK: - Activity History Store

public final class ActivityHistoryStore {
    public static let shared = ActivityHistoryStore()
    private let key = "com.mole.activityHistory"
    private let maxItems = 200

    private init() {}

    public func recent(limit: Int) -> [ActivityRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let records = try? JSONDecoder().decode([ActivityRecord].self, from: data) else {
            return []
        }
        return Array(records.prefix(limit))
    }

    public func append(_ record: ActivityRecord) {
        var records = recent(limit: maxItems)
        records.insert(record, at: 0)
        if records.count > maxItems { records = Array(records.prefix(maxItems)) }
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    /// Convenience: record a Smart Care scan completion.
    public func recordSmartCareScan(healthScore: Int, cleanupBytes: Int64) {
        append(ActivityRecord(
            title: "Smart Care Scan",
            detail: "Health: \(healthScore)/100 · \(Formatters.bytes(cleanupBytes)) reclaimable",
            iconName: "sparkle.magnifyingglass",
            colorName: "blue"
        ))
    }

    /// Convenience: record a cleanup action.
    public func recordCleanup(removedCount: Int, freedBytes: Int64) {
        append(ActivityRecord(
            title: "Cleanup",
            detail: "\(removedCount) items moved to Trash · \(Formatters.bytes(freedBytes)) freed",
            iconName: "trash",
            colorName: "orange"
        ))
    }

    /// Convenience: record a maintenance task.
    public func recordMaintenance(taskName: String, success: Bool) {
        append(ActivityRecord(
            title: taskName,
            detail: success ? "Completed successfully" : "Completed with errors",
            iconName: success ? "checkmark.circle" : "exclamationmark.circle",
            colorName: success ? "green" : "red"
        ))
    }
}
