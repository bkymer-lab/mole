import SwiftUI

public struct SpaceLensBubbleView: View {
    @ObservedObject var viewModel: MaintenanceViewModel
    @State private var hoveredBubbleID: UUID? = nil
    @State private var appearScale: CGFloat = 0.5
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Space Lens")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Concentric Bubble Map of your Home Directory Storage")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        viewModel.runSpaceLensReview()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Re-scan Space")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            ZStack {
                if viewModel.loadingSection == .spaceLens {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        Text(viewModel.status)
                            .font(.callout)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.snapshot.spaceLens.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.linearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .opacity(0.8)
                        
                        Text("Scan Space Lens to visualize storage")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Button("Start Lens Scan") {
                            withAnimation {
                                viewModel.runSpaceLensReview()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    GeometryReader { geo in
                        let entries = viewModel.snapshot.spaceLens
                        let width = geo.size.width
                        let height = geo.size.height
                        let center = CGPoint(x: width / 2, y: height / 2)
                        
                        ZStack {
                            // Background Orb
                            Circle()
                                .fill(RadialGradient(
                                    colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.05), Color.clear],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: min(width, height) / 2
                                ))
                                .blur(radius: 20)
                            
                            Canvas { context, size in
                                // Draw connecting paths first
                                let count = entries.count
                                for index in 0..<count {
                                    let distance = index == 0 ? 0 : (min(width, height) * 0.26) * CGFloat(index) / CGFloat(count)
                                    let angle = Double(index) * (2.0 * .pi / Double(max(1, count - 1)))
                                    let xOffset = index == 0 ? 0 : cos(angle) * distance
                                    let yOffset = index == 0 ? 0 : sin(angle) * distance
                                    let nodeCenter = CGPoint(x: center.x + xOffset, y: center.y + yOffset)
                                    
                                    if index > 0 {
                                        var path = Path()
                                        path.move(to: center)
                                        path.addLine(to: nodeCenter)
                                        context.stroke(path, with: .color(Color.primary.opacity(0.1)), lineWidth: 1.5)
                                    }
                                }
                                
                                // Draw nodes (bubbles)
                                for index in 0..<count {
                                    let entry = entries[index]
                                    let distance = index == 0 ? 0 : (min(width, height) * 0.26) * CGFloat(index) / CGFloat(count)
                                    let angle = Double(index) * (2.0 * .pi / Double(max(1, count - 1)))
                                    let xOffset = index == 0 ? 0 : cos(angle) * distance
                                    let yOffset = index == 0 ? 0 : sin(angle) * distance
                                    let nodeCenter = CGPoint(x: center.x + xOffset, y: center.y + yOffset)
                                    
                                    // Draw resolved SwiftUI View
                                    if let symbol = context.resolveSymbol(id: entry.id) {
                                        context.draw(symbol, at: nodeCenter)
                                    }
                                }
                            } symbols: {
                                // Define the UI for each bubble to be injected into the Canvas
                                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                                    let ratio = Double(entry.sizeBytes) / Double(entries.first?.sizeBytes ?? 1)
                                    let radius = max(40, CGFloat(ratio) * (min(width, height) * 0.28))
                                    
                                    ZStack {
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
                                            .overlay(
                                                Circle()
                                                    .stroke(
                                                        LinearGradient(
                                                            colors: [
                                                                Color.white.opacity(0.35),
                                                                Color.white.opacity(0.1),
                                                                Color.clear,
                                                                Color.purple.opacity(0.15)
                                                            ],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        ),
                                                        lineWidth: hoveredBubbleID == entry.id ? 2 : 1
                                                    )
                                            )
                                        
                                        Circle()
                                            .fill(accentGradient(for: index))
                                            .opacity(hoveredBubbleID == entry.id ? 0.35 : 0.2)
                                            .padding(4)
                                        
                                        VStack(spacing: 4) {
                                            Image(systemName: folderIcon(for: entry.name))
                                                .font(.system(size: max(12, radius * 0.25)))
                                                .foregroundColor(.primary.opacity(0.9))
                                            
                                            Text(entry.name)
                                                .font(.system(size: max(10, radius * 0.16), weight: .bold, design: .rounded))
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.5)
                                                .padding(.horizontal, 8)
                                            
                                            Text(Formatters.bytes(entry.sizeBytes))
                                                .font(.system(size: max(8, radius * 0.13), design: .monospaced))
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    .frame(width: radius * 2, height: radius * 2)
                                    .onHover { isHovered in
                                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                            hoveredBubbleID = isHovered ? entry.id : nil
                                        }
                                    }
                                    .tag(entry.id)
                                }
                            }
                            .scaleEffect(appearScale)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .onAppear {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                            appearScale = 1.0
                        }
                    }
                }
            }
        }
        .background(Color.clear)
    }
    
    private func accentGradient(for index: Int) -> LinearGradient {
        let colors: [[Color]] = [
            [Color.blue, Color.purple],
            [Color.purple, Color.pink],
            [Color.pink, Color.orange],
            [Color.teal, Color.blue],
            [Color.green, Color.teal],
            [Color.orange, Color.yellow]
        ]
        let selected = colors[index % colors.count]
        return LinearGradient(colors: selected, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    private func folderIcon(for name: String) -> String {
        switch name.lowercased() {
        case "downloads": return "arrow.down.circle"
        case "documents": return "doc.folder"
        case "desktop": return "desktopcomputer"
        case "movies": return "film"
        case "pictures": return "photo.on.rectangle"
        case "music": return "music.note"
        case "library": return "folder.badge.gearshape"
        default: return "folder"
        }
    }
}
