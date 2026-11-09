import SwiftUI
import AVFoundation
import Vision
import CoreBluetooth

// MARK: - =====================================================================
// T-FLOW BRAND LOGO VECTOR (NATIVE SWIFTUI)
// =====================================================================
struct TFlowBrandLogo: View {
    var size: CGFloat = 28
    var strokeColor: Color = .white
    var bgColor: Color = .black

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.26)
                .fill(bgColor)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.26)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )

            Canvas { context, sz in
                let scale = sz.width / 100.0
                var path = Path()

                // Wave curve
                path.move(to: CGPoint(x: 16 * scale, y: 34 * scale))
                path.addCurve(
                    to: CGPoint(x: 50 * scale, y: 34 * scale),
                    control1: CGPoint(x: 26 * scale, y: 21 * scale),
                    control2: CGPoint(x: 39 * scale, y: 21 * scale)
                )
                path.addCurve(
                    to: CGPoint(x: 84 * scale, y: 34 * scale),
                    control1: CGPoint(x: 61 * scale, y: 47 * scale),
                    control2: CGPoint(x: 74 * scale, y: 47 * scale)
                )

                // Vertical stem
                path.move(to: CGPoint(x: 50 * scale, y: 34 * scale))
                path.addLine(to: CGPoint(x: 50 * scale, y: 82 * scale))

                context.stroke(
                    path,
                    with: .color(strokeColor),
                    style: StrokeStyle(lineWidth: 12 * scale, lineCap: .round, lineJoin: .round)
                )
            }
            .padding(size * 0.16)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - =====================================================================
// APP ENTRY POINT
// =====================================================================
@main
struct SmartGimbalApp: App {
    @StateObject private var store = SupabaseModuleStore()
    @StateObject private var ble = BLEGimbalManager()

    var body: some Scene {
        WindowGroup {
            MainTabShellView()
                .environmentObject(store)
                .environmentObject(ble)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - =====================================================================
// 1. SUPABASE CLOUD AI & 7-MODULE REALTIME STORE
// =====================================================================
@MainActor
final class SupabaseModuleStore: ObservableObject {
    private let supabaseUrl = "https://dlgkrwodxdsbbliwdnkg.supabase.co"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRsZ2tyd29keGRzYmJsaXdkbmtnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQxMjIwNjQsImV4cCI6MjEwOTY5ODA2NH0.Lg6C6MpLhX_CoKgWtl_nhWLGNw5NuYE9FZJoTxXnu6I"

    @Published var userName: String = "Đặng Anh Dũng"
    @Published var userTier: String = "Pro Cinema Tier"
    @Published var deviceName: String = "Smart Gimbal S1 Titanium"
    @Published var modules: [Bool] = [true, true, true, true, true, true, true]
    @Published var isOnline: Bool = true
    @Published var lastSyncText: String = "Đã đồng bộ T-Flow Cloud"

    private var timer: Timer?

    init() {
        Task { await fetchUserPermissions() }
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { await self?.fetchUserPermissions() }
        }
    }

    var isAiVisionAllowed: Bool {
        modules.indices.contains(0) ? modules[0] : true
    }

    func fetchUserPermissions() async {
        guard let url = URL(string: "\(supabaseUrl)/rest/v1/users?id=eq.usr-dung&select=*") else { return }
        var req = URLRequest(url: url)
        req.timeoutInterval = 4.0
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
                isOnline = false
                return
            }
            isOnline = true
            if let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let first = arr.first {
                if let name = first["name"] as? String { userName = name }
                if let tier = first["tier_badge"] as? String { userTier = tier }
                if let dev = first["device"] as? String { deviceName = dev }
                if let mods = first["modules"] as? [Bool], mods.count >= 7 {
                    modules = mods
                }
            }
        } catch {
            isOnline = false
        }
    }
}

