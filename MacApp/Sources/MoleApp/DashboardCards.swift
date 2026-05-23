import SwiftUI

// MARK: - Health Timeline
public struct HealthTimelineView: View {
    public let currentStatus: ProtectionStatus
    
    // Scale matching CMM: Excellent, Good, Fair, Requires Attention, Critical
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            timelineNode(title: "Excellent", isCurrent: false, color: .cyan)
            timelineNode(title: "Good", isCurrent: true, color: .green)
            timelineNode(title: "Fair", isCurrent: false, color: .yellow)
            timelineNode(title: "Requires Attention", isCurrent: false, color: .orange)
            timelineNode(title: "Critical", isCurrent: false, color: .red)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func timelineNode(title: String, isCurrent: Bool, color: Color) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isCurrent ? color : color.opacity(0.3))
                .frame(width: isCurrent ? 12 : 8, height: isCurrent ? 12 : 8)
                .overlay(
                    Circle()
                        .stroke(color, lineWidth: isCurrent ? 0 : 2)
                )
            
            Text(title)
                .font(.system(size: 13, weight: isCurrent ? .bold : .regular))
                .foregroundColor(isCurrent ? color : .secondary)
            
            Spacer()
        }
    }
}

// MARK: - Main Status Card
public struct MainStatusCard: View {
    @ObservedObject var viewModel: MaintenanceViewModel
    @State private var showLearnMore = false
    
    public var body: some View {
        ZStack {
            // Background glow matching CMM
            RadialGradient(gradient: Gradient(colors: [Color.green.opacity(0.3), .clear]), center: .center, startRadius: 0, endRadius: 250)
                .offset(x: -50, y: -50)
            
            VStack(alignment: .leading) {
                // Top header
                HStack(alignment: .center) {
                    Text("Good")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Button(action: { showLearnMore.toggle() }) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showLearnMore, arrowEdge: .top) {
                        HealthTimelineView(currentStatus: viewModel.snapshot.protection)
                    }
                    
                    Spacer()
                }
                
                Text(Utilities.deviceModelIdentifier())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Bottom Storage Progress
                VStack(spacing: 6) {
                    HStack {
                        Text("Macintosh HD")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Text("\((viewModel.snapshot.system.storageTotalBytes - viewModel.snapshot.system.storageUsedBytes) / 1_000_000_000) GB free of \(viewModel.snapshot.system.storageTotalBytes / 1_000_000_000) GB")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.primary.opacity(0.1))
                                .frame(height: 6)
                            
                            Capsule()
                                .fill(Color.primary)
                                .frame(width: viewModel.snapshot.system.storageTotalBytes > 0 ? geo.size.width * CGFloat(Double(viewModel.snapshot.system.storageUsedBytes) / Double(viewModel.snapshot.system.storageTotalBytes)) : 0, height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
            .padding(24)
            
            // Decorative Laptop Image (right side)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "laptopcomputer")
                        .font(.system(size: 100))
                        .foregroundColor(.primary.opacity(0.2))
                        .offset(x: 20, y: 20)
                }
            }
        }
        .frame(minHeight: 280)
        .background(VisualEffectView(material: .sidebar, blendingMode: .withinWindow))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
}

// MARK: - Vertical Action Card
public struct VerticalActionCard: View {
    public let icon: String
    public let description: String
    public let buttonTitle: String
    public let action: () -> Void
    
    @State private var isPulsing = false
    @State private var isHovered = false
    
    public var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button(action: {}) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(isPulsing ? 0.2 : 0.05))
                    .frame(width: isPulsing ? 120 : 100, height: isPulsing ? 120 : 100)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPulsing)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(colors: [.accentColor, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            .onAppear {
                isPulsing = true
            }
            
            Spacer()
            
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            
            Button(action: action) {
                Text(buttonTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isHovered ? Color.accentColor.opacity(0.8) : Color.accentColor)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VisualEffectView(material: .sidebar, blendingMode: .withinWindow))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isHovered ? Color.accentColor.opacity(0.3) : Color.primary.opacity(0.05), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovered in
            isHovered = hovered
        }
    }
}

// MARK: - Horizontal Info Card
public struct HorizontalInfoCard: View {
    public let icon: String
    public let title: String
    public let description: String
    public let action: () -> Void
    public var iconColor: Color = .orange
    
    @State private var isHovered = false
    
    public var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Button(action: {}) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(iconColor)
                    .frame(width: 48, height: 48)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(VisualEffectView(material: .sidebar, blendingMode: .withinWindow))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isHovered ? iconColor.opacity(0.3) : Color.primary.opacity(0.05), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovered in
            isHovered = hovered
        }
        .onTapGesture {
            action()
        }
    }
}
