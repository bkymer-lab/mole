import SwiftUI

public struct AppUpdaterView: View {
    @ObservedObject var viewModel: MaintenanceViewModel
    @State private var selectedUpdate: AppUpdate? = nil
    
    public var body: some View {
        HStack(spacing: 0) {
            // Update items checklist
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("App Updater")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Keep your apps secure and up to date automatically")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                if viewModel.appUpdates.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Checking updates from channels...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(viewModel.appUpdates) { update in
                                Button(action: {
                                    selectedUpdate = update
                                }) {
                                    HStack(spacing: 12) {
                                        // Custom checkbox
                                        Button(action: {
                                            viewModel.toggleUpdateSelection(for: update)
                                        }) {
                                            Image(systemName: update.isSelected ? "checkmark.circle.fill" : "circle")
                                                .font(.title3)
                                                .foregroundColor(update.isSelected ? .blue : .secondary)
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(update.status == .completed)
                                        
                                        // App Details
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(update.appName)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            HStack(spacing: 6) {
                                                Text(update.installedVersion)
                                                    .foregroundColor(.secondary)
                                                Image(systemName: "arrow.right")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                Text(update.latestVersion)
                                                    .foregroundColor(.blue)
                                            }
                                            .font(.caption2)
                                        }
                                        
                                        Spacer()
                                        
                                        // Action Status Badge
                                        Text(update.status.rawValue)
                                            .font(.system(size: 10, weight: .semibold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(statusColor(for: update.status).opacity(0.12))
                                            .foregroundColor(statusColor(for: update.status))
                                            .cornerRadius(6)
                                    }
                                    .padding(12)
                                    .background(selectedUpdate?.id == update.id ? Color.primary.opacity(0.06) : Color.primary.opacity(0.02))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.primary.opacity(selectedUpdate?.id == update.id ? 0.15 : 0.04), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            // Side panel with release notes
            if let update = selectedUpdate {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Release Profile")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(update.appName)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Update size: \(Formatters.bytes(update.sizeBytes))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Release Notes")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        
                        ScrollView(.vertical) {
                            Text(update.releaseNotes)
                                .font(.caption)
                                .foregroundColor(.primary.opacity(0.85))
                                .lineSpacing(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .background(Color.primary.opacity(0.03))
                                .cornerRadius(8)
                        }
                    }
                    
                    Spacer()
                    
                    // Update Action Button
                    let selectedCount = viewModel.appUpdates.filter { $0.isSelected && $0.status == .pending }.count
                    Button(action: {
                        viewModel.updateSelectedApps()
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.asymmetric.and.arrow.up.asymmetric")
                            Text(viewModel.isUpdatingApp ? "Installing Updates..." : "Update Selected (\(selectedCount))")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedCount == 0 || viewModel.isUpdatingApp ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedCount == 0 || viewModel.isUpdatingApp)
                }
                .padding(24)
                .frame(width: 320)
                .background(.ultraThinMaterial)
                .transition(.move(edge: .trailing))
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.down.asymmetric.and.arrow.up.asymmetric")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("Select an app update to read release notes.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(width: 320)
                .background(.ultraThinMaterial)
            }
        }
        .background(Color.clear)
        .onAppear {
            viewModel.loadAppUpdates()
            if selectedUpdate == nil {
                selectedUpdate = viewModel.appUpdates.first
            }
        }
        .onChange(of: viewModel.appUpdates) { _, newUpdates in
            if let selected = selectedUpdate,
               let updated = newUpdates.first(where: { $0.id == selected.id }) {
                selectedUpdate = updated
            }
        }
    }
    
    private func statusColor(for status: AppUpdate.UpdateStatus) -> Color {
        switch status {
        case .pending: return .blue
        case .downloading: return .orange
        case .installing: return .purple
        case .completed: return .green
        case .failed: return .red
        }
    }
}