// MARK: - =====================================================================
// 2. COREBLUETOOTH BLE 5.3 GIMBAL CONTROLLER (50Hz)
// =====================================================================
@MainActor
final class BLEGimbalManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    @Published var isConnected: Bool = true
    @Published var gimbalMode: String = "PF"
    @Published var batteryLevel: Int = 94
    @Published var yawOffset: Double = 0.0
    @Published var pitchOffset: Double = 0.0

    // Realtime angle telemetry
    @Published var rollAngle: Double = 0.02
    @Published var pitchAngle: Double = 12.4
    @Published var panAngle: Double = 359.8
    @Published var joystickSensitivity: Double = 0.65

    private var central: CBCentralManager?

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // BLE ready
    }

    func sendTrackingError(dx: Double, dy: Double) {
        yawOffset = (dx * 45.0)
        pitchOffset = (-dy * 35.0)
        panAngle = (359.8 + yawOffset).truncatingRemainder(dividingBy: 360.0)
        pitchAngle = 12.4 + pitchOffset
    }

    func autoCalibrateMotors() {
        rollAngle = 0.0
        pitchAngle = 0.0
        panAngle = 0.0
    }
}

// MARK: - =====================================================================
// 3. MAIN NAVIGATION SHELL (FIGMA APPLE HIG TAB BAR)
// =====================================================================
struct MainTabShellView: View {
    @State private var selectedTab: Int = 0

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 0.95)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            CameraStudioNativeView()
                .tabItem {
                    Label("Camera AI", systemImage: "camera.aperture")
                }
                .tag(0)

            GimbalDeviceHubView()
                .tabItem {
                    Label("T-Flow Pro", systemImage: "gyroscope")
                }
                .tag(1)

            TFlowAIChatAssistantView()
                .tabItem {
                    Label("T-Flow Bot", systemImage: "sparkles")
                }
                .tag(2)

            UserProfilePermissionsView()
                .tabItem {
                    Label("Tài Khoản", systemImage: "person.crop.circle")
                }
                .tag(3)
        }
        .tint(Color(red: 0.98, green: 0.72, blue: 0.10)) // Apple Amber Gold Accent
    }
}

// MARK: - =====================================================================
// 4. SCREEN 01: 98% CLEAR VIEWFINDER WITH APPLE FROSTED GLASS HUD
// =====================================================================
struct CameraStudioNativeView: View {
    @EnvironmentObject var store: SupabaseModuleStore
    @EnvironmentObject var ble: BLEGimbalManager

    @State private var isAiActive: Bool = true
    @State private var isRecording: Bool = false
    @State private var selectedCamMode: String = "VIDEO 4K/60"
    @State private var selectedAspectRatio: String = "16:9"
    @State private var showAspectPicker: Bool = false
    @State private var faceBox: CGRect = CGRect(x: 0.35, y: 0.30, width: 0.30, height: 0.34)

    let aspectRatios = ["16:9", "9:16", "2.39:1", "4:3", "1:1"]
    let gimbalModes = ["PF", "FPV", "LOCK", "360°"]
    let camModes = ["TIMELAPSE", "SLOW-MO", "VIDEO 4K/60", "PHOTO", "PRO CINEMA"]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Live AVFoundation Camera Preview
                NativeCameraPreviewRepresentable(onFaceDetected: { normalizedRect in
                    if let rect = normalizedRect {
                        withAnimation(.linear(duration: 0.08)) {
                            faceBox = rect
                        }
                        let dx = Double(rect.midX - 0.5)
                        let dy = Double(rect.midY - 0.5)
                        ble.sendTrackingError(dx: dx, dy: dy)
                    }
                })
                .ignoresSafeArea()

                // Minimalist Rule of Thirds Grid (Ultra Subtle 12% Opacity)
                RuleOfThirdsGridView()
                    .ignoresSafeArea()

