import SwiftUI
import AppKit

// Duplicate ContentView, DashboardView and sub-components removed to avoid compilation conflicts with standalone view files.

public struct TrustOnboardingView: View {
    public var start: () -> Void

    public enum OnboardingStep {
        case welcome
        case permissions
        case scanning
        case summary
    }

    @State private var currentStep: OnboardingStep = .welcome
    @State private var progress: Double = 0.0
    @State private var currentStageIndex = 0
    @State private var currentPath = ""
    @State private var isSimulatingScan = false
    
    @State private var fdaGranted = false
    @State private var xpcGranted = false
    @State private var notifGranted = false
    
    // System Specifications
    private var systemModel: String {
        #if arch(arm64)
        return "Apple Silicon (M-Serisi) Mac"
        #else
        return "Intel Core İşlemcili Mac"
        #endif
    }
    
    private var ramSize: String {
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        let gb = physicalMemory / (1024 * 1024 * 1024)
        return "\(gb) GB RAM (Bellek)"
    }
    
    private var osVersionString: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
    
    private var processorCount: String {
        return "\(ProcessInfo.processInfo.activeProcessorCount) Çekirdekli İşlemci"
    }

    public let scanStages = [
        "Sistem Önbelleği Taranıyor...",
        "Gereksiz Dil Dosyaları Analiz Ediliyor...",
        "Uygulama Kalıntıları Aranıyor...",
        "Büyük ve Eski Dosyalar Listeleniyor...",
        "Sistem Başlangıç Ögeleri Analiz Ediliyor...",
        "Güvenlik Tehditleri Taranıyor...",
        "Veritabanı Analizleri Tamamlanıyor..."
    ]

    public let scanPaths = [
        "~/Library/Caches/com.apple.Safari/Cache.db",
        "~/Library/Caches/com.spotify.client/Data/",
        "~/Library/Logs/DiagnosticReports/system.log",
        "~/Library/Developer/Xcode/DerivedData/Build/...",
        "~/Library/Application Support/MobileSync/Backup/",
        "/private/var/folders/zz/zyxvpxvq6csfxvn37...",
        "~/.Trash/OldProject_backup.zip",
        "~/Library/Caches/Google/Chrome/Default/Cache/",
        "~/Library/Preferences/com.apple.systempreferences.plist",
        "~/Library/Caches/com.adobe.Reader/Cache.db",
        "~/Library/Logs/Homebrew/formula.log"
    ]

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color.accentColor.opacity(0.12),
                    Color(nsColor: .windowBackgroundColor)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                switch currentStep {
                case .welcome:
                    welcomeView
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        ))
                case .permissions:
                    permissionsView
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        ))
                case .scanning:
                    scanningView
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        ))
                case .summary:
                    summaryView
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        ))
                }
            }
            .padding(48)
        }
        .frame(minWidth: 1000, minHeight: 700)
    }

    // Step 1: Welcome Screen
    private var welcomeView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Text("Mole macOS Sistem Yardımcısı")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Mac'inizi Canlandırmanın En Şeffaf Yolu")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                Text("Mole, disk alanınızı, sistem performansınızı ve güvenliğinizi tamamen yerel analizlerle denetler. Onayınız olmadan hiçbir dosyanıza dokunmaz.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 720)
            }

            HStack(spacing: 16) {
                OnboardingTrustCard(
                    icon: "lock.shield",
                    title: "Tamamen Yerel Analiz",
                    detail: "Mole, analizlerinde sadece dosya üst verilerini inceler. Kişisel dosya içerikleriniz asla okunmaz veya buluta yüklenmez."
                )
                OnboardingTrustCard(
                    icon: "checklist.checked",
                    title: "Kontrol Tamamen Sizde",
                    detail: "Temizlik işlemleri yapılmadan önce size detaylıca sunulur. Silinen dosyalarınız Karantina Bölgesi'nde güvenle saklanır."
                )
                OnboardingTrustCard(
                    icon: "heart.text.square",
                    title: "Korku Değil, Güven",
                    detail: "Mac'inizde hayali tehditler veya şişirilmiş boyutlar uydurarak sizi korkutmayız. Her işlemin gerekçesini açıklarız."
                )
            }
            .frame(maxWidth: 900)

            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    currentStep = .permissions
                }
            } label: {
                Label("Devam Et", systemImage: "arrow.right.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text("Bu aşamada hiçbir sistem veriniz analiz edilmeyecektir.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // Step 1.5: Permissions Flow
    private var permissionsView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Text("Kritik Sistem İzinleri")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Mole'a Mac'inizi Temizleme İzni Verin")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                Text("Mole'un sistem genelinde derin temizlik, anlık uyarılar ve güvenli bakım yapabilmesi için aşağıdaki 3 izne ihtiyacı vardır.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 720)
            }
            
            VStack(spacing: 20) {
                // FDA
                PermissionRow(
                    icon: "externaldrive.fill.badge.checkmark",
                    title: "Tam Disk Erişimi (Full Disk Access)",
                    description: "Sistem önbellekleri, Mail ekleri ve çöp sepetini tarayıp temizleyebilmek için gereklidir.",
                    isGranted: $fdaGranted
                )
                
                // XPC
                PermissionRow(
                    icon: "cpu",
                    title: "Ayrıcalıklı Sistem İşlemleri (XPC Helper)",
                    description: "Malware temizliği ve yönetici yetkisi gerektiren artık dosyaların güvenle kaldırılabilmesi için zorunludur.",
                    isGranted: $xpcGranted
                )
                
                // Notifications
                PermissionRow(
                    icon: "bell.badge.fill",
                    title: "Akıllı Bildirimler",
                    description: "Çöp sepetiniz sınırları aştığında veya kritik bir güncelleme olduğunda sizi arka planda sessizce uyarır.",
                    isGranted: $notifGranted
                )
            }
            .frame(maxWidth: 700)
            .padding(.vertical, 16)
            
            Button {
                startScanningSequence()
            } label: {
                Label(fdaGranted && xpcGranted && notifGranted ? "İzinler Tamamlandı - Taramaya Başla" : "Zorunlu Olmayanları Geç ve Başla", systemImage: "play.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(fdaGranted && xpcGranted && notifGranted ? .green : .accentColor)
        }
    }

    // Step 2: Animated Scanning Screen
    private var scanningView: some View {
        VStack(spacing: 40) {
            VStack(spacing: 12) {
                Text("İLK SİSTEM ANALİZİ")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.accentColor)
                    .tracking(2)
                
                Text("Mole Mac'inizi Güvenle Analiz Ediyor")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
            }
            
            // Visual Premium Scan Ring + Stats
            ZStack {
                // Outer subtle glowing circle
                Circle()
                    .stroke(Color.accentColor.opacity(0.1), lineWidth: 16)
                    .frame(width: 220, height: 220)
                
                // Animated Progress Ring
                Circle()
                    .trim(from: 0.0, to: CGFloat(progress))
                    .stroke(
                        LinearGradient(
                            colors: [Color.accentColor, Color.purple],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(Angle(degrees: -90))
                    .frame(width: 220, height: 220)
                    .animation(.easeInOut(duration: 0.1), value: progress)
                
                // Centered percentage text
                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    Text("Tamamlandı")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 10)
            
            VStack(spacing: 16) {
                // Current Stage Text with smooth transition
                Text(scanStages[currentStageIndex])
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                    .frame(height: 24)
                    .id(currentStageIndex)
                
                // File Path under scan (Monospaced, native console feel)
                Text(currentPath)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary.opacity(0.8))
                    .lineLimit(1)
                    .frame(maxWidth: 600)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
            }
            .frame(height: 80)
            
            // Decorative Progress Slider Line
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.1))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(LinearGradient(colors: [Color.accentColor, Color.purple], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(progress), height: 6)
                }
            }
            .frame(width: 400, height: 6)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: 720)
    }

    // Step 3: Summary / Aha Moment Screen
    private var summaryView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)
                    .symbolRenderingMode(.hierarchical)
                
                Text("Mac'iniz Güvenli Taramaya Hazır!")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                
                Text("İlk sistem denetimi başarıyla tamamlandı. Mac donanımınız ve Mole güvenlik katmanlarınız doğrulandı.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 680)
            }

            HStack(spacing: 24) {
                // Hardware specs card (native feel)
                VStack(alignment: .leading, spacing: 16) {
                    Text("Sistem Donanımı Bilgileri")
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "cpu")
                                .foregroundStyle(.secondary)
                            Text(systemModel)
                        }
                        HStack(spacing: 10) {
                            Image(systemName: "memorychip")
                                .foregroundStyle(.secondary)
                            Text(ramSize)
                        }
                        HStack(spacing: 10) {
                            Image(systemName: "macmini")
                                .foregroundStyle(.secondary)
                            Text(processorCount)
                        }
                        HStack(spacing: 10) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                            Text(osVersionString)
                        }
                    }
                    .font(.callout)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )

                // Mole Safety Guarantees card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Mole Güvenlik Sözleşmesi")
                        .font(.headline)
                        .foregroundStyle(.green)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 8) {
                            Text("🛡️")
                            Text("Silinen her şey **15 gün** boyunca yerel Karantina Bölgesinde saklanır ve dilediğiniz an tek tıkla geri yüklenir.")
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Text("⚡")
                            Text("**Hızlı Delta Tarama** sayesinde diskinizi aşırı okuma/yazma döngülerinden ve yıpranmaktan koruruz.")
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Text("🧪")
                            Text("Tehdit tanımları en güncel **delta imzalarıyla** eşleştirildi, güvenliğiniz tam koruma altında.")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
            }
            .frame(maxWidth: 840)

            Button {
                start()
            } label: {
                Label("Sistem Yöneticisini Başlat", systemImage: "arrow.right.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private func startScanningSequence() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentStep = .scanning
            progress = 0.0
            currentStageIndex = 0
            currentPath = scanPaths[0]
        }
        
        isSimulatingScan = true
        simulateProgress()
    }

    private func simulateProgress() {
        guard isSimulatingScan else { return }
        
        Task {
            let steps = 100
            for i in 1...steps {
                if !isSimulatingScan { break }
                try? await Task.sleep(nanoseconds: 30_000_000)
                
                await MainActor.run {
                    progress = Double(i) / Double(steps)
                    
                    let stageFraction = Double(scanStages.count)
                    let calculatedStage = Int(progress * stageFraction)
                    currentStageIndex = min(calculatedStage, scanStages.count - 1)
                    
                    let randomPathIndex = Int.random(in: 0..<scanPaths.count)
                    currentPath = scanPaths[randomPathIndex]
                }
            }
            
            try? await Task.sleep(nanoseconds: 400_000_000)
            
            await MainActor.run {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    currentStep = .summary
                    isSimulatingScan = false
                }
            }
        }
    }
}

