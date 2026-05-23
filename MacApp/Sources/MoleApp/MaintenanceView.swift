import SwiftUI

public struct MaintenanceView: View {
    @ObservedObject var viewModel: MaintenanceViewModel
    @State private var selectedAction: MaintenanceAction? = nil
    
    public var body: some View {
        HStack(spacing: 0) {
            // Actions List
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Maintenance")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Run optimizing scripts to speed up your Mac")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(viewModel.maintenanceActions) { action in
                            Button(action: {
                                selectedAction = action
                            }) {
                                HStack(spacing: 12) {
                                    // Checkbox Button
                                    Button(action: {
                                        viewModel.toggleMaintenanceActionSelection(action)
                                    }) {
                                        Image(systemName: action.isSelected ? "checkmark.square.fill" : "square")
                                            .font(.title3)
                                            .foregroundColor(action.isSelected ? .blue : .secondary.opacity(0.8))
                                    }
                                    .buttonStyle(.plain)
                                    .frame(width: 24, height: 24)
                                    
                                    // Icon block
                                    Image(systemName: action.icon)
                                        .font(.title2)
                                        .foregroundColor(action.status == .running ? .orange : .blue)
                                        .frame(width: 40, height: 40)
                                        .background(Color.blue.opacity(0.08))
                                        .cornerRadius(8)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(action.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(action.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                    
                                    Spacer()
                                    
                                    // Status Badge
                                    Text(action.status.rawValue)
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(statusColor(for: action.status).opacity(0.12))
                                        .foregroundColor(statusColor(for: action.status))
                                        .cornerRadius(6)
                                }
                                .padding(12)
                                .background(selectedAction?.id == action.id ? Color.primary.opacity(0.06) : Color.primary.opacity(0.02))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.primary.opacity(selectedAction?.id == action.id ? 0.15 : 0.04), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
                
                // Bottom Batch Run Bar (CleanMyMac-style!)
                let selectedCount = viewModel.maintenanceActions.filter { $0.isSelected }.count
                HStack {
                    if selectedCount > 0 {
                        Text("\(selectedCount) script(s) selected")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Select scripts to optimize your Mac")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.runSelectedMaintenanceActions()
                    }) {
                        HStack {
                            Image(systemName: viewModel.isRunningMaintenance ? "arrow.triangle.2.circlepath" : "play.fill")
                                .imageScale(.medium)
                            Text(viewModel.isRunningMaintenance ? "Running..." : "Run Selected Scripts")
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(selectedCount > 0 && !viewModel.isRunningMaintenance ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(selectedCount > 0 && !viewModel.isRunningMaintenance ? .white : .secondary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedCount == 0 || viewModel.isRunningMaintenance)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color.primary.opacity(0.02))
                .overlay(
                    Divider(), alignment: .top
                )
            }
            .frame(maxWidth: .infinity)
            
            // Task Detail & Logs panel
            if let action = selectedAction {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Task Diagnostics")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(action.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Task Category: \(action.kind.rawValue)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    // Task state
                    if action.status == .running {
                        VStack(spacing: 8) {
                            ProgressView(value: action.progress, total: 1.0)
                                .progressViewStyle(.linear)
                            Text("Running background tasks...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.primary.opacity(0.03))
                        .cornerRadius(8)
                    } else {
                        Button(action: {
                            viewModel.runMaintenanceAction(action)
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Execute Script Now")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isRunningMaintenance)
                        .opacity(viewModel.isRunningMaintenance ? 0.6 : 1.0)
                    }
                    
                    // Live Terminal Logs
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Terminal Log Output")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.vertical) {
                            Text(action.logOutput.isEmpty ? "Waiting for execution..." : action.logOutput)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.85))
                        .cornerRadius(8)
                    }
                }
                .padding(24)
                .frame(width: 320)
                .background(.ultraThinMaterial)
                .transition(.move(edge: .trailing))
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("Select a maintenance script to view details.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(width: 320)
                .background(.ultraThinMaterial)
            }
        }
        .background(Color.clear)
        .onAppear {
            viewModel.loadMaintenanceActions()
            if selectedAction == nil {
                selectedAction = viewModel.maintenanceActions.first
            }
        }
        // Keep selectedAction details updated in real-time as state changes
        .onChange(of: viewModel.maintenanceActions) { _, newActions in
            if let selected = selectedAction,
               let updated = newActions.first(where: { $0.id == selected.id }) {
                selectedAction = updated
            }
        }
    }
    
    private func statusColor(for status: MaintenanceAction.ActionStatus) -> Color {
        switch status {
        case .idle: return .blue
        case .running: return .orange
        case .completed: return .green
        case .failed: return .red
        }
    }
}
