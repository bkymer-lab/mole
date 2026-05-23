import SwiftUI

public struct DashboardView: View {
    @ObservedObject var viewModel: MaintenanceViewModel
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                
                // TOP ROW: Main Status Card + 2 Vertical Cards
                HStack(spacing: 16) {
                    
                    // Left Column: Big Status Card
                    MainStatusCard(viewModel: viewModel)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Right Column: Two Vertical Cards
                    HStack(spacing: 16) {
                        VerticalActionCard(
                            icon: "eraser",
                            description: "Clean up storage and watch your free gigabytes add up.",
                            buttonTitle: "Go to Smart Care",
                            action: {
                                withAnimation { viewModel.selectedSection = .cleanup }
                            }
                        )
                        
                        VerticalActionCard(
                            icon: "bolt.fill",
                            description: "Start using Mole to see your recent time saved.",
                            buttonTitle: "Go to Smart Care",
                            action: {
                                withAnimation { viewModel.selectedSection = .performance }
                            }
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 320)
                
                // BOTTOM ROW: 3 Horizontal Cards
                HStack(spacing: 16) {
                    
                    // Recommendations Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("5 Recommendations")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("View All") {
                                // Action
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 13, weight: .semibold))
                        }
                        .padding(.horizontal, 4)
                        
                        HorizontalInfoCard(
                            icon: "lock.shield.fill",
                            title: "Unlock Advanced Features",
                            description: "Activate Mole's full potential to take advantage of all features.",
                            action: {},
                            iconColor: .orange
                        )
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Protection Card
                    VStack(alignment: .leading, spacing: 8) {
                        // Invisible spacer for alignment with "5 Recommendations"
                        Text(" ")
                            .font(.system(size: 13))
                            .padding(.horizontal, 4)
                        
                        HorizontalInfoCard(
                            icon: "hand.raised.fill",
                            title: "Active Protection",
                            description: "Your Mac's protection is currently running in background.",
                            action: {
                                withAnimation { viewModel.selectedSection = .protection }
                            },
                            iconColor: .pink
                        )
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Cloud Cleanup Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text(" ")
                            .font(.system(size: 13))
                            .padding(.horizontal, 4)
                        
                        HorizontalInfoCard(
                            icon: "cloud.fill",
                            title: "Cloud Cleanup",
                            description: "To clean cloud storage you need to scan your accounts.",
                            action: {
                                withAnimation { viewModel.selectedSection = .cloud }
                            },
                            iconColor: .cyan
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Spacer()
            }
            .padding(24)
        }
        .background(
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.02), .clear, Color.purple.opacity(0.01)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .ignoresSafeArea()
        )
    }
}