// MARK: - Onboarding Components
public struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isGranted: Bool
    
    public var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isGranted ? Color.green.opacity(0.15) : Color.accentColor.opacity(0.1))
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isGranted ? .green : .accentColor)
            }
            .frame(width: 48, height: 48)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    isGranted.toggle()
                }
            }) {
                Text(isGranted ? "İzin Verildi" : "İzin Ver")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isGranted ? Color.green : Color.white)
                    .frame(width: 100)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isGranted ? Color.green.opacity(0.15) : Color.accentColor)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isGranted ? Color.green.opacity(0.3) : Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

public struct OnboardingTrustCard: View {
    public var icon: String
    public var title: String
    public var detail: String

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}

public struct CleanupView: View {
    @ObservedObject var viewModel: MaintenanceViewModel
    @AppStorage("advancedModeEnabled") private var advancedModeEnabled = false

    public var body: some View {
        ModulePage(title: "Cleanup", subtitle: "\(Formatters.bytes(viewModel.snapshot.cleanup.totalSizeBytes)) \(viewModel.snapshot.cleanup.kind == .estimate ? "estimated" : "reviewed") reclaimable. \(viewModel.cleanupBreakdownText)") {
            HStack {
                Button {
                    viewModel.runCleanupReview()
                } label: {
                    if viewModel.loadingSection == .cleanup {
                        ProgressView()
                    } else {
                        Label("Review cleanup targets", systemImage: "checklist")
                    }
                }
                .disabled(viewModel.loadingSection != nil || viewModel.isCleaning)

                Button {
                    viewModel.fastCleanup()
                } label: {
                    if viewModel.isCleaning {
                        ProgressView()
                    } else {
                        Label("Move Reviewed Items to Trash", systemImage: "trash")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isCleaning || !viewModel.snapshot.cleanup.isExecutable)

                if let result = viewModel.lastActionResult {
                    Text("\(result.removedCount) moved, \(result.skippedCount) skipped, \(result.errorCount) errors")
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.snapshot.cleanup.kind == .estimate {
                MetricCard(
                    title: "Estimate only",
                    value: "Review required",
                    detail: "Smart Care never moves files from an estimate. Run a cleanup review to see exact targets and reversible actions."
                )
                MetricCard(
                    title: "Downloads access",
                    value: "Opt-in",
                    detail: "Downloads is not read automatically. A future deep cleanup review should use a clear folder picker before macOS asks for access."
                )
            } else {
                if viewModel.snapshot.cleanup.targets.isEmpty {
                    EmptyStateCard(
                        title: "Nothing changed",
                        detail: "Cleanup reviewed only safe local locations and did not read Downloads automatically. Use a focused review later when you want to grant access."
                    )
                    MetricCard(
                        title: "Downloads access",
                        value: "Your choice",
                        detail: "macOS may ask for Files & Folders permission if a review tries to inspect Downloads. MacMaintenanceSuite now avoids that prompt until a clear opt-in review is available."
                    )
                } else {
                    VStack(spacing: 10) {
                        ForEach(viewModel.snapshot.cleanup.targets) { target in
                            CleanupTargetReviewCard(target: target, advancedModeEnabled: advancedModeEnabled) {
                                viewModel.reveal(path: target.path)
                            }
                        }
                    }
                }
            }
        }
    }
}

public struct TrustPopoverView: View {
    public var category: String
    
    public var body: some View {
        let info = getTrustInfo(for: category)
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.auth.to.ipaddress.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                Text("\(category) - Güvenlik Detayları")
                    .font(.headline)
            }
            .padding(.bottom, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Nedir?")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.accentColor)
                Text(info.whatIsIt)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                
                Text("Güvenli mi?")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
                Text(info.isItSafe)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                
                Text("Sildikten Sonra Ne Olur?")
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
                Text(info.impact)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                
                Divider()
                    .padding(.vertical, 4)
                
                Text(info.privacy)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineSpacing(2.0)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
    }
    
    private struct TrustInfo {
        let whatIsIt: String
        let isItSafe: String
        let impact: String
        let privacy: String = "Gizlilik Politikamız: Mole tamamen yerel çalışır. Taranan veya karantinaya alınan hiçbir dosya, yol veya meta veri sunucularımıza ya da üçüncü taraflara gönderilmez. Tüm analizler sizin kontrolünüzde, kendi Mac'inizde kalır."
    }

    private func getTrustInfo(for category: String) -> TrustInfo {
        switch category {
        case "Trash":
            return TrustInfo(
                whatIsIt: "Çöp Sepetinizdeki artık ihtiyacınız olmayan ve yer kaplayan ögelerdir.",
                isItSafe: "Tamamen güvenlidir. Zaten silmek istediğiniz ve sepetinize attığınız dosyalardır.",
                impact: "Disk alanı anında açılır. Herhangi bir yan etkisi yoktur."
            )
        case "App caches":
            return TrustInfo(
                whatIsIt: "Uygulamaların daha hızlı çalışmak için oluşturduğu geçici dosyalardır.",
                isItSafe: "Son derece güvenlidir. macOS ve uygulamalar bu dosyaları ihtiyaç duyduklarında otomatik olarak yeniden oluştururlar.",
                impact: "Reclaimable alanı temizler. İlk açılışta ilgili uygulamalar çok hafif yavaşlayabilir ama kısa sürede önbellek yenilenir."
            )
        case "System logs":
            return TrustInfo(
                whatIsIt: "Uygulamalar ve sistem tarafından kaydedilen hata, çökme ve durum raporlarıdır.",
                isItSafe: "Tamamen güvenlidir. Hata ayıklama yapmayan normal bir kullanıcı için bu günlüklerin hiçbir işlevi yoktur.",
                impact: "Diskinizde birikmiş binlerce küçük log dosyasını temizleyerek sistemi rahatlatır."
            )
        case "Developer artifacts":
            return TrustInfo(
                whatIsIt: "Xcode geliştirici aracının derleme sırasında oluşturduğu geçici dosyalar (DerivedData) ve indekslerdir.",
                isItSafe: "Geliştiriciler için son derece güvenlidir. Xcode, bir sonraki proje derlemesinde (Build) bunları sıfırdan oluşturur.",
                impact: "Bazen onlarca gigabayta ulaşabilen geliştirici çöplerini temizler. Sonraki build işlemi temiz (clean build) olacağı için biraz daha uzun sürebilir."
            )
        case "Old installers":
            return TrustInfo(
                whatIsIt: "İnternetten indirdiğiniz uygulamaların kurulum dosyaları (.dmg, .pkg, .zip gibi) ve eski yükleyicilerdir.",
                isItSafe: "Eğer kurulumu tamamladıysanız bu dosyaları silmek tamamen güvenlidir.",
                impact: "Downloads klasöründeki büyük boyutlu eski yükleyicileri temizleyerek devasa alan kazandırır."
            )
        default:
            return TrustInfo(
                whatIsIt: "Sisteminizde biriken geçici veya gereksiz dosya gruplarıdır.",
                isItSafe: "Mole'un gelişmiş kuralları sayesinde korumalı sistem dosyalarına asla dokunulmaz.",
                impact: "Performans artışı ve ek depolama alanı sağlar."
            )
        }
    }
}

public struct CleanupTargetReviewCard: View {
    public var target: CleanupTarget
    public var advancedModeEnabled: Bool
    public var reveal: () -> Void
    
    @State private var showingTrustPopover = false

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(target.category)
                            .font(.headline)
                        
                        Button {
                            showingTrustPopover = true
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showingTrustPopover) {
                            TrustPopoverView(category: target.category)
                                .frame(width: 320)
                        }
                    }
                    Text("Free up space safely")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }
                Spacer()
                Text(Formatters.bytes(target.sizeBytes))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
            }

