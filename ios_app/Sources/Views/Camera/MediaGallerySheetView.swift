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
        }
    }
}
