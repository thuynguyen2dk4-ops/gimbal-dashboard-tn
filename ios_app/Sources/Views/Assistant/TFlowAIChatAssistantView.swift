//
//  TFlowAIChatAssistantView.swift
//  SmartGimbalPro
//
//  T-Flow AI Copilot — Chat thời gian thực qua Vercel API (fallback offline thông minh)
//  và điều khiển trực tiếp Gimbal / Camera (Khóa vật thể, 0.5x nhóm, 360° Inception, Pro Mode).
//

import SwiftUI
import UIKit

struct TFlowAIChatAssistantView: View {
    @EnvironmentObject var ble: BLEGimbalManager
    @EnvironmentObject var camera: CameraService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let chatEndpoint = "https://t-flow-tech.vercel.app/api/chat"
    private let accentYellow = Color(red: 1.0, green: 0.84, blue: 0.04) // #FFD60A

    @State private var inputText: String = ""
    @State private var isLoadingReply: Bool = false
    @State private var messages: [ChatMessage] = [
        ChatMessage(
            isUser: false,
            text: "Xin chào! Tôi là T-Flow AI Copilot cho Smart Gimbal Pro S1. Bạn có thể hỏi thông số kỹ thuật hoặc ra lệnh trực tiếp như: \"Khóa vật thể\", \"Chụp nhóm 0.5x\", \"Xoay 360° Inception\" hoặc \"Bật chế độ Chuyên nghiệp\"."
        )
    ]

    private let quickChips: [String] = [
        "Khóa vật thể",
        "Chụp nhóm 0.5x",
        "Xoay 360° Inception",
        "Bật chế độ Chuyên nghiệp",
        "Lực hút MagSafe N52",
        "Cân bằng CoG 20kHz"
    ]

    private var surfaceBackground: Color {
        colorScheme == .light ? Color(red: 0.96, green: 0.96, blue: 0.98) : Color(red: 0.04, green: 0.04, blue: 0.06)
    }