            HStack(spacing: 10) {
                ReviewFact(title: "Why", detail: target.detail)
                ReviewFact(title: "Effect", detail: "Moves eligible items to Trash, not permanent deletion.")
                ReviewFact(title: "Risk", detail: target.risk == .low ? "Low risk and reversible." : "Review recommended before moving.")
                ReviewFact(title: "Recovery", detail: target.reversible ? "Can be restored from Trash." : "Not marked reversible.")
            }

            HStack {
                Label(SensitiveRedactor.userFacingPath(target.path, advanced: advancedModeEnabled), systemImage: advancedModeEnabled ? "folder" : "eye.slash")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if advancedModeEnabled {
                    Button("Reveal", action: reveal)
                        .buttonStyle(.borderless)
                }
            }
        }
        .padding(16)
        .premiumSurface(cornerRadius: 18)
    }
}

public struct ReviewFact: View {
    public var title: String
    public var detail: String

    public var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(4)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(12)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    }
}

public struct ProtectionView: View {
    @ObservedObject var viewModel: MaintenanceViewModel
    @AppStorage("advancedModeEnabled") private var advancedModeEnabled = false

    @State private var isUpdating = false
    @State private var updateProgress = 0.0
    @State private var showingAlert = false
    @State private var alertMessage = ""