                // MINIMALIST CINEMATIC AI TARGET RETICLE (Figma Screen 04 Specs: Titanium White, No Neon Borders)
                if store.isOnline && store.isAiVisionAllowed && isAiActive {
                    let bx = faceBox.minX * geo.size.width
                    let by = faceBox.minY * geo.size.height
                    let bw = faceBox.width * geo.size.width
                    let bh = faceBox.height * geo.size.height

                    ZStack {
                        // 4 Sleek Corner Brackets
                        CinematicReticleShape()
                            .stroke(Color.white.opacity(0.85), lineWidth: 1.8)
                            .frame(width: max(bw, 70), height: max(bh, 70))
                            .shadow(color: Color.black.opacity(0.6), radius: 4)

                        // Center Focus Dot
                        Circle()
                            .fill(Color(red: 0.98, green: 0.72, blue: 0.10))
                            .frame(width: 4, height: 4)

                        // Subtle Lock Pill
                        HStack(spacing: 4) {
                            Circle().fill(Color.green).frame(width: 5, height: 5)
                            Text("AI LOCK 60FPS")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .offset(y: -(bh / 2 + 18))
                    }
                    .position(x: bx + bw / 2, y: by + bh / 2)
                    .animation(.spring(response: 0.2, dampingFraction: 0.8), value: faceBox)
                }

                // ERGONOMIC VIEW HUD OVERLAY (98% Clear Viewport)
                VStack(spacing: 0) {
                    // TOP BAR: Logo, Battery, Aspect Ratio & 4K/60 Indicator
                    HStack(spacing: 8) {
                        // Logo & Battery Pill
                        HStack(spacing: 6) {
                            TFlowBrandLogo(size: 18)
                            Text("S1 PRO")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                            Circle()
                                .fill(Color.green)
                                .frame(width: 5, height: 5)
                            Text("\(ble.batteryLevel)%")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())

                        Spacer()

                        // Aspect Ratio Picker Button
                        Button(action: { showAspectPicker.toggle() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "aspectratio")
                                    .font(.system(size: 11, weight: .bold))
                                Text(selectedAspectRatio)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }

                        // 4K60 / ProRes Pill
                        Text("4K • 60")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())

                        // AI Vision Toggle
                        Button(action: { withAnimation { isAiActive.toggle() } }) {
                            Image(systemName: isAiActive ? "viewfinder" : "viewfinder.circle")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(isAiActive ? .white : .white.opacity(0.4))
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    Spacer()

                    // BOTTOM CONTROLS CLUSTER (Ergonomic Thumb Access)
                    VStack(spacing: 14) {
                        // Gimbal Mode Switcher (PF | FPV | LOCK | 360°)
                        HStack(spacing: 4) {
                            ForEach(gimbalModes, id: \.self) { mode in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        ble.gimbalMode = mode
                                    }
                                }) {
                                    Text(mode)
                                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(ble.gimbalMode == mode ? Color.white : Color.clear)
                                        .foregroundColor(ble.gimbalMode == mode ? .black : .white.opacity(0.8))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(3)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())

                        // Camera Mode Carousel
                        HStack(spacing: 16) {
                            ForEach(camModes, id: \.self) { m in
                                Button(action: { selectedCamMode = m }) {
                                    Text(m)
                                        .font(.system(size: 11.5, weight: selectedCamMode == m ? .bold : .medium))
                                        .foregroundColor(selectedCamMode == m ? Color(red: 0.98, green: 0.72, blue: 0.10) : .white.opacity(0.6))
                                }
                            }
                        }

                        // Shutter & Utility Buttons
                        HStack(spacing: 36) {
                            // Left: Gallery Thumbnail
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.15))
                                .overlay(
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .foregroundColor(.white.opacity(0.8))
                                )
                                .frame(width: 44, height: 44)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )

                            // Center: Shutter Button
                            Button(action: {
                                withAnimation(.spring()) {
                                    isRecording.toggle()
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3.5)
                                        .frame(width: 72, height: 72)

                                    if isRecording {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.red)
                                            .frame(width: 28, height: 28)
                                    } else {
                                        Circle()
                                            .fill(selectedCamMode.contains("VIDEO") ? Color.red : Color.white)
                                            .frame(width: 58, height: 58)
                                    }
                                }
                            }

                            // Right: Flip Camera
                            Button(action: {}) {
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                    )
                                    .overlay(
                                        Circle().stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }

