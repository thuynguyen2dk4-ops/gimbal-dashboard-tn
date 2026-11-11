//
//  MediaGallerySheetView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//

import SwiftUI
import UIKit

// MARK: - =====================================================================
// 13. MEDIA GALLERY SHEET VIEW (SCREEN 27 & 28)
// =====================================================================

struct MediaGallerySheetView: View {
    @ObservedObject var camera: CameraService
    @Environment(\.dismiss) var dismiss
    @State private var selectedItem: CapturedMediaItem? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(camera.capturedMedia) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            ZStack(alignment: .bottomTrailing) {
                                Image(uiImage: item.image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 140)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                if item.isVideo, let dur = item.duration {
                                    HStack(spacing: 3) {
                                        Image(systemName: "play.fill").font(.system(size: 9))
                                        Text(dur).font(.system(size: 10, weight: .bold, design: .monospaced))
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.black.opacity(0.75))
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                                    .padding(6)
                                }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.resolution)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                Text(item.profile)
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                            }
                        }
                        .onTapGesture {
                            selectedItem = item
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Thư Viện Media S1 Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") { dismiss() }
                        .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                }
            }
            .sheet(item: $selectedItem) { item in
                MediaDetailPreviewSheet(
                    item: item,
                    onDelete: {
                        camera.capturedMedia.removeAll { $0.id == item.id }
                        camera.latestThumbnail = camera.capturedMedia.first?.image
                        selectedItem = nil
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                )
            }
        }
    }
}

struct MediaDetailPreviewSheet: View {
    let item: CapturedMediaItem
    let onDelete: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var showShareSheet: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 18) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: item.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 380)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1))

                    HStack(spacing: 5) {
                        Image(systemName: item.isVideo ? "video.fill" : "camera.fill")
                            .font(.system(size: 10))
                        Text(item.isVideo ? (item.duration ?? "VIDEO") : "PHOTO")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.75))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .padding(12)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Độ phân giải:")
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Text(item.resolution)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    HStack {
                        Text("Hồ sơ màu / LUT:")
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Text(item.profile)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                    }
                    HStack {
                        Text("Thời gian:")
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Text(DateFormatter.localizedString(from: item.timestamp, dateStyle: .short, timeStyle: .medium))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
                .font(.system(size: 13))
                .padding(16)
                .background(Color.white.opacity(0.06))
                .cornerRadius(14)

                Spacer()

                HStack(spacing: 12) {
                    Button(action: { showShareSheet = true }) {
                        Label("Chia Sẻ", systemImage: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color.white.opacity(0.14))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    Button(role: .destructive, action: onDelete) {
                        Label("Xóa Media", systemImage: "trash")
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color.red.opacity(0.22))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(20)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle(item.isVideo ? "Chi Tiết Video Clip" : "Chi Tiết Ảnh Chụp")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") { dismiss() }
                        .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ActivityShareSheet(items: [item.image])
            }
        }
    }
}

private struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