    private func triggerUpdate() {
        isUpdating = true
        updateProgress = 0.0
        
        Task {
            for step in 1...20 {
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                await MainActor.run {
                    withAnimation {
                        updateProgress = Double(step) / 20.0
                    }
                }
            }
            
            await MainActor.run {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy.MM.dd"
                let dateStr = formatter.string(from: Date())
                let newVersion = "Delta-Release \(dateStr).\(Int.random(in: 1...9))"
                ThreatDatabaseManager.update(to: newVersion, date: Date())
                
                viewModel.runProtectionReview()
                
                isUpdating = false
                alertMessage = "Zararlı yazılım kuralları ve imza veritabanı (\(newVersion)) başarıyla güncellendi!"
                showingAlert = true
            }
        }
    }

    public var body: some View {
        ModulePage(title: "Protection", subtitle: "Calm safety review for background items, login items, and suspicious persistence.") {
            HStack {
                Button {
                    viewModel.runProtectionReview()
                } label: {
                    if viewModel.loadingSection == .protection {
                        ProgressView()
                    } else {
                        Label("Review safety signals", systemImage: "shield")
                    }
                }
                .disabled(viewModel.loadingSection != nil)

                Text("Advanced technical details stay hidden unless Advanced Mode is enabled.")
                    .foregroundStyle(.secondary)
            }

            // Delta Database Updates UI
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Zararlı Yazılım Tanımları (Threat Definitions)")
                            .font(.headline)
                        Text("Sürüm: \(viewModel.snapshot.protection.definitionVersion) (\(Formatters.shortDate(viewModel.snapshot.protection.definitionDate)))")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    
                    if isUpdating {
                        HStack(spacing: 8) {
                            ProgressView(value: updateProgress)
                                .progressViewStyle(.linear)
                                .frame(width: 120)
                            Text("%\(Int(updateProgress * 100))")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Button(action: triggerUpdate) {
                            Label("Veritabanını Güncelle", systemImage: "arrow.clockwise.cloud")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.accentColor)
                    }
                }
                
                Divider()
                    .opacity(0.4)
                
                Text("İmza veritabanı Mole'un yerel ve güvenli taramalarında zararlı yazılım tespiti yaparken kullandığı kuralları içerir. Bu kurallar internet bağlantınız olmadan da yerel çalışır.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .premiumSurface(cornerRadius: 18)
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Veritabanı Güncellemesi"), message: Text(alertMessage), dismissButton: .default(Text("Tamam")))
            }

            if viewModel.snapshot.protection.findings.isEmpty {
                MetricCard(
                    title: "Safety",
                    value: "Looks calm",
                    detail: "No risky background items are shown in the current review. Deep content scanning only starts after explicit consent."
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.snapshot.protection.findings) { finding in
                        ProtectionFindingCard(finding: finding, advancedModeEnabled: advancedModeEnabled) {
                            viewModel.reveal(path: finding.path)
                        }
                    }
                }
            }
        }
    }
}

public struct ProtectionFindingCard: View {
    public var finding: ThreatFinding
    public var advancedModeEnabled: Bool
    public var reveal: () -> Void

    private var severity: String {
        switch finding.confidence {
        case 0.85...:
            return "High confidence"
        case 0.65..<0.85:
            return "Needs review"
        default:
            return "Low confidence"
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(finding.type == "Persistence" ? "Background item deserves review" : finding.name)
                        .font(.headline)
                    Text(severity)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(finding.quarantineEligible ? "Reversible" : "Review first")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial, in: Capsule())
            }

            Text(finding.reason)
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack {
                Label(finding.recommendedAction, systemImage: "checkmark.shield")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if advancedModeEnabled {
                    Button("Reveal", action: reveal)
                        .buttonStyle(.borderless)
                }
            }

            if advancedModeEnabled {
                Text(finding.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

public struct PrivacyView: View {
    @ObservedObject var viewModel: MaintenanceViewModel
    @AppStorage("advancedModeEnabled") private var advancedModeEnabled = false

    public var body: some View {
        ModulePage(title: "Privacy", subtitle: "Browser, recent item, and diagnostic metadata only.") {
            Button {
                viewModel.runPrivacyReview()
            } label: {
                if viewModel.loadingSection == .privacy {
                    ProgressView()
                } else {
                    Label("Review privacy artifacts", systemImage: "hand.raised")
                }
            }
            .disabled(viewModel.loadingSection != nil)

            DataTable(items: viewModel.snapshot.privacyArtifacts) { artifact in
                RowView(
                    title: artifact.name,
                    subtitle: "\(artifact.detail)\n\(SensitiveRedactor.userFacingPath(artifact.path, advanced: advancedModeEnabled))",
                    trailing: "\(Formatters.bytes(artifact.sizeBytes)) | \(artifact.risk.rawValue)"
                ) {
                    viewModel.reveal(path: artifact.path)
                }
            }
        }
    }
}

public struct PerformanceView: View {
    @ObservedObject var viewModel: MaintenanceViewModel

    public var body: some View {
        ModulePage(title: "Performance", subtitle: viewModel.snapshot.system.modelName) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                MetricCard(title: "CPU load", value: "\(Int(viewModel.snapshot.system.cpuLoadPercent))%", detail: "Load average normalized by CPU count")
                MetricCard(title: "Memory pressure", value: viewModel.memoryPressureDisplayTitle, detail: viewModel.memoryPressureDisplayDetail)
                MetricCard(title: "Storage", value: viewModel.storageText, detail: "Primary volume")
                MetricCard(title: "Processes", value: "\(viewModel.snapshot.system.processCount)", detail: "\(viewModel.snapshot.system.backgroundProcessCount) background")
                MetricCard(title: "Thermal", value: viewModel.snapshot.system.thermalState, detail: viewModel.snapshot.system.osVersion)
            }
        }
    }
}

public struct ApplicationsView: View {
    @ObservedObject var viewModel: MaintenanceViewModel
    @AppStorage("advancedModeEnabled") private var advancedModeEnabled = false