                // Aspect Ratio Modal Sheet
                if showAspectPicker {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { showAspectPicker = false }

                    VStack(spacing: 12) {
                        Text("CHỌN TỈ LỆ KHUNG HÌNH ĐIỆN ẢNH")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))

                        HStack(spacing: 10) {
                            ForEach(aspectRatios, id: \.self) { ar in
                                Button(action: {
                                    selectedAspectRatio = ar
                                    showAspectPicker = false
                                }) {
                                    VStack(spacing: 4) {
                                        Text(ar)
                                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 14)
                                    .background(selectedAspectRatio == ar ? Color.white : Color.white.opacity(0.12))
                                    .foregroundColor(selectedAspectRatio == ar ? .black : .white)
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(red: 0.12, green: 0.12, blue: 0.14))
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 1))
                    .padding(24)
                }
            }
        }
    }
}

// Reticle Corner Brackets Shape
struct CinematicReticleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let len: CGFloat = 14

        // Top-Left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + len))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + len, y: rect.minY))

        // Top-Right
        path.move(to: CGPoint(x: rect.maxX - len, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + len))

        // Bottom-Right
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - len))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - len, y: rect.maxY))

        // Bottom-Left
        path.move(to: CGPoint(x: rect.minX + len, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - len))

        return path
    }
}

// Rule of Thirds
struct RuleOfThirdsGridView: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let w = geo.size.width
                let h = geo.size.height
                path.move(to: CGPoint(x: w / 3, y: 0))
                path.addLine(to: CGPoint(x: w / 3, y: h))
                path.move(to: CGPoint(x: 2 * w / 3, y: 0))
                path.addLine(to: CGPoint(x: 2 * w / 3, y: h))

                path.move(to: CGPoint(x: 0, y: h / 3))
                path.addLine(to: CGPoint(x: w, y: h / 3))
                path.move(to: CGPoint(x: 0, y: 2 * h / 3))
                path.addLine(to: CGPoint(x: w, y: 2 * h / 3))
            }
            .stroke(Color.white.opacity(0.12), lineWidth: 0.6)
        }
    }
}

