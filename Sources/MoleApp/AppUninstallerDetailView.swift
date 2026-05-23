import SwiftUI

public struct AppUninstallerDetailView: View {
    @ObservedObject var viewModel: MaintenanceViewModel
    @State private var searchText = ""
    
    public var filteredApps: [AppInventoryItem] {
        if searchText.isEmpty {
            return viewModel.appsList
        } else {
            return viewModel.appsList.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            // Left Column: Apps list
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("App Uninstaller")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Deep clean residual paths and leftovers completely")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search installed apps...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.04))
                .cornerRadius(8)
                .padding(.horizontal, 24)
                
                if viewModel.appsList.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Scanning applications list...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredApps) { app in
                                Button(action: {
                                    withAnimation {
                                        viewModel.selectAppForUninstall(app)
                                    }
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "app.gift")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                            .frame(width: 32, height: 32)
                                            .background(Color.blue.opacity(0.08))
                                            .cornerRadius(6)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(app.name)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            Text(app.bundleID)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(Formatters.bytes(app.sizeBytes))
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(10)
                                    .background(viewModel.selectedAppForUninstall?.id == app.id ? Color.primary.opacity(0.06) : Color.primary.opacity(0.02))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.primary.opacity(viewModel.selectedAppForUninstall?.id == app.id ? 0.15 : 0.04), lineWidth: 1)
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
            
            // Right Column: Details & leftovers
            if let app = viewModel.selectedAppForUninstall {
                VStack(alignment: .leading, spacing: 20) {
                    Text("App Profile")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(app.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(app.path)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    // Safety profile
                    HStack {
                        Image(systemName: app.uninstallSafety == .blocked ? "lock.fill" : "lock.open.fill")
                            .foregroundColor(app.uninstallSafety == .blocked ? .red : .green)
                        Text(app.uninstallSafety == .blocked ? "Protected System App" : "Safe to Uninstall")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(8)
                    .background(Color.primary.opacity(0.03))
                    .cornerRadius(6)
                    
                    Divider()
                    
                    // Residual scan state
                    if viewModel.isScanningResiduals {
                        VStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Analyzing residual folders...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Residual Files Found")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Spacer()
                                Text(Formatters.bytes(app.associatedResidualBytes))
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.orange)
                            }
                            
                            if app.associatedResidualPaths.isEmpty {
                                Text("No configuration leftovers found. Clean uninstallation complete.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .italic()
                            } else {
                                ScrollView(.vertical) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        ForEach(app.associatedResidualPaths, id: \.self) { path in
                                            HStack(spacing: 6) {
                                                Image(systemName: "folder")
                                                    .foregroundColor(.orange)
                                                Text(URL(fileURLWithPath: path).lastPathComponent)
                                                    .font(.system(.caption2, design: .rounded))
                                                    .lineLimit(1)
                                                Spacer()
                                                Button(action: {
                                                    viewModel.reveal(path: path)
                                                }) {
                                                    Image(systemName: "magnifyingglass")
                                                        .font(.caption)
                                                        .foregroundColor(.blue)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                            .padding(4)
                                            .background(Color.primary.opacity(0.02))
                                            .cornerRadius(4)
                                        }
                                    }
                                }
                                .frame(maxHeight: 180)
                            }
                        }
                        
                        Spacer()
                        
                        // Deep Uninstall Button
                        Button(action: {
                            viewModel.deepUninstallApp(app)
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Deep Uninstall App")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(app.uninstallSafety == .blocked ? Color.gray : Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .disabled(app.uninstallSafety == .blocked || viewModel.isCleaning)
                    }
                }
                .padding(24)
                .frame(width: 320)
                .background(.ultraThinMaterial)
                .transition(.move(edge: .trailing))
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "app.gift")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("Select an app to view deep leftovers details.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(width: 320)
                .background(.ultraThinMaterial)
            }
        }
        .background(Color.clear)
        .onAppear {
            viewModel.runApplicationsReview()
        }
    }
}