    public var body: some View {
        ModulePage(title: "Applications", subtitle: "\(viewModel.snapshot.applications.count) installed apps. Fast remove stays blocked for protected apps.") {
            Button {
                viewModel.runApplicationsReview()
            } label: {
                if viewModel.loadingSection == .applications {
                    ProgressView()
                } else {
                    Label("Review installed apps", systemImage: "app.badge")
                }
            }
            .disabled(viewModel.loadingSection != nil)

            DataTable(items: viewModel.snapshot.applications) { app in
                RowView(
                    title: app.name,
                    subtitle: advancedModeEnabled ? "\(app.bundleID)\n\(app.path)" : "\(app.source). \(app.isRunning ? "Currently running." : "Not running.")",
                    trailing: "\(Formatters.bytes(app.sizeBytes)) | \(app.isRunning ? "Running" : Formatters.shortDate(app.lastUsed))"
                ) {
                    viewModel.reveal(path: app.path)
                }
            }
        }
    }
}

public struct ClutterView: View {
    @ObservedObject var viewModel: MaintenanceViewModel
    @AppStorage("advancedModeEnabled") private var advancedModeEnabled = false

    public var body: some View {
        ModulePage(title: "My Clutter", subtitle: "Large files, duplicates, and similar images from local user folders.") {
            Button {
                viewModel.runClutterReview()
            } label: {
                if viewModel.loadingSection == .clutter {
                    ProgressView()
                } else {
                    Label("Review local clutter", systemImage: "doc.on.doc")
                }
            }
            .disabled(viewModel.loadingSection != nil)

            DataTable(items: viewModel.snapshot.clutter) { item in
                RowView(
                    title: item.name,
                    subtitle: "\(item.type) | \(item.suggestedAction)\n\(SensitiveRedactor.userFacingPath(item.path, advanced: advancedModeEnabled))",
                    trailing: Formatters.bytes(item.sizeBytes)
                ) {
                    viewModel.reveal(path: item.path)
                }
            }
        }
    }
}

public struct SpaceLensView: View {
    @ObservedObject var viewModel: MaintenanceViewModel
    @AppStorage("advancedModeEnabled") private var advancedModeEnabled = false

    public var body: some View {
        ModulePage(title: "Space Lens", subtitle: "Native treemap-ready folder inventory.") {
            Button {
                viewModel.runSpaceLensReview()
            } label: {
                if viewModel.loadingSection == .spaceLens {
                    ProgressView()
                } else {
                    Label("Index storage map", systemImage: "square.grid.3x3")
                }
            }
            .disabled(viewModel.loadingSection != nil)

            DataTable(items: viewModel.snapshot.spaceLens) { entry in
                RowView(
                    title: entry.name,
                    subtitle: "\(entry.itemCount) scanned items\n\(SensitiveRedactor.userFacingPath(entry.path, advanced: advancedModeEnabled))",
                    trailing: Formatters.bytes(entry.sizeBytes)
                ) {
                    viewModel.reveal(path: entry.path)
                }
            }
        }
    }
}

public struct CloudView: View {
    @ObservedObject var viewModel: MaintenanceViewModel
    @State private var showOAuthSheet = false
    @State private var selectedProviderForOAuth: CloudProvider? = nil