// MARK: - =====================================================================
// 5. SCREEN 02: T-FLOW PRO DEVICE HUB (FIGMA SCREEN 07 SPECS)
// =====================================================================
struct GimbalDeviceHubView: View {
    @EnvironmentObject var ble: BLEGimbalManager
    @State private var isCalibrating: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // HERO HARDWARE CARD
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    TFlowBrandLogo(size: 26)
                                    Text("T-Flow Pro S1")
                                        .font(.system(size: 20, weight: .bold))
                                }
                                Text("Titanium Aerospace Edition • BLE 5.3")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            Spacer()
                            HStack(spacing: 5) {
                                Circle().fill(Color.green).frame(width: 7, height: 7)
                                Text("50Hz FOC Synced")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(Color.green.opacity(0.12))
                            .clipShape(Capsule())
                        }

                        Divider().background(Color.white.opacity(0.1))

                        HStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("PIN 4500mAh").font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.5))
                                Text("\(ble.batteryLevel)%").font(.system(size: 18, weight: .bold, design: .monospaced)).foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("XUNG ĐIỀU KHIỂN").font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.5))
                                Text("20 kHz").font(.system(size: 18, weight: .bold, design: .monospaced)).foregroundColor(.green)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("FIRMWARE").font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.5))
                                Text("v2.4.1").font(.system(size: 18, weight: .bold, design: .monospaced)).foregroundColor(.white)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(red: 0.11, green: 0.11, blue: 0.13))
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.12), lineWidth: 1))

                    // 3-AXIS REALTIME FOC ANGLE GAUGES (Pan, Tilt, Roll)
                    VStack(alignment: .leading, spacing: 14) {
                        Text("GÓC QUAY 3 TRỤC THỜI GIAN THỰC (50Hz IMU)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))

                        HStack(spacing: 12) {
                            AxisAngleCard(axis: "ROLL", angle: String(format: "%.2f°", ble.rollAngle), status: "Chuẩn Cân", color: .green)
                            AxisAngleCard(axis: "TILT", angle: String(format: "%+.1f°", ble.pitchAngle), status: "Góc Chụp", color: Color(red: 0.98, green: 0.72, blue: 0.10))
                            AxisAngleCard(axis: "PAN", angle: String(format: "%.1f°", ble.panAngle), status: "Quay 360°", color: .cyan)
                        }
                    }

                    // CALIBRATION & JOYSTICK TUNING
                    VStack(alignment: .leading, spacing: 16) {
                        Text("HIỆU CHUẨN ĐỘNG CƠ & CẦN ĐIỀU KHIỂN")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))

                        Button(action: {
                            isCalibrating = true
                            ble.autoCalibrateMotors()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                isCalibrating = false
                            }
                        }) {
                            HStack {
                                Image(systemName: isCalibrating ? "arrow.triangle.2.circlepath" : "scope")
                                    .rotationEffect(.degrees(isCalibrating ? 360 : 0))
                                    .animation(isCalibrating ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isCalibrating)
                                Text(isCalibrating ? "Đang Cân Bằng Trọng Tâm Motor..." : "Tự Động Cân Bằng Trọng Tâm (CoG)")
                                    .font(.system(size: 14, weight: .bold))
                                Spacer()
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Độ Nhạy Cần Joystick")
                                    .font(.system(size: 13, weight: .semibold))
                                Spacer()
                                Text(ble.joystickSensitivity > 0.7 ? "Thể Thao" : "Điện Ảnh Mượt")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                            }
                            Slider(value: $ble.joystickSensitivity, in: 0.1...1.0)
                                .tint(Color(red: 0.98, green: 0.72, blue: 0.10))
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(14)
                    }
                }
                .padding(16)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Thiết Bị T-Flow Pro")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct AxisAngleCard: View {
    let axis: String
    let angle: String
    let status: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(axis)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.6))

            Text(angle)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(color)

            Text(status)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(red: 0.11, green: 0.11, blue: 0.13))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}

// MARK: - =====================================================================
// 6. SCREEN 03: T-FLOW BOT COPILOT (MONOCHROME BRANDING)
// =====================================================================
struct TFlowAIChatAssistantView: View {
    @State private var messages: [ChatMessage] = [
        ChatMessage(
            isBot: true,
            text: "Xin chào! Em là T-Flow Bot — trợ lý thông minh đồng bộ Cloud trên ứng dụng T-Flow Cam.\n\nEm sẵn sàng giải đáp kỹ thuật cân trục Pure FOC 20kHz, góc quay Inception 360°, thiết lập Apple Log 4K/60fps và đồng bộ dữ liệu thời gian thực từ Admin CMS."
        )
    ]
    @State private var inputText: String = ""

