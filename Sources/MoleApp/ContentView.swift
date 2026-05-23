import SwiftUI

public struct ContentView: View {
    @ObservedObject var viewModel: MaintenanceViewModel
    @AppStorage("hasCompletedTrustOnboarding") private var hasCompletedTrustOnboarding = false
    @AppStorage("shouldRunInitialSmartCare") private var shouldRunInitialSmartCare = false

    public var body: some View {
        Group {
            if hasCompletedTrustOnboarding {
                NavigationSplitView {
                    sidebar
                } detail: {
                    detail
                }
                .onAppear {
                    if shouldRunInitialSmartCare {
                        shouldRunInitialSmartCare = false
                        viewModel.performSmartCareAction()
                    }
                }
            } else {
                TrustOnboardingView {
                    shouldRunInitialSmartCare = true
                    withAnimation(.smooth(duration: 0.35)) {
                        hasCompletedTrustOnboarding = true
                    }
                }
            }
        }
        .frame(minWidth: 1120, minHeight: 760)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
                }) {
                    Image(systemName: "sidebar.left")
                }
            }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 24) {
            // App Identity Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.accentColor.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.accentColor.opacity(0.24), lineWidth: 1)
                        )
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentColor, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .frame(width: 36, height: 36)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Mole")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("System Companion")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 16)

            // Navigation Sections
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(AppSection.allCases) { section in
                        SidebarItemView(
                            section: section,
                            isSelected: viewModel.selectedSection == section,
                            action: {
                                withAnimation(.smooth(duration: 0.2)) {
                                    viewModel.selectedSection = section
                                    viewModel.selectedInspectorItem = nil
                                }
                            }
                        )
                        
                        // Add spacing before "My Tools" and "My Activity" if needed, 
                        // or just keep it flat. In CMM it's mostly flat.
                        if section == .cloud || section == .myTools {
                            Spacer().frame(height: 16)
                        }
                    }
                }
                .padding(.horizontal, 12)
            }

            Spacer()

            // Dynamic Sidebar Health Card
            SidebarHealthStatusCard(viewModel: viewModel)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 12)
        .visualEffect(material: .sidebar, blendingMode: .behindWindow)
        .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
    }

    private var detail: some View {
        HStack(spacing: 0) {
            mainDetail
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if let selectedItem = viewModel.selectedInspectorItem {
                Divider()
                InspectorPanelView(item: selectedItem, onClose: {
                    withAnimation(.smooth(duration: 0.3)) {
                        viewModel.selectedInspectorItem = nil
                    }
                })
                    .background(VisualEffectView(material: .sidebar, blendingMode: .withinWindow))
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.smooth(duration: 0.35), value: viewModel.selectedInspectorItem)
    }

    @ViewBuilder
    private var mainDetail: some View {
        switch viewModel.selectedSection {
        case .dashboard:
            DashboardView(viewModel: viewModel)
        case .cleanup:
            CleanupView(viewModel: viewModel)
        case .protection:
            ProtectionView(viewModel: viewModel)
        case .performance:
            MaintenanceView(viewModel: viewModel)
        case .applications:
            UnifiedApplicationsView(viewModel: viewModel)
        case .clutter:
            ClutterView(viewModel: viewModel)
        case .spaceLens:
            SpaceLensBubbleView(viewModel: viewModel)
        case .cloud:
            CloudView(viewModel: viewModel)
        case .myTools:
            ExtensionsManagerView(viewModel: viewModel)
        case .myActivity:
            MyActivityView(viewModel: viewModel)
        case .privacy:
            PrivacyView(viewModel: viewModel)
        case .settings:
            UnifiedSettingsView(viewModel: viewModel)
        }
    }
}

// MARK: - Premium Right Sliding Inspector Detail Panel
public struct InspectorPanelView: View {
    public let item: CleanupTarget
    public let onClose: () -> Void
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Analiz Raporu")
                    .font(.system(size: 15, weight: .bold)) // SF Pro Display
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button(action: {
                    onClose()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            Divider()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Category & Size card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .center, spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.accentColor.opacity(0.1))
                                Image(systemName: "chart.pie.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.accentColor)
                            }
                            .frame(width: 32, height: 32)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.category.uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.secondary)
                                    .tracking(0.5)
                                