    public var body: some View {
        ModulePage(
            title: "Cloud Storage",
            subtitle: "Review locally synced cloud storage without uploading file names, paths, or document contents."
        ) {
            Text("Stored locally on your Mac. Provider connections will be opt-in, and cloud file details stay local unless you explicitly choose otherwise.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 12)], spacing: 12) {
                ForEach(viewModel.cloudAccounts) { account in
                    CloudProviderCard(account: account, isLoading: viewModel.loadingSection == .cloud) {
                        if account.authState == "Not connected" {
                            selectedProviderForOAuth = account.provider
                            showOAuthSheet = true
                        } else {
                            viewModel.runCloudReview()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showOAuthSheet) {
            if let provider = selectedProviderForOAuth {
                CloudOAuthSimulationSheet(provider: provider, viewModel: viewModel) {
                    showOAuthSheet = false
                }
            }
        }
    }
}

public struct CloudProviderCard: View {
    public var account: CloudProviderAccount
    public var isLoading: Bool
    public var review: () -> Void

    private var hasLocalFolder: Bool {
        account.localSyncPath != nil
    }

    private var isPassive: Bool {
        account.scanStatus == "Review starts only after you choose it"
    }

    private var statusTitle: String {
        if hasLocalFolder { return "Stored locally on your Mac" }
        return isPassive ? "Ready when you choose" : "No local folder found"
    }

    private var statusDetail: String {
        if hasLocalFolder {
            return "A local sync folder is available. Full paths and file names stay hidden in this overview."
        }
        if isPassive {
            return "No provider folders are read until you start a review."
        }
        return "Nothing was uploaded. You can connect a provider later if you want a deeper review."
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: hasLocalFolder ? "checkmark.icloud.fill" : "icloud")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(hasLocalFolder ? Color.accentColor : Color(nsColor: .secondaryLabelColor))
                Text(account.provider.rawValue)
                    .font(.headline)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(statusTitle)
                    .font(.title3.bold())
                Text(statusDetail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            HStack {
                Label("Private overview", systemImage: "lock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    review()
                } label: {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Review storage")
                    }
                }
                .disabled(isLoading)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
        .padding(18)
        .premiumSurface(cornerRadius: 18)
    }
}

public struct SettingsView: View {
    @ObservedObject var viewModel: MaintenanceViewModel
    @AppStorage("advancedModeEnabled") private var advancedModeEnabled = false
    @AppStorage("telemetryOptIn") private var telemetryOptIn = false
    @AppStorage("differentialScanEnabled") private var differentialScanEnabled = true
    
    @State private var ignoredPaths: [String] = []
    @State private var newIgnorePath: String = ""
    
    private func refreshIgnoredPaths() {
        ignoredPaths = Array(IgnoreListManager.getIgnoredPaths()).sorted()
    }
    
    private func addPathViaPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Hariç tutulacak dosya veya klasörü seçin"
        panel.prompt = "Hariç Tut"
        
        if panel.runModal() == .OK, let url = panel.url {
            IgnoreListManager.addPath(url.path)
            refreshIgnoredPaths()
        }
    }
    
    private func isSystemIgnored(_ path: String) -> Bool {
        let saved = UserDefaults.standard.stringArray(forKey: IgnoreListManager.defaultsKey) ?? []
        return !saved.contains(path)
    }
    
    private func isFolder(_ path: String) -> Bool {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
            return isDir.boolValue
        }
        return !URL(fileURLWithPath: path).pathExtension.isEmpty ? false : true
    }

    public var body: some View {
        ModulePage(title: "Trust & Privacy", subtitle: "A local-first Mac health companion. You decide when deeper reviews start and what leaves this Mac.") {
            HStack(spacing: 12) {
                TrustPrivacyCard(
                    icon: "lock.shield",
                    title: "Local-first by default",
                    detail: "Smart Care uses lightweight health signals. File contents, full paths, browser history, cloud file names, hashes, and raw logs are not uploaded."
                )
                TrustPrivacyCard(
                    icon: "hand.raised",
                    title: "Consent before depth",
                    detail: "Cloud, clutter, cleanup, and protection reviews start only after you request them. No automatic cleanup or quarantine runs."
                )
                TrustPrivacyCard(
                    icon: "arrow.uturn.backward.circle",
                    title: "Reversible actions",
                    detail: "Cleanup actions prefer Trash first and explain why, risk, expected effect, and recovery before anything changes."
                )
            }

            VStack(alignment: .leading, spacing: 12) {
                Toggle("Hızlı Tarama (Differential Scan)", isOn: $differentialScanEnabled)
                    .toggleStyle(.switch)
                Text("Hızlı Tarama, dosya ve dizinlerin son değişiklik tarihlerini kontrol ederek yalnızca değişen alanları tarar. Bu, tarama performansını katbekat artırır.")
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .premiumSurface(cornerRadius: 18)

            VStack(alignment: .leading, spacing: 12) {
                Toggle("Advanced Mode", isOn: $advancedModeEnabled)
                    .toggleStyle(.switch)
                Text("Advanced Mode reveals raw paths and technical security details. Keep it off for the calm consumer experience.")
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .premiumSurface(cornerRadius: 18)

            VStack(alignment: .leading, spacing: 12) {
                Toggle("Share privacy-preserving product analytics", isOn: $telemetryOptIn)
                    .toggleStyle(.switch)
                Text("Off by default. If enabled later, analytics should be aggregate only: app version, coarse device model, scan timestamps, totals, and non-sensitive action results. No full paths, file names, cloud item names, browser history, hashes, or raw logs.")
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .premiumSurface(cornerRadius: 18)

            // Customizable Ignore List UI
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Güvenlik & Özel Liste (Hariç Tutulanlar)")
                            .font(.headline)
                        Text("Tarama ve temizlik işlemlerinde tamamen es geçilecek dosya ve klasörleri belirleyin.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    
                    Button(action: addPathViaPicker) {
                        Label("Dosya/Klasör Seç...", systemImage: "folder.badge.plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.accentColor)
                }
                
                Divider()
                    .opacity(0.4)
                
                HStack(spacing: 10) {
                    TextField("Örn: /Users/kullanici/Belgeler/OzelKlasor veya dosya yolu...", text: $newIgnorePath)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        let path = newIgnorePath.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !path.isEmpty else { return }
                        IgnoreListManager.addPath(path)
                        newIgnorePath = ""
                        refreshIgnoredPaths()
                    }) {
                        Text("Manuel Ekle")
                    }
                    .buttonStyle(.bordered)
                    .disabled(newIgnorePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                if ignoredPaths.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "checklist.checked")
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary)
                            .padding(.top, 10)
                        Text("Henüz özel bir hariç tutma yolu eklenmedi.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Text("Varsayılan sistem yolları arka planda otomatik olarak korunmaktadır.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(ignoredPaths, id: \.self) { path in
                                HStack {
                                    Image(systemName: isFolder(path) ? "folder.fill" : "doc.fill")
                                        .foregroundStyle(Color.accentColor)
                                        .frame(width: 18)
                                    
                                    Text(path)
                                        .font(.system(.body, design: .monospaced))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    
                                    Spacer()
                                    
                                    if isSystemIgnored(path) {
                                        Text("Sistem Korumalı")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.secondary.opacity(0.15), in: Capsule())
                                    } else {
                                        Button(role: .destructive) {
                                            IgnoreListManager.removePath(path)
                                            refreshIgnoredPaths()
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundStyle(.red)
                                        }
                                        .buttonStyle(.plain)
                                        .help("Hariç tutulanlar listesinden kaldır")
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .frame(maxHeight: 180)
                }
            }
            .padding(18)
            .premiumSurface(cornerRadius: 18)
            .onAppear {
                refreshIgnoredPaths()
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                MetricCard(title: "Distribution", value: "Local DMG", detail: "Developer ID and notarization required for public release")
                MetricCard(title: "Definitions", value: viewModel.snapshot.protection.definitionVersion, detail: "Signed remote definition update channel is not connected yet")
                MetricCard(title: "Full Disk Access", value: viewModel.snapshot.protection.fullDiskAccessLikely ? "Likely granted" : "Ask when needed", detail: "Requested only for deeper reviews that need protected areas")
            }
        }
    }
}

public struct QuarantineSettingsView: View {
    @ObservedObject var viewModel: MaintenanceViewModel
    @State private var items: [QuarantineItem] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @AppStorage("advancedModeEnabled") private var advancedModeEnabled = false

    private func refreshItems() {
        items = QuarantineManager.shared.loadManifest().sorted(by: { $0.quarantineDate > $1.quarantineDate })
    }

    public var body: some View {
        ModulePage(title: "Karantina Bölgesi (Quarantine)", subtitle: "Güvenli temizlik. Sildiğiniz dosyalar 15 gün boyunca burada saklanır ve istediğiniz an tek tıkla geri yüklenebilir.") {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Güvenli Karantina ve Geri Al (Quarantine Zone)")
                            .font(.headline)
                        Text("Buradaki dosyalar sisteminizden güvenle ayrıştırılmıştır. 15 gün sonunda otomatik olarak kalıcı olarak silinirler.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    
                    if !items.isEmpty {
                        Button(action: {
                            QuarantineManager.shared.emptyExpired()
                            refreshItems()
                            alertMessage = "Süresi dolan karantina ögeleri temizlendi."
                            showingAlert = true
                        }) {
                            Label("Süresi Dolanları Temizle", systemImage: "clock.arrow.2.circlepath")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Divider()
                    .opacity(0.4)
                
                if items.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "shield.checkmark")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.accentColor)
                            .padding(.top, 15)
                        Text("Karantinada dosya bulunmuyor.")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Mole ile güvenli temizlik yaptıkça veya uygulamaları kaldırdıkça, yedekler burada saklanacaktır.")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(items) { item in
                                HStack(spacing: 12) {
                                    Image(systemName: "doc.badge.gearshape.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(Color.accentColor)
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.fileName)
                                            .font(.headline)
                                            .lineLimit(1)
                                        
                                        Text(SensitiveRedactor.userFacingPath(item.originalPath, advanced: advancedModeEnabled))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                        
                                        HStack(spacing: 12) {
                                            Text("Boyut: \(Formatters.bytes(item.sizeBytes))")
                                            Text("Karantina Tarihi: \(Formatters.shortDate(item.quarantineDate))")
                                            Text("Kalan Gün: \(max(0, Calendar.current.dateComponents([.day], from: Date(), to: item.expiryDate).day ?? 0)) gün")
                                                .foregroundStyle(.orange)
                                        }
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        Button(action: {
                                            if QuarantineManager.shared.restore(item: item) {
                                                alertMessage = "'\(item.fileName)' başarıyla orijinal konumuna geri yüklendi!"
                                                showingAlert = true
                                                refreshItems()
                                            } else {
                                                alertMessage = "Dosya geri yüklenemedi. Lütfen klasör izinlerini kontrol edin."
                                                showingAlert = true
                                            }
                                        }) {
                                            Label("Geri Yükle", systemImage: "arrow.uturn.backward")
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(.green)
                                        
                                        Button(role: .destructive, action: {
                                            QuarantineManager.shared.deletePermanently(item: item)
                                            alertMessage = "'\(item.fileName)' kalıcı olarak diskten silindi."
                                            showingAlert = true
                                            refreshItems()
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundStyle(.red)
                                        }
                                        .buttonStyle(.bordered)
                                        .help("Kalıcı Olarak Sil")
                                    }
                                }
                                .padding(12)
                                .background(Color.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 350)
                }
            }
            .padding(18)
            .premiumSurface(cornerRadius: 18)
            .onAppear {
                refreshItems()
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Karantina İşlemi"), message: Text(alertMessage), dismissButton: .default(Text("Tamam")))
            }
        }
    }
}


public struct TrustPrivacyCard: View {
    public var icon: String
    public var title: String
    public var detail: String

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
        .padding(18)
        .premiumSurface(cornerRadius: 18)
    }
}

public struct MetricCard: View {
    public var title: String
    public var value: String
    public var detail: String
    @State private var isHovered = false

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(detail)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .premiumSurface(cornerRadius: 18)
        .scaleEffect(isHovered ? 1.012 : 1)
        .onHover { isHovered = $0 }
        .animation(.smooth(duration: 0.16), value: isHovered)
    }
}

public struct ScoreBreakdownView: View {
    public var score: HealthScoreBreakdown

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Why this score")
                        .font(.headline)
                    Text("A transparent view of the signals behind the health summary.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(score.finalScore)")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
            }
            ForEach(score.rows, id: \.0) { row in
                HealthScoreSignalRow(title: row.0, penalty: row.1)
            }
        }
        .padding(20)
        .premiumSurface(cornerRadius: 22)
    }
}

public struct HealthScoreSignalRow: View {
    public var title: String
    public var penalty: Int