    let quickPrompts = [
        "Quay Inception 360°",
        "Cài đặt Apple Log 4K/60",
        "Hiệu chuẩn động cơ FOC",
        "Áp bảng màu 3D LUT"
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Quick Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickPrompts, id: \.self) { p in
                            Button(action: { sendUserText(p) }) {
                                Text(p)
                                    .font(.system(size: 12, weight: .semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(Color.white.opacity(0.1))
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(Color(red: 0.08, green: 0.08, blue: 0.10))

                // Chat Stream
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(messages) { msg in
                                HStack(alignment: .top, spacing: 10) {
                                    if msg.isBot {
                                        TFlowBrandLogo(size: 28)
                                    } else {
                                        Spacer()
                                    }

                                    VStack(alignment: msg.isBot ? .leading : .trailing, spacing: 4) {
                                        Text(msg.text)
                                            .font(.system(size: 14, weight: .regular))
                                            .padding(14)
                                            .background(msg.isBot ? Color(red: 0.14, green: 0.14, blue: 0.16) : Color(red: 0.0, green: 0.44, blue: 0.89))
                                            .foregroundColor(.white)
                                            .cornerRadius(16)

                                        Text(msg.isBot ? "T-Flow Bot" : "Bạn")
                                            .font(.system(size: 10))
                                            .foregroundColor(.white.opacity(0.4))
                                    }

                                    if !msg.isBot {
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                            .frame(width: 28, height: 28)
                                            .overlay(Text("U").font(.system(size: 12, weight: .bold)))
                                    } else {
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                }

                // Input Bar
                HStack(spacing: 10) {
                    TextField("Hỏi T-Flow Bot về kỹ thuật quay, FOC...", text: $inputText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(Color(red: 0.14, green: 0.14, blue: 0.16))
                        .cornerRadius(20)
                        .foregroundColor(.white)

                    Button(action: {
                        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !text.isEmpty {
                            sendUserText(text)
                            inputText = ""
                        }
                    }) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 38, height: 38)
                            .background(Color(red: 0.0, green: 0.48, blue: 0.95))
                            .clipShape(Circle())
                    }
                }
                .padding(12)
                .background(Color(red: 0.07, green: 0.07, blue: 0.09))
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("T-Flow Bot")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func sendUserText(_ text: String) {
        messages.append(ChatMessage(isBot: false, text: text))

        // Bot responds with tailored camera knowledge
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let answer: String
            if text.contains("Inception") || text.contains("360") {
                answer = "🔄 **Chế độ Inception 360°:** Động cơ Roll sẽ xoay vô hạn 360 độ theo thời gian thực. Bấm phím trigger 3 lần trên báng tay cầm để kích hoạt ngay lập tức!"
            } else if text.contains("Log") || text.contains("Apple") {
                answer = "🎬 **Cài đặt Apple Log:** Đã kích hoạt không gian màu Log Rec.709 trên iPhone 15/16 Pro. Tốc độ ghi 220Mbps ProRes 4K/60fps sẵn sàng ghi thẳng vào ổ SSD Type-C."
            } else if text.contains("FOC") || text.contains("động cơ") {
                answer = "⚡ **Thuật toán Pure FOC 20kHz:** Bộ vi điều khiển 32-bit tính toán vector dòng điện 20.000 lần mỗi giây, triệt tiêu vi rung giật hoàn toàn không tiếng ồn."
            } else {
                answer = "Dạ, em đã ghi nhận câu hỏi của anh: \"\(text)\". Em đang liên kết với bộ não tri thức T-Flow Cloud để phản hồi anh chi tiết nhất ạ!"
            }
            messages.append(ChatMessage(isBot: true, text: answer))
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let isBot: Bool
    let text: String
}

// MARK: - =====================================================================
// 7. SCREEN 04: PROFILE & 7-MODULE INSET GROUPED (FIGMA SCREEN 09 SPECS)
// =====================================================================
struct UserProfilePermissionsView: View {
    @EnvironmentObject var store: SupabaseModuleStore

    let moduleTitles = [
        ("AI Vision Optical Tracking", "camera.metering.spot", "Đã Mở Khóa"),
        ("Apple Log & ProRes 4K/60fps", "film.stack", "Đã Mở Khóa"),
        ("Motionlapse Waypoint 5-Point", "point.topleft.down.curvedto.point.bottomright.up", "Đã Mở Khóa"),
        ("Multi-Cam Director Studio", "rectangle.split.2x2", "Đã Mở Khóa"),
        ("3D LUT Real-time Preview", "slider.horizontal.3", "Đã Mở Khóa"),
        ("FOC Motor Micro-Tuning", "waveform.path.ecg", "Đã Mở Khóa"),
        ("500Hz Gyro Raw Telemetry", "location.north.circle", "Đã Mở Khóa")
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // TITANIUM VIP MEMBERSHIP CARD (Brushed Titanium Gradient)
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top) {
                            HStack(spacing: 10) {
                                TFlowBrandLogo(size: 32)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(store.userName)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                    Text(store.userTier)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                                }
                            }
                            Spacer()
                            Text("VIP LIFETIME")
                                .font(.system(size: 10, weight: .black))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.15))
                                .foregroundColor(.white)
                                .cornerRadius(6)
                        }

                        Divider().background(Color.white.opacity(0.12))

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("THIẾT BỊ ĐĂNG KÝ").font(.system(size: 9.5, weight: .bold)).foregroundColor(.white.opacity(0.5))
                                Text(store.deviceName).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                            }
                            Spacer()
                            HStack(spacing: 5) {
                                Circle().fill(store.isOnline ? Color.green : Color.red).frame(width: 6, height: 6)
                                Text(store.isOnline ? "Supabase Live" : "Offline")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(store.isOnline ? .green : .red)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.15, green: 0.15, blue: 0.18), Color(red: 0.08, green: 0.08, blue: 0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.16), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.5), radius: 10, y: 4)

