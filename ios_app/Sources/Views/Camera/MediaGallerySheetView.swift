//
//  MediaGallerySheetView.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//  Lưới thư viện Media (10_Media_Gallery_Grid) & Trình phát Cinema 16:9 (11_Cinema_Video_Player).
//

import SwiftUI
import UIKit

struct MediaGallerySheetView: View {
    @ObservedObject var camera: CameraService
    @Environment(\.dismiss) var dismiss
    @State private var selectedFilter: String = "Tất cả"
    @State private var selectedItem: CapturedMediaItem? = nil

    private let filters = ["Tất cả", "Video", "Ảnh", "Apple Log"]
    private let goldAccent = Color(red: 0.98, green: 0.72, blue: 0.10)
    private let appleBlue = Color(red: 0.23, green: 0.51, blue: 0.96)

    private var filteredMedia: [CapturedMediaItem] {
        switch selectedFilter {
        case "Video":
            return camera.capturedMedia.filter { $0.isVideo }
        case "Ảnh":
            return camera.capturedMedia.filter { !$0.isVideo }
        case "Apple Log":
            return camera.capturedMedia.filter { $0.profile.localizedCaseInsensitiveContains("Log") }
        default:
            return camera.capturedMedia
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Visual Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filters, id: \.self) { filter in
                            let isActive = selectedFilter == filter
                            Button {
                                selectedFilter = filter
                            } label: {
                                Text(filter)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(isActive ? .white : .primary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(
                                        Capsule().fill(isActive ? appleBlue : Color(UIColor.secondarySystemGroupedBackground))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 8)

                if filteredMedia.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "film.stack")
                            .font(.system(size: 42))
                            .foregroundColor(goldAccent)
                        Text("Chưa có Media")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Nhấn nút quay hoặc chụp để lưu khoảnh khắc")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(24)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            ForEach(filteredMedia) { item in
                                Button {
                                    selectedItem = item
                                } label: {
                                    galleryGridCard(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Thư Viện Media (\(filteredMedia.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .sheet(item: $selectedItem) { item in
                MediaDetailPreviewSheet(item: item) {
                    camera.deleteMedia(item)
                    selectedItem = nil
                }
            }
        }
    }

    private func galleryGridCard(item: CapturedMediaItem) -> some View {
        ZStack(alignment: .bottomLeading) {
            Image(uiImage: item.image)
                .resizable()
                .scaledToFill()
                .frame(height: 168)
                .frame(maxWidth: .infinity)
                .clipped()

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )

            // Top-right Resolution Badge
            VStack {
                HStack {
                    if item.profile.localizedCaseInsensitiveContains("Log") {
                        Text("LOG")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.black)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(goldAccent)
                            .cornerRadius(4)
                    }
                    Spacer()
                    Text(item.resolution)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.65))
                        .cornerRadius(5)
                }
                Spacer()
            }
            .padding(8)

            // Bottom-left Video/Photo Badge
            HStack(spacing: 5) {
                Image(systemName: item.isVideo ? "play.circle.fill" : "camera.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(item.isVideo ? goldAccent : .white)
                Text(item.isVideo ? (item.duration ?? "00:12") : "PHOTO")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(9)
        }
        .frame(height: 168)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

struct MediaDetailPreviewSheet: View {
    let item: CapturedMediaItem
    let onDelete: () -> Void
    @Environment(\.dismiss) var dismiss

    @State private var isPlaying: Bool = false
    @State private var playbackProgress: Double = 0.28
    @State private var rec709PreviewEnabled: Bool = true
    @State private var showShareSheet: Bool = false

    private let goldAccent = Color(red: 0.98, green: 0.72, blue: 0.10)
    private let appleBlue = Color(red: 0.23, green: 0.51, blue: 0.96)

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                // 16:9 Cinema Player Frame
                ZStack {
                    Color.black

                    Image(uiImage: item.image)
                        .resizable()
                        .scaledToFit()
                        .saturation(rec709PreviewEnabled ? 1.15 : 0.72)
                        .contrast(rec709PreviewEnabled ? 1.08 : 0.92)

                    if item.isVideo {
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isPlaying.toggle()
                            }
                        } label: {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 54))
                                .foregroundColor(.white.opacity(0.92))
                                .shadow(color: .black.opacity(0.5), radius: 8)
                        }
                    }

                    VStack {
                        HStack {
                            Text(item.resolution)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.65))
                                .cornerRadius(6)
                            Spacer()
                            Button {
                                rec709PreviewEnabled.toggle()
                            } label: {
                                Text(rec709PreviewEnabled ? "LUT: Rec.709" : "Flat Log")
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                                    .foregroundColor(rec709PreviewEnabled ? .black : .white)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 4)
                                    .background(rec709PreviewEnabled ? goldAccent : Color.black.opacity(0.65))
                                    .cornerRadius(6)
                            }
                        }
                        Spacer()
                    }
                    .padding(12)
                }
                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                .cornerRadius(16)
                .padding(.horizontal, 16)
                .padding(.top, 10)

                // Cinema Timeline Scrubber
                VStack(spacing: 6) {
                    Slider(value: $playbackProgress, in: 0.0...1.0)
                        .tint(goldAccent)
                    HStack {
                        Text(item.isVideo ? "00:04" : "RAW/HEIF")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(item.isVideo ? (item.duration ?? "00:15") : item.profile)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                // Export 4K & Delete Actions
                HStack(spacing: 12) {
                    Button {
                        showShareSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Xuất File 4K")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(appleBlue)
                        .cornerRadius(13)
                    }

                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash.fill")
                            Text("Xóa")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 13)
                        .background(Color.red)
                        .cornerRadius(13)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Cinema Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
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