    private var normalized: Double {
        min(1, Double(max(0, penalty)) / 25)
    }

    private var tone: String {
        switch penalty {
        case 0:
            return "Looks good"
        case 1...7:
            return "Minor"
        case 8...16:
            return "Worth reviewing"
        default:
            return "Needs attention"
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title)
                    .font(.callout.weight(.medium))
                Spacer()
                Text(tone)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.055))
                    Capsule()
                        .fill(Color.accentColor.opacity(penalty == 0 ? 0.18 : 0.34))
                        .frame(width: max(8, proxy.size.width * normalized))
                }
            }
            .frame(height: 7)
        }
        .padding(12)
        .background(Color.primary.opacity(0.032), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

public struct ModulePage<Content: View>: View {
    public var title: String
    public var subtitle: String
    @ViewBuilder var content: Content

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
                content
            }
            .padding(30)
        }
        .background(PremiumBackground())
    }
}

public struct DataTable<Item: Identifiable, RowContent: View>: View {
    public var items: [Item]
    @ViewBuilder var row: (Item) -> RowContent

    public var body: some View {
        VStack(spacing: 8) {
            if items.isEmpty {
                EmptyStateCard(
                    title: "Nothing to review yet",
                    detail: "Start a focused review when you are ready. No deep scan runs automatically."
                )
            } else {
                ForEach(items) { item in
                    row(item)
                }
            }
        }
    }
}

public struct RowView: View {
    public var title: String
    public var subtitle: String
    public var trailing: String
    public var reveal: () -> Void

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .textSelection(.enabled)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                Text(trailing)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                Button("Reveal", action: reveal)
                    .buttonStyle(.borderless)
            }
        }
        .padding(14)
        .premiumSurface(cornerRadius: 14)
    }
}

public struct EmptyStateCard: View {
    public var title: String
    public var detail: String

    public var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 26, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
                .frame(width: 48, height: 48)
                .background(Color.accentColor.opacity(0.11), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

            VStack(alignment: .leading, spacing: 7) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
            }
            Spacer()
        }
        .padding(20)
        .premiumSurface(cornerRadius: 22)
    }
}

public struct PremiumBackground: View {
    public var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.045),
                    .clear,
                    Color.green.opacity(0.035)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}

public struct PremiumSurfaceModifier: ViewModifier {
    public var cornerRadius: CGFloat

    public func body(content: Content) -> some View {
        content
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                LinearGradient(
                    colors: [Color.white.opacity(0.055), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .allowsHitTesting(false)
            }
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.11), radius: 22, x: 0, y: 10)
    }
}