                    // 7-MODULE INSET GROUPED LIST
                    VStack(alignment: .leading, spacing: 10) {
                        Text("TRẠNG THÁI 7 MODULE ĐỒNG BỘ TỪ WEB ADMIN CMS")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 4)

                        VStack(spacing: 0) {
                            ForEach(0..<moduleTitles.count, id: \.self) { idx in
                                let item = moduleTitles[idx]
                                let isEnabled = store.modules.indices.contains(idx) ? store.modules[idx] : true

                                HStack(spacing: 12) {
                                    Image(systemName: item.1)
                                        .font(.system(size: 15))
                                        .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 1) {
                                        Text("\(idx + 1). \(item.0)")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.white)
                                    }

                                    Spacer()

                                    Text(isEnabled ? "ĐÃ MỞ KHÓA" : "ĐÃ KHÓA")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(isEnabled ? .green : .red)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background((isEnabled ? Color.green : Color.red).opacity(0.12))
                                        .clipShape(Capsule())
                                }
                                .padding(.vertical, 13)
                                .padding(.horizontal, 16)

                                if idx < moduleTitles.count - 1 {
                                    Divider()
                                        .background(Color.white.opacity(0.08))
                                        .padding(.leading, 52)
                                }
                            }
                        }
                        .background(Color(red: 0.11, green: 0.11, blue: 0.13))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }

                    // SYSTEM INFO & LOGOUT
                    VStack(spacing: 12) {
                        HStack {
                            Text("Phiên bản ứng dụng")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Text("v2.4.1 (Build 241 Pro)")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(14)
                        .background(Color(red: 0.11, green: 0.11, blue: 0.13))
                        .cornerRadius(12)
                    }
                }
                .padding(16)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Hồ Sơ & Phân Quyền")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - =====================================================================
// 8. AVFOUNDATION LIVE CAMERA CAPTURE PREVIEW CONTROLLER
// =====================================================================
struct NativeCameraPreviewRepresentable: UIViewControllerRepresentable {
    var onFaceDetected: (CGRect?) -> Void

    func makeUIViewController(context: Context) -> CameraViewController {
        let vc = CameraViewController()
        vc.onFaceDetected = onFaceDetected
        return vc
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

final class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onFaceDetected: ((CGRect?) -> Void)?
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func setupCamera() {
        captureSession.beginConfiguration()
        if captureSession.canSetSessionPreset(.hd4K3840x2160) {
            captureSession.sessionPreset = .hd4K3840x2160
        } else if captureSession.canSetSessionPreset(.hd1920x1080) {
            captureSession.sessionPreset = .hd1920x1080
        } else {
            captureSession.sessionPreset = .high
        }

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoInput) else {
            captureSession.commitConfiguration()
            return
        }
        captureSession.addInput(videoInput)

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frame.processing"))
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        captureSession.commitConfiguration()

        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        self.previewLayer = layer

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceRectanglesRequest { [weak self] req, err in
            guard let results = req.results as? [VNFaceObservation], let firstFace = results.first else {
                DispatchQueue.main.async { self?.onFaceDetected?(nil) }
                return
            }

            let box = firstFace.boundingBox
            let normalized = CGRect(
                x: 1.0 - box.maxX,
                y: 1.0 - box.maxY,
                width: box.width,
                height: box.height
            )

            DispatchQueue.main.async {
                self?.onFaceDetected?(normalized)
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        try? handler.perform([request])
    }
}