                                Text(Formatters.bytes(item.sizeBytes))
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                            }
                        }
                        
                        Divider().padding(.vertical, 4)
                        
                        // Path and Items summary
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Dosya Sayısı:")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(item.itemCount) öğe")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.primary)
                            }
                            
                            HStack {
                                Text("Güvenlik Seviyesi:")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(item.risk == .low ? "Tamamen Güvenli" : "İnceleme Önerilir")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(item.risk == .low ? Color.green : Color.orange)
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                            )
                    )
                    
                    // Expert analysis (Apple OS Analyst Tone)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "brain.head.profile.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.accentColor)
                            Text("Sistem Analisti Görüşü")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.primary)
                        }
                        
                        Text(analystCommentary(for: item))
                            .font(.system(size: 12))
                            .foregroundStyle(.primary.opacity(0.85))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.accentColor.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.accentColor.opacity(0.12), lineWidth: 1)
                            )
                    )
                    
                    // Recoverability / Quarantine warning
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.uturn.backward.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.green)
                            Text("Kurtarılabilirlik & Karantina")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.primary)
                        }
                        
                        Text("Bu öğeler silindikten sonra 15 gün boyunca yerel karantina alanında saklanır. Dilediğiniz an Cmd+Z kısayolu veya Karantina Ayarları üzerinden orijinal konumlarına sıfır veri kaybıyla geri yükleyebilirsiniz.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                            )
                    )
                    
                    // Path details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DOSYA YOLU DETAYI")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                            .tracking(0.5)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(SensitiveRedactor.userFacingPath(item.path, advanced: true))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .padding(8)
                                .background(Color.primary.opacity(0.03))
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(20)
            }
            
            Spacer()
            
            // Footer with Action
            VStack(spacing: 12) {
                Divider()
                
                Button(action: {
                    onClose()
                }) {
                    Text("Detayları Kapat")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.accentColor)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .padding(.top, 8)
            }
        }
        .frame(width: 320)
    }
    
    private func analystCommentary(for target: CleanupTarget) -> String {
        switch target.category {
        case "App caches", "Sistem Önbelleği":
            return "Uygulamalar ve işletim sistemi, sık erişilen verileri daha hızlı yüklemek için bu önbellek dosyalarını oluşturur. Bu dosyaların silinmesi sistem stabilitesini kesinlikle etkilemez; sistem ihtiyaç duyduğunda bunları arka planda otomatik olarak yeniden oluşturacaktır."
        case "System logs", "Developer artifacts":
            return "Sisteminizdeki arka plan servisleri ve çökme raporları bu günlük dosyalarında depolanır. Geliştirici değilseniz veya aktif bir sorunu hata ayıklama moduyla izlemiyorsanız, bu log dosyalarını temizlemek sisteminizde hiçbir olumsuz etki yaratmadan önemli ölçüde yer kazandıracaktır."
        case "E-Posta Ekleri":
            return "E-posta uygulamalarınızın (Mail.app gibi) ekleri çevrimdışı görüntüleme için yerel diskinize indirdiği kopyalardır. Orijinal dosyalarınız IMAP posta sunucunuzda güvenle saklanmaya devam eder. Silinmesi diskte ciddi yer açar."
        case "Old installers", "Downloads":
            return "İndirilenler klasörünüzde kalan bu yükleyici paketleri (DMG, PKG veya ZIP), uygulamaları yükledikten sonra artık herhangi bir işleve sahip değildir. Sistem kararlılığına hiçbir etkileri yoktur ve silinmeleri tamamen güvenlidir."
        case "Dil Paketleri", "Kullanılmayan Dil Paketleri":
            return "Kullanmakta olduğunuz ana diller (Türkçe, İngilizce) haricindeki tüm diğer dil lokalizasyon dosyaları bu kapsamdadır. Silinmeleri uygulamaların genel çalışmasını asla engellemez ve disk alanınızı verimli kullanmanıza imkan tanır."
        default:
            return "Mole sistem analiz motoru bu dosyaları güvenle temizlenebilir olarak işaretlemiştir. Silme işlemi sonrasında ilgili uygulamalar kararlı çalışmaya devam edecektir."
        }
    }
}

// Custom Sidebar Item
public struct SidebarItemView: View {
    public let section: AppSection
    public let isSelected: Bool
    public let action: () -> Void
    @State private var isHovered = false

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: section.symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .frame(width: 18)
                
                Text(section.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Color.primary : Color.primary.opacity(0.85))
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.primary.opacity(0.03), lineWidth: 1)
                        )
                } else if isHovered {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.primary.opacity(0.03))
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovered in
            isHovered = hovered
        }
    }
}

// Premium Sidebar Status Card
public struct SidebarHealthStatusCard: View {
    @ObservedObject var viewModel: MaintenanceViewModel
    @State private var pulse = false

    public var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.green)
                .frame(width: 6, height: 6)
                .opacity(pulse ? 0.45 : 1.0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        pulse = true
                    }
                }
            
            Text("Mac tamamen sağlıklı")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.green)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.green.opacity(0.08))
        )
        .overlay(
            Capsule()
                .stroke(Color.green.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

public struct UnifiedApplicationsView: View {
    @ObservedObject var viewModel: MaintenanceViewModel
    @State private var selectedTab = 0
    
    public var body: some View {
        VStack(spacing: 0) {
            // Segment picker header
            HStack {
                Picker("", selection: $selectedTab) {
                    Text("Uninstaller").tag(0)
                    Text("Updates").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            if selectedTab == 0 {
                AppUninstallerDetailView(viewModel: viewModel)
            } else {
                AppUpdaterView(viewModel: viewModel)
            }
        }
    }
}

public struct UnifiedSettingsView: View {
    @ObservedObject var viewModel: MaintenanceViewModel
    @State private var selectedTab = 0
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("", selection: $selectedTab) {
                    Text("Extensions").tag(0)
                    Text("Preferences").tag(1)
                    Text("Karantina").tag(2)
                    Text("Zamanlama").tag(3)
                }
                .pickerStyle(.segmented)
                .frame(width: 420)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            if selectedTab == 0 {
                ExtensionsManagerView(viewModel: viewModel)
            } else if selectedTab == 1 {
                SettingsView(viewModel: viewModel)
            } else if selectedTab == 2 {
                QuarantineSettingsView(viewModel: viewModel)
            } else {
                SchedulesSettingsView(viewModel: viewModel)
            }
        }
    }
}