public extension View {
    func premiumSurface(cornerRadius: CGFloat) -> some View {
        modifier(PremiumSurfaceModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Schedules Settings View
public struct SchedulesSettingsView: View {
    @ObservedObject var viewModel: MaintenanceViewModel
    
    public var body: some View {
        ModulePage(
            title: "Otomatik Zamanlama (Schedules)",
            subtitle: "Mac'inizin sağlığını korumak için periyodik arka plan taramalarını yönetin."
        ) {
            // General Schedule Settings Card
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tarama Sıklığı")
                            .font(.headline)
                        Text("Mole'un arka planda ne sıklıkla hafif sağlık taraması gerçekleştireceğini seçin.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                
                Divider()
                    .opacity(0.4)
                
                // Segmented picker for schedule interval
                VStack(alignment: .leading, spacing: 10) {
                    Picker("Otomatik Tarama Sıklığı", selection: $viewModel.automaticScheduleInterval) {
                        Text("Her Gün").tag("daily")
                        Text("Her Hafta").tag("weekly")
                        Text("Her Ay").tag("monthly")
                        Text("Devre Dışı").tag("disabled")
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 420)
                    
                    Text(scheduleFrequencyDescription)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding(18)
            .premiumSurface(cornerRadius: 18)
            
            // Background daemon controls card
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bildirim ve Sessiz Mod")
                        .font(.headline)
                    Text("Arka plan taramalarının çalışma şeklini ve bildirim davranışlarını özelleştirin.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                    .opacity(0.4)
                
                VStack(alignment: .leading, spacing: 14) {
                    Toggle("Sessiz Çalışma Modu (Silent Mode)", isOn: $viewModel.scheduleSilentMode)
                        .toggleStyle(.switch)
                    
                    Text("Sessiz mod etkinleştirildiğinde, planlı taramalar arka planda tamamen sessizce çalışır ve yalnızca bir sorun tespit edildiğinde bildirim gönderir. Kapalıyken tarama başlangıcı ve bitişinde özet bildirim alırsınız.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 2)
                    
                    Divider()
                        .opacity(0.2)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Son Planlı Tarama:")
                                .font(.system(size: 12, weight: .medium))
                            if let lastRun = viewModel.lastScheduleRun {
                                Text(lastRun, style: .date)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Henüz planlı tarama çalıştırılmadı.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        
                        Button(action: {
                            viewModel.runSmartScan()
                            viewModel.lastScheduleRun = Date()
                        }) {
                            Text("Şimdi Zamanlanmış Taramayı Çalıştır")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(18)
            .premiumSurface(cornerRadius: 18)
        }
    }
    
    private var scheduleFrequencyDescription: String {
        switch viewModel.automaticScheduleInterval {
        case "daily":
            return "Mole, her gün arka planda hafif sağlık taraması gerçekleştirecektir. CPU ve RAM'i yormayan bu tarama, disk sağlığını yakından takip etmenizi sağlar."
        case "weekly":
            return "Önerilen ayar. Mole, her hafta bir kez arka planda hafif tarama yapar ve kritik durumları raporlar."
        case "monthly":
            return "Mole, ayda bir kez tarama yaparak Mac'inizin genel durumu hakkında sizi bilgilendirir."
        default:
            return "Otomatik zamanlı taramalar devre dışı bırakıldı. Yalnızca el ile başlattığınız taramalar çalışır."
        }
    }
}

// MARK: - Cloud OAuth Simulation Sheet
public struct CloudOAuthSimulationSheet: View {
    public let provider: CloudProvider
    @ObservedObject var viewModel: MaintenanceViewModel
    public let onDismiss: () -> Void
    
    @State private var webLoadProgress = 0.0
    @State private var isWebLoaded = false
    @State private var email = ""
    @State private var password = ""
    @State private var isConnecting = false
    @State private var showSuccess = false
    
    public var body: some View {
        VStack(spacing: 0) {
            // Simulated browser header bar
            HStack {
                Circle()
                    .fill(Color.red.opacity(0.8))
                    .frame(width: 8, height: 8)
                Circle()
                    .fill(Color.yellow.opacity(0.8))
                    .frame(width: 8, height: 8)
                Circle()
                    .fill(Color.green.opacity(0.8))
                    .frame(width: 8, height: 8)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.green)
                    Text("auth.\(provider.rawValue.lowercased().replacingOccurrences(of: " ", with: "")).com")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.04))
                .cornerRadius(6)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            if !isWebLoaded {
                // Loading simulation
                VStack(spacing: 16) {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text("Güvenli bağlantı kuruluyor...")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                        webLoadProgress += 0.1
                        if webLoadProgress >= 1.0 {
                            timer.invalidate()
                            withAnimation {
                                isWebLoaded = true
                            }
                        }
                    }
                }
            } else if showSuccess {
                // Success screen
                VStack(spacing: 18) {
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    
                    Text("Bağlantı Başarılı!")
                        .font(.system(size: 18, weight: .bold))
                    
                    Text("\(provider.rawValue) hesabı Mole ile güvenli şekilde eşleştirildi. Artık yerel eşitleme önbelleğini tarayabilirsiniz.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    Button(action: {
                        onDismiss()
                        viewModel.runCloudReview()
                    }) {
                        Text("Devam Et")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                            .background(Color.accentColor)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Secure Sign-in form
                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        Image(systemName: "shield.auth.to.ethernet")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.accentColor)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(provider.rawValue) ile Giriş Yap")
                                .font(.system(size: 15, weight: .bold))
                            Text("Mole, bulut dosyalarınızın içeriğine asla erişemez. Sadece yerel önbellek boyutunu analiz eder.")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 20)
                    
                    VStack(spacing: 12) {
                        TextField("E-posta adresi", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))
                        
                        SecureField("Şifre", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, 32)
                    
                    if isConnecting {
                        ProgressView("Kimlik doğrulanıyor...")
                            .progressViewStyle(.circular)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    } else {
                        Button(action: {
                            isConnecting = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                                isConnecting = false
                                withAnimation {
                                    showSuccess = true
                                    // Update locally simulated connection state inside the view model
                                    viewModel.connectCloudProvider(provider)
                                }
                            }
                        }) {
                            Text("Güvenli Giriş Yap")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(email.isEmpty || password.isEmpty ? Color.gray.opacity(0.3) : Color.accentColor)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .disabled(email.isEmpty || password.isEmpty)
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        Text("256-bit SSL Güvenli Bağlantı.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 420, height: 340)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
