//
//  TFlowAIChatAssistantView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//

import SwiftUI

struct TFlowAIChatAssistantView: View {
    @EnvironmentObject var ble: BLEGimbalManager
    @EnvironmentObject var camera: CameraService

    @State private var messages: [ChatMessage] = [
        ChatMessage(
            isUser: false,
            text: "Xin chào! T-Flow AI sẵn sàng hỗ trợ quay, cân bằng CoG và setup gimbal."
        )
    ]
    @State private var inputText: String = ""

    private let quickChips = [
        "Quay Inception 360°",
        "Cài đặt Apple Log 4K/60",
        "Cân bằng trọng tâm CoG",
        "Báo giá 4 cấu hình Pro",
        "Ngàm MagSafe 45N N52"
    ]

    private let goldAccent = Color(red: 0.98, green: 0.72, blue: 0.10)
    private let appleBlue = Color(red: 0.23, green: 0.51, blue: 0.96)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { msg in
                                HStack {
                                    if msg.isUser { Spacer(minLength: 48) }
                                    Text(msg.text)
                                        .font(.system(size: 13))
                                        .foregroundColor(msg.isUser ? .white : .primary)
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(msg.isUser ? appleBlue : Color(UIColor.secondarySystemGroupedBackground))
                                        )
                                    if !msg.isUser { Spacer(minLength: 48) }
                                }
                                .id(msg.id)
                            }
                        }
                        .padding(16)
                    }
                    .onChange(of: messages.count) { _ in
                        if let lastId = messages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }

                // Quick Prompt Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickChips, id: \.self) { chip in
                            Button {
                                sendMessage(chip)
                            } label: {
                                Text(chip)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(Capsule().fill(Color(UIColor.secondarySystemGroupedBackground)))
                                    .overlay(Capsule().stroke(goldAccent.opacity(0.45), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                }

                // Input Row
                HStack(spacing: 10) {
                    TextField("Hỏi T-Flow AI...", text: $inputText)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color(UIColor.secondarySystemGroupedBackground)))

                    Button {
                        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        inputText = ""
                        sendMessage(trimmed)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(appleBlue)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(UIColor.systemBackground))
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Trợ Lý T-Flow AI")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func sendMessage(_ text: String) {
        messages.append(ChatMessage(isUser: true, text: text))
        let reply = generateReply(for: text)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            messages.append(ChatMessage(isUser: false, text: reply))
        }
    }

    private func generateReply(for text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("inception") || lower.contains("360") {
            return "• Chế độ: 360° Spin • 4K 60fps\n• Khuyên dùng: Bật Pro HUD + Zoom 1x\n• Di chuyển chậm giữ trục thẳng."
        } else if lower.contains("apple log") || lower.contains("4k/60") || lower.contains("prores") {
            return "• Định dạng: 4K 60fps • Shutter 1/120s\n• Màu: Apple Log + LUT Rec.709\n• Bật Zebra 95% kiểm tra vùng sáng."
        } else if lower.contains("cog") || lower.contains("cân bằng") || lower.contains("trọng tâm") {
            return "• Gắn máy vào tâm ngàm trước khi bật\n• Vào Gimbal Hub -> Cân bằng CoG\n• Giữ máy đứng yên 3 giây."
        } else if lower.contains("magsafe") || lower.contains("45n") || lower.contains("n52") || lower.contains("ngàm") || lower.contains("nam châm") {
            return "• Lực hút N52 45N tải tối đa 320g\n• Khớp vòng tròn thép sau ốp mỏng\n• Siết an toàn khi chạy tốc độ cao."
        } else if lower.contains("báo giá") || lower.contains("gói") || lower.contains("giá") || lower.contains("cấu hình") {
            return "• Free Starter: 0₫ (1080p • Basic)\n• Creator Pro: 299.000₫/tháng (4K • AI)\n• VIP Lifetime: Mở khóa 7 module."
        } else {
            return "• Kết nối BLE: \(ble.isConnected ? "Đã ghép đôi" : "Chưa kết nối")\n• Chế độ hiện tại: \(camera.isProMode ? "Chuyên Nghiệp" : "Cơ Bản") • \(camera.selectedAspectRatio)"
        }
    }
}