    private var cardBackground: Color {
        colorScheme == .light ? Color.white : Color.white.opacity(0.08)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                liveTelemetryStrip
                Divider()

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { msg in
                                messageBubble(msg)
                                    .id(msg.id)
                            }

                            if isLoadingReply {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(0.85)
                                        .tint(accentYellow)
                                    Text("T-Flow AI đang phản hồi...")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .id("typing-indicator")
                            }
                        }
                        .padding(16)
                    }
                    .background(surfaceBackground)
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()
                quickChipsBar
                composerBar
            }
            .navigationTitle("T-Flow AI Copilot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        messages = [
                            ChatMessage(
                                isUser: false,
                                text: "Đã làm mới phiên trò chuyện. Sẵn sàng nhận lệnh cho Smart Gimbal Pro S1."
                            )
                        ]
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.secondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(accentYellow)
                }
            }
        }
    }

    private var liveTelemetryStrip: some View {
        HStack(spacing: 10) {
            Label("\(ble.gimbalMode)", systemImage: "cpu")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(accentYellow)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(accentYellow.opacity(0.14)))

            Text(camera.isProMode ? "Pro Camera" : "Cơ bản")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(cardBackground))

            if camera.autoGroupFraming05x {
                Text("0.5x Nhóm")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.cyan.opacity(0.14)))
            }

            Spacer()

            Text("Pin \(ble.batteryLevel)%")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(cardBackground)
    }

    private func messageBubble(_ msg: ChatMessage) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if msg.isUser { Spacer(minLength: 42) }

            if !msg.isUser {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(accentYellow))
            }

            Text(msg.text)
                .font(.system(size: 14))
                .foregroundColor(msg.isUser ? .black : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(msg.isUser ? accentYellow : cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            msg.isUser ? Color.clear : Color.primary.opacity(0.08),
                            lineWidth: 1
                        )
                )

            if !msg.isUser { Spacer(minLength: 36) }
        }
    }

    private var quickChipsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickChips, id: \.self) { chip in
                    Button {
                        send(chip)
                    } label: {
                        Text(chip)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(cardBackground))
                            .overlay(
                                Capsule().stroke(Color.primary.opacity(0.10), lineWidth: 1)
                            )
                    }
                    .disabled(isLoadingReply)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .background(surfaceBackground)
    }

    private var composerBar: some View {
        HStack(spacing: 10) {
            TextField("Hỏi hoặc ra lệnh cho Gimbal...", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(cardBackground))
                .onSubmit {
                    send(inputText)
                }

            Button {
                send(inputText)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(
                        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoadingReply
                            ? .secondary.opacity(0.45)
                            : accentYellow
                    )
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoadingReply)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(surfaceBackground)
    }

    private func send(_ rawText: String) {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isLoadingReply else { return }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        messages.append(ChatMessage(isUser: true, text: trimmed))
        inputText = ""

        // Thực thi tức thì lệnh phần cứng/camera nếu câu lệnh khớp ý định điều khiển
        let hardwareFeedback = executeLiveCommandIfMatched(for: trimmed)

        isLoadingReply = true
        Task {
            let replyText = await fetchRemoteOrFallbackReply(for: trimmed, hardwareFeedback: hardwareFeedback)
            await MainActor.run {
                messages.append(ChatMessage(isUser: false, text: replyText))
                isLoadingReply = false
            }
        }
    }

    private func executeLiveCommandIfMatched(for text: String) -> String? {
        let lower = text.lowercased()
        var actions: [String] = []

        if lower.contains("khóa vật thể") || lower.contains("khoá vật thể") || lower.contains("lock") {
            camera.lockObjectAtNormalizedPoint(CGPoint(x: 0.5, y: 0.5), label: "Mục tiêu AI")
            actions.append("Đã kích hoạt Khóa vật thể AI tại tâm khung hình.")
        }

        if lower.contains("0.5") || lower.contains("nhóm") || lower.contains("góc rộng") {
            camera.setAutoGroupFraming(true)
            actions.append("Đã chuyển sang ống kính góc rộng 0.5x Auto-Framing cho chụp/quay nhóm.")
        }

        if lower.contains("inception") || lower.contains("360") {
            ble.setGimbalModeWithHaptic("360°")
            actions.append("Đã chuyển Gimbal sang chế độ xoay 360° Inception Barrel Roll.")
        }

        if lower.contains("chuyên nghiệp") || lower.contains("chế độ pro") || lower == "pro" {
            camera.setCameraInterfaceMode(pro: true)
            actions.append("Đã bật giao diện Camera Chuyên nghiệp (Pro Mode).")
        }

        return actions.isEmpty ? nil : actions.joined(separator: " ")
    }

    private func fetchRemoteOrFallbackReply(for text: String, hardwareFeedback: String?) async -> String {
        guard let url = URL(string: chatEndpoint) else {
            return combineReply(hardwareFeedback: hardwareFeedback, baseReply: generateReply(for: text))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 8.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let payload: [String: Any] = [
            "message": text,
            "messages": [["role": "user", "content": text]],
            "context": [
                "device": "Smart Gimbal Pro S1",
                "gimbalMode": ble.gimbalMode,
                "batteryLevel": ble.batteryLevel,
                "isProMode": camera.isProMode,
                "resolution": camera.selectedResolution
            ]
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: payload) else {
            return combineReply(hardwareFeedback: hardwareFeedback, baseReply: generateReply(for: text))
        }
        request.httpBody = bodyData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
               let remoteText = extractReplyText(from: data), !remoteText.isEmpty {
                return combineReply(hardwareFeedback: hardwareFeedback, baseReply: remoteText)
            }
        } catch {
            // Mất mạng hoặc timeout -> dùng phản hồi ngoại tuyến bên dưới
        }

        return combineReply(hardwareFeedback: hardwareFeedback, baseReply: generateReply(for: text))
    }

    private func extractReplyText(from data: Data) -> String? {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            for key in ["reply", "answer", "response", "text", "message", "content"] {
                if let val = json[key] as? String {
                    let trimmed = val.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty { return trimmed }
                }
            }
            if let choices = json["choices"] as? [[String: Any]],
               let first = choices.first,
               let msg = first["message"] as? [String: Any],
               let content = msg["content"] as? String {
                let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { return trimmed }
            }
        }
        if let raw = String(data: data, encoding: .utf8) {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !trimmed.hasPrefix("<") {
                return trimmed
            }
        }
        return nil
    }

    private func combineReply(hardwareFeedback: String?, baseReply: String) -> String {
        guard let feedback = hardwareFeedback else { return baseReply }
        return "[Đã thực thi] \(feedback)\n\n\(baseReply)"
    }

    func generateReply(for text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("khóa vật thể") || lower.contains("khoá vật thể") || lower.contains("lock") {
            return "Chế độ khóa vật thể AI đã được kích hoạt tại tâm khung hình (độ trễ bám nét ~14ms). Bạn có thể chạm trực tiếp lên màn hình Quay để đổi điểm khóa bất kỳ."
        } else if lower.contains("0.5") || lower.contains("nhóm") || lower.contains("góc rộng") {
            return "Ống kính góc rộng 0.5x + Auto-Framing đã bật, tự động mở rộng khung hình khi phát hiện từ 2 người trở lên."
        } else if lower.contains("chuyên nghiệp") || lower.contains("chế độ pro") || lower == "pro" {
            return "Giao diện Chuyên nghiệp (Pro Mode) đã mở khóa ISO, Shutter Speed 1/120s, Histogram RGB, Audio VU và tùy chỉnh 5 Widget trên màn hình quay."
        } else if lower.contains("n52") || lower.contains("magsafe") || lower.contains("rơi") {
            return "Ngàm MagSafe 45N N52 giữ lực hút vượt 4.5kg trên iPhone 16 Pro Max. Hãy gắn trực tiếp vào vòng MagSafe trần hoặc ốp chuẩn MagSafe trước khi bật nguồn động cơ."
        } else if lower.contains("cog") || lower.contains("cân") || lower.contains("rung") {
            return "Nếu điện thoại lệch tâm, hãy vào tab Thiết bị -> Hiệu chỉnh 6 mặt cảm biến hoặc Tự động cân bằng động cơ FOC 20kHz để đưa Roll/Pitch về ±0.01°."
        } else if lower.contains("inception") || lower.contains("360") {
            return "Chế độ 360° Inception Barrel Roll đã sẵn sàng trên Smart Gimbal S1. Xoay cần Joystick trái/phải để tạo cú xoay vô cực điện ảnh."
        } else if lower.contains("prores") || lower.contains("log") {
            return "Camera Studio hỗ trợ 4K 60fps & LUT Rec.709 / Cinematic / Teal-Orange để tối ưu dải tương phản động khi hậu kỳ."
        } else if lower.contains("giá") || lower.contains("gói") {
            return "Smart Gimbal Pro S1 bản tiêu chuẩn có giá niêm yết 2.890.000đ, tặng kèm gói VIP AI Tracking trọn đời."
        }
        return "T-Flow AI đang theo dõi trạng thái thiết bị (Pin \(ble.batteryLevel)%, Mode \(ble.gimbalMode)). Bạn có thể yêu cầu \"Khóa vật thể\", \"Chụp nhóm 0.5x\", \"Xoay 360° Inception\" hoặc \"Bật chế độ Chuyên nghiệp\"."
    }
}
