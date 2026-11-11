//
//  TFlowAIChatAssistantView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//

import SwiftUI
import UIKit

// MARK: - =====================================================================
// 16. TAB 3: T-FLOW BOT CHAT VIEW (AI COPILOT)
// =====================================================================

struct TFlowAIChatAssistantView: View {
    @State private var messages: [ChatMessage] = [
        ChatMessage(
            isUser: false,
            text: "Chào anh Thủy! Em là T-Flow Bot — Trợ lý AI đồng hành cùng Smart Gimbal S1 Titanium. Em có thể hướng dẫn anh các kỹ thuật quay điện ảnh, bật Apple Log 4K/60, hiệu chuẩn động cơ FOC hoặc đồng bộ dữ liệu với Web Admin!"
        )
    ]
    @State private var inputText: String = ""

    let quickChips = [
        "Quay Inception 360°",
        "Cài đặt Apple Log 4K/60",
        "Cân bằng trọng tâm CoG",
        "Báo giá 4 cấu hình Pro",
        "Ngàm MagSafe 45N N52"
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Quick Chips Row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickChips, id: \.self) { chip in
                            Button(action: {
                                sendMessage(chip)
                            }) {
                                Text(chip)
                                    .font(.system(size: 12, weight: .semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(Color.white.opacity(0.08))
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(Color(red: 0.07, green: 0.07, blue: 0.09))

                // Chat Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(messages) { msg in
                                HStack(alignment: .top, spacing: 10) {
                                    if msg.isUser {
                                        Spacer()
                                        Text(msg.text)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(Color(red: 0.0, green: 0.48, blue: 1.0))
                                            .clipShape(RoundedRectangle(cornerRadius: 18))
                                            .frame(maxWidth: 280, alignment: .trailing)
                                    } else {
                                        TFlowBrandLogo(size: 26)
                                        Text(msg.text)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(Color.white.opacity(0.08))
                                            .clipShape(RoundedRectangle(cornerRadius: 18))
                                            .frame(maxWidth: 290, alignment: .leading)
                                        Spacer()
                                    }
                                }
                                .id(msg.id)
                            }
                        }
                        .padding(16)
                    }
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider().background(Color.white.opacity(0.1))

                // Input Bar
                HStack(spacing: 10) {
                    TextField("Hỏi T-Flow Bot về kỹ thuật quay, FOC...", text: $inputText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(20)
                        .foregroundColor(.white)

                    Button(action: {
                        if !inputText.trimmingCharacters(in: .whitespaces).isEmpty {
                            sendMessage(inputText)
                            inputText = ""
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(red: 0.07, green: 0.07, blue: 0.09))
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("T-Flow Bot")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func sendMessage(_ text: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        messages.append(ChatMessage(isUser: true, text: text))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let reply: String
            let lower = text.lowerBound(target: text.lowercased())
            if text.contains("Inception") || text.contains("360") {
                reply = """
🎬 Để quay cú máy Inception 360°:
1. Tại Tab Camera, chọn chế độ '360°' trên thanh Gimbal.
2. Cầm gimbal nằm ngang hướng thẳng vào chủ thể.
3. Gạt cần Joystick ảo sang trái hoặc phải để trục Roll xoay tròn 360° liên tục không điểm dừng!
"""
            } else if text.contains("Apple Log") || text.contains("4K/60") {
                reply = """
🎥 Cài đặt Apple Log 4K/60fps:
1. Bật nút 'PRO' trên thanh HUD đỉnh máy ảnh.
2. Chọn không gian màu 'Apple Log (Flat)'.
3. ISO cố định ở mức 100, góc mở màn trập 180° (1/120s) để đạt dải nhạy sáng dynamic range 14+ stops tối đa!
"""
            } else if text.contains("CoG") || text.contains("Cân bằng") {
                reply = """
⚖️ Tự động cân bằng CoG:
1. Chuyển sang Tab 'T-Flow Pro'.
2. Nhấn nút 'Tự Động Cân Bằng Trọng Tâm (CoG)'.
3. Đặt gimbal đứng yên trong 2 giây để thuật toán FOC quét và triệt tiêu rung sai số ±0.01°.
"""
            } else if text.contains("Báo giá") || text.contains("gói") {
                reply = """
📦 Bảng giá 4 gói T-Flow Pro:
• Gói 1: Gimbal Cầm Tay S1 (B2C) — 3.990.000₫
• Gói 2: Cụm Camera AI & Đèn MagSafe — 1.490.000₫
• Gói 3: Bo Mạch STM32 Pure FOC 20kHz — 890.000₫
• Gói 4: Cảm Biến IMU 6 Trục & Encoder 14-bit — 450.000₫
"""
            } else {
                reply = "Dạ em đã ghi nhận yêu cầu của anh. Gimbal S1 Pro của anh đang hoạt động ở trạng thái hoàn hảo với tần số FOC 20kHz và pin 94%!"
            }
            messages.append(ChatMessage(isUser: false, text: reply))
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

extension String {
    func lowerBound(target: String) -> String { self.lowercased() }
}
