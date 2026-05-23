import SwiftUI

public struct ExtensionsManagerView: View {
    @ObservedObject var viewModel: MaintenanceViewModel
    @State private var selectedExtension: SystemExtension? = nil
    @State private var selectedTab: SystemExtension.ExtensionType = .launchAgent
    
    public var filteredExtensions: [SystemExtension] {
        viewModel.systemExtensions.filter { $0.type == selectedTab }
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            // Main list of extensions
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Extensions & Login Items")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Manage LaunchAgents, Preference Panes, and Login elements safely")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Segments Tab Picker
                HStack(spacing: 12) {
                    segmentButton(title: "LaunchAgents", type: .launchAgent)
                    segmentButton(title: "Pref Panes", type: .preferencePane)
                }
                .padding(.horizontal, 24)
                
                if viewModel.isScanningExtensions {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Reading LaunchAgents databases...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(filteredExtensions) { item in
                                Button(action: {
                                    selectedExtension = item
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: item.type == .preferencePane ? "slider.horizontal.3" : "app.badge.fill")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                            .frame(width: 36, height: 36)
                                            .background(Color.blue.opacity(0.08))
                                            .cornerRadius(8)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            Text(item.bundleID)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                        
                                        // Dynamic toggle
                                        Toggle("", isOn: Binding(
                                            get: { item.isEnabled },
                                            set: { _ in
                                                viewModel.toggleExtension(item)
                                            }
                                        ))
                                        .toggleStyle(.switch)
                                        .labelsHidden()
                                    }
                                    .padding(12)
                                    .background(selectedExtension?.id == item.id ? Color.primary.opacity(0.06) : Color.primary.opacity(0.02))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.primary.opacity(selectedExtension?.id == item.id ? 0.15 : 0.04), lineWidth: 1)
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
            
            // Side detail card
            if let item = selectedExtension {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Extension Profile")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(item.bundleID)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Functional Description")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Text(item.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                            .padding(10)
                            .background(Color.primary.opacity(0.03))
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Location Path")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Text(item.path)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.primary)
                            .lineLimit(4)
                    }
                    
                    Spacer()
                    
                    // Reveal path Button
                    Button(action: {
                        viewModel.reveal(path: item.path)
                    }) {
                        HStack {
                            Image(systemName: "folder.fill")
                            Text("Reveal in Finder")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.primary.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(24)
                .frame(width: 320)
                .background(.ultraThinMaterial)
                .transition(.move(edge: .trailing))
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "app.badge")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("Select a background extension to view settings.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(width: 320)
                .background(.ultraThinMaterial)
            }
        }
        .background(Color.clear)
        .onAppear {
            viewModel.loadExtensions()
            if selectedExtension == nil {
                selectedExtension = filteredExtensions.first
            }
        }
        .onChange(of: viewModel.systemExtensions) { _, newExts in
            if let selected = selectedExtension,
               let updated = newExts.first(where: { $0.id == selected.id }) {
                selectedExtension = updated
            }
        }
    }
    
    private func segmentButton(title: String, type: SystemExtension.ExtensionType) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = type
                selectedExtension = viewModel.systemExtensions.first { $0.type == type }
            }
        }) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedTab == type ? Color.blue : Color.primary.opacity(0.04))
                .foregroundColor(selectedTab == type ? .white : .primary)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}
