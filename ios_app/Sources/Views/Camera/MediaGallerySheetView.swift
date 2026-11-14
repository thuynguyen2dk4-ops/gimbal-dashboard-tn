//
//  MediaGallerySheetView.swift
//  SmartGimbalPro
//
//  Figma Node 96:3 — 27_gallery (3-column Photos grid), 28_player (ProRes Viewer), 29_editor (Clip Editor).
//

import SwiftUI
import AVFoundation
import AVKit
import UIKit

struct MediaGallerySheetView: View {
    @ObservedObject var camera: CameraService
    var isEmbeddedTab: Bool = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedFilter: String = "Tất cả"
    @State private var selectedItem: CapturedMediaItem? = nil
    @State private var isSelecting: Bool = false
    @State private var selectedIds: Set<UUID> = []
    @State private var batchShareItems: [Any] = []
    @State private var showBatchShareSheet: Bool = false

    private let filters = ["Tất cả", "Video", "Ảnh"]
    private let accentYellow = Color(red: 1.0, green: 0.84, blue: 0.04) // #FFD60A

    private let gridColumns = [
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3)
    ]

    private var filteredMedia: [CapturedMediaItem] {
        switch selectedFilter {
        case "Video":
            return camera.capturedMedia.filter { $0.isVideo }
        case "Ảnh":
            return camera.capturedMedia.filter { !$0.isVideo }
        default:
            return camera.capturedMedia
        }
    }

    private var surfaceBackground: Color {
        colorScheme == .light ? Color(red: 0.96, green: 0.96, blue: 0.98) : Color.black
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Bộ lọc", selection: $selectedFilter) {
                    ForEach(filters, id: \.self) { f in
                        Text(f).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                if filteredMedia.isEmpty {
                    emptyStateView
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: gridColumns, spacing: 3) {
                            ForEach(filteredMedia) { item in
                                mediaGridCell(item)
                            }
                        }

                        Text("\(camera.realPhotoCount) Ảnh • \(camera.realVideoCount) Video • \(camera.totalLibraryStorageBytesFormatted)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 18)
                    }
                }

                if isSelecting {
                    batchSelectionBar
                }
            }
            .background(surfaceBackground.ignoresSafeArea())
            .navigationTitle("Thư viện")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isEmbeddedTab {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Đóng") {
                            dismiss()
                        }
                        .foregroundColor(accentYellow)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isSelecting ? "Xong" : "Chọn") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        isSelecting.toggle()
                        if !isSelecting {
                            selectedIds.removeAll()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(accentYellow)
                }
            }
            .sheet(item: $selectedItem) { item in
                MediaDetailPreviewSheet(
                    item: item,
                    onSaveEditedCopy: { edited in
                        camera.addAndPersistMedia(edited)
                    },
                    onDelete: {
                        camera.deleteMedia(item)
                    }
                )
            }
            .sheet(isPresented: $showBatchShareSheet) {
                ActivityShareSheet(items: batchShareItems)
            }
        }
    }

    private func mediaGridCell(_ item: CapturedMediaItem) -> some View {
        let isSelected = selectedIds.contains(item.id)
        let qualityLabel = item.resolution.uppercased().contains("4K") ? "4K" : "HD"

        return Button {
            if isSelecting {
                if isSelected {
                    selectedIds.remove(item.id)
                } else {
                    selectedIds.insert(item.id)
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } else {
                selectedItem = item
            }
        } label: {
            GeometryReader { geo in
                ZStack {
                    Image(uiImage: item.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.width)
                        .clipped()

                    VStack {
                        HStack {
                            Text(qualityLabel)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.black.opacity(0.65))
                                )

                            Spacer()

                            if isSelecting {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(isSelected ? accentYellow : .white)
                                    .shadow(radius: 2)
                            }
                        }

                        Spacer()

                        if item.isVideo {
                            HStack {
                                Spacer()
                                Text(item.duration ?? "00:42")
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.black.opacity(0.70))
                                    )
                            }
                        }
                    }
                    .padding(5)

                    if isSelecting && isSelected {
                        Rectangle()
                            .stroke(accentYellow, lineWidth: 2.5)
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .background(Color.secondary.opacity(0.18))
            .clipped()
        }
        .buttonStyle(.plain)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 46))
                .foregroundColor(.secondary.opacity(0.65))
            Text("Chưa có video/ảnh nào")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            Text("Hãy nhấn nút Quay đỏ ở màn hình Studio để lưu khung hình 4K đầu tiên.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Spacer()
        }
    }

    private var batchSelectionBar: some View {
        HStack {
            Button {
                let shareTargets: [Any] = filteredMedia
                    .filter { selectedIds.contains($0.id) }
                    .map { ($0.isVideo ? ($0.videoURL as Any?) : nil) ?? $0.image }
                guard !shareTargets.isEmpty else { return }
                batchShareItems = shareTargets
                showBatchShareSheet = true
            } label: {
                Label("Chia sẻ (\(selectedIds.count))", systemImage: "square.and.arrow.up")
                    .font(.system(size: 14, weight: .semibold))
            }
            .disabled(selectedIds.isEmpty)

            Spacer()

            Button(role: .destructive) {
                let targets = filteredMedia.filter { selectedIds.contains($0.id) }
                for item in targets {
                    camera.deleteMedia(item)
                }
                selectedIds.removeAll()
                isSelecting = false
            } label: {
                Label("Xóa", systemImage: "trash")
                    .font(.system(size: 14, weight: .semibold))
            }
            .disabled(selectedIds.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

// MARK: - 28_player: Detail Preview & Player Sheet

struct MediaDetailPreviewSheet: View {
    let item: CapturedMediaItem
    var onSaveEditedCopy: ((CapturedMediaItem) -> Void)? = nil
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var avPlayer: AVPlayer? = nil
    @State private var isFavorite: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var showClipEditor: Bool = false

    private let accentYellow = Color(red: 1.0, green: 0.84, blue: 0.04) // #FFD60A

    private var timestampLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "Hôm nay, \(formatter.string(from: item.timestamp))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .light ? Color(red: 0.96, green: 0.96, blue: 0.98) : Color.black)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer(minLength: 10)

                    ZStack {
                        if item.isVideo, let player = avPlayer {
                            VideoPlayer(player: player)
                                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                                .cornerRadius(12)
                                .padding(.horizontal, 8)
                        } else {
                            Image(uiImage: item.image)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                                .padding(.horizontal, 8)
                        }
                    }

                    Spacer(minLength: 10)

                    if item.isVideo && item.videoURL == nil {
                        Text("Video bản xem trước tĩnh (chưa có tệp .mov trên thiết bị)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                    }

                    bottomActionToolbar
                }
            }
            .onAppear {
                if item.isVideo, let url = item.videoURL, avPlayer == nil {
                    let player = AVPlayer(url: url)
                    avPlayer = player
                    player.play()
                }
            }
            .onDisappear {
                avPlayer?.pause()
                avPlayer = nil
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Đóng") {
                        dismiss()
                    }
                    .foregroundColor(accentYellow)
                }

                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text(timestampLabel)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("\(item.resolution) • \(item.profile)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ActivityShareSheet(items: [(item.isVideo ? (item.videoURL as Any?) : nil) ?? item.image])
            }
            .sheet(isPresented: $showClipEditor) {
                ClipEditorSheetView(item: item) { editedCopy in
                    onSaveEditedCopy?(editedCopy)
                }
            }
        }
    }

    private var bottomActionToolbar: some View {
        HStack(spacing: 10) {
            playerActionButton(
                icon: "square.and.arrow.up",
                title: "Chia sẻ",
                tint: .primary
            ) {
                showShareSheet = true
            }

            playerActionButton(
                icon: isFavorite ? "heart.fill" : "heart",
                title: "Yêu thích",
                tint: isFavorite ? .pink : .primary
            ) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                isFavorite.toggle()
            }

            playerActionButton(
                icon: "slider.horizontal.3",
                title: "Chỉnh sửa clip",
                tint: accentYellow
            ) {
                showClipEditor = true
            }

            playerActionButton(
                icon: "trash",
                title: "Xóa",
                tint: .red
            ) {
                onDelete()
                dismiss()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private func playerActionButton(
        icon: String,
        title: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundColor(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
    }

    private func formattedSeconds(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

// MARK: - 29_editor: Clip Editor Sheet

struct ClipEditorSheetView: View {
    let item: CapturedMediaItem
    var onSaveCopy: ((CapturedMediaItem) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var trimStart: Double = 0.12
    @State private var trimEnd: Double = 0.88
    @State private var selectedLut: String = "Gốc"
    @State private var activeToolTab: Int = 0
    @State private var selectedRatio: String = "16:9"
    @State private var playbackSpeed: Double = 1.0
    @State private var selectedSoundtrack: String = "Không có"

    private let accentYellow = Color(red: 1.0, green: 0.84, blue: 0.04) // #FFD60A
    private let lutPresets = ["Gốc", "Cinematic", "Teal/Orange", "Ấm áp", "Đơn sắc", "Cổ điển"]
    private let ratioPresets = ["16:9", "9:16", "4:3", "1:1"]
    private let speedPresets = [0.5, 1.0, 1.5, 2.0]
    private let soundtrackPresets = ["Không có", "Cinematic Epic", "Lo-fi Travel", "Action Beat"]

    private var selectedDurationText: String {
        let baseSeconds: Double = {
            if let videoURL = item.videoURL {
                let assetSecs = AVURLAsset(url: videoURL).duration.seconds
                if assetSecs.isFinite && assetSecs > 0 { return assetSecs }
            }
            if let dur = item.duration {
                let parts = dur.split(separator: ":").compactMap { Double($0) }
                if parts.count == 2 { return parts[0] * 60 + parts[1] }
                if parts.count == 3 { return parts[0] * 3600 + parts[1] * 60 + parts[2] }
            }
            return 10.0
        }()
        let selected = max(0.5, (trimEnd - trimStart) * baseSeconds / playbackSpeed)
        return String(format: "00:%04.1f", selected)
    }

    private var previewAspectRatio: CGFloat {
        switch selectedRatio {
        case "9:16": return 9.0 / 16.0
        case "4:3": return 4.0 / 3.0
        case "1:1": return 1.0
        default: return 16.0 / 9.0
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                previewStage

                trimTimelineSection

                toolContentSection

                bottomToolTabs
            }
            .padding(.top, 8)
            .background(
                (colorScheme == .light ? Color(red: 0.96, green: 0.96, blue: 0.98) : Color.black)
                    .ignoresSafeArea()
            )
            .navigationTitle("Chỉnh sửa clip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Huỷ") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Lưu bản sao") {
                        let newId = UUID()
                        var copiedVideoURL: URL? = nil
                        var copiedFileName = ""
                        if item.isVideo, let srcURL = item.videoURL {
                            let tmpCopy = FileManager.default.temporaryDirectory
                                .appendingPathComponent("\(newId.uuidString).mov")
                            try? FileManager.default.removeItem(at: tmpCopy)
                            if (try? FileManager.default.copyItem(at: srcURL, to: tmpCopy)) != nil {
                                copiedVideoURL = tmpCopy
                                copiedFileName = "\(newId.uuidString).mov"
                            }
                        }
                        let copied = CapturedMediaItem(
                            id: newId,
                            image: item.image,
                            isVideo: item.isVideo,
                            duration: item.isVideo ? String(selectedDurationText.prefix(5)) : nil,
                            resolution: "\(selectedRatio) • \(item.resolution)",
                            profile: "LUT \(selectedLut)",
                            fileName: copiedFileName,
                            videoURL: copiedVideoURL
                        )
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        onSaveCopy?(copied)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(accentYellow)
                }
            }
        }
    }

    private var previewStage: some View {
        ZStack(alignment: .bottomLeading) {
            Image(uiImage: item.image)
                .resizable()
                .scaledToFill()
                .saturation(lutSaturation)
                .contrast(lutContrast)
                .brightness(lutBrightness)
                .colorMultiply(lutTint)
                .aspectRatio(previewAspectRatio, contentMode: .fit)
                .frame(maxHeight: 240)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
                .clipped()

            HStack(spacing: 8) {
                Label(selectedLut, systemImage: "camera.filters")
                Text("•")
                Text("\(selectedRatio)")
                Text("•")
                Text(String(format: "%.1fx", playbackSpeed))
                if selectedSoundtrack != "Không có" {
                    Text("•")
                    Label(selectedSoundtrack, systemImage: "music.note")
                }
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.black.opacity(0.68)))
            .padding(10)
        }
        .padding(.horizontal, 16)
    }

    private var trimTimelineSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Đoạn chọn: \(selectedDurationText)")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(accentYellow)
                Spacer()
                Text("Điểm vào \(Int(trimStart * 100))% - Ra \(Int(trimEnd * 100))%")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            // Trim strip with #FFD60A highlighted frame border
            GeometryReader { geo in
                let width = max(1, geo.size.width)
                let startX = width * CGFloat(trimStart)
                let selectionW = max(24, width * CGFloat(max(0.08, trimEnd - trimStart)))

                ZStack(alignment: .leading) {
                    HStack(spacing: 1) {
                        ForEach(0..<8, id: \.self) { _ in
                            Image(uiImage: item.image)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, height: 48)
                                .clipped()
                                .opacity(0.42)
                        }
                    }
                    .cornerRadius(8)

                    RoundedRectangle(cornerRadius: 8)
                        .stroke(accentYellow, lineWidth: 3)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(accentYellow.opacity(0.12))
                        )
                        .frame(width: min(width - startX, selectionW), height: 48)
                        .offset(x: startX)
                }
            }
            .frame(height: 48)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Đầu clip")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                    Slider(value: $trimStart, in: 0.0...max(0.05, trimEnd - 0.12))
                        .tint(accentYellow)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Cuối clip")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                    Slider(value: $trimEnd, in: min(0.95, trimStart + 0.12)...1.0)
                        .tint(accentYellow)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var toolContentSection: some View {
        switch activeToolTab {
        case 1:
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ratioPresets, id: \.self) { ratio in
                        editorOptionChip(title: ratio, isSelected: selectedRatio == ratio) {
                            selectedRatio = ratio
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        case 2:
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(speedPresets, id: \.self) { speed in
                        editorOptionChip(
                            title: String(format: "%.1fx", speed),
                            isSelected: abs(playbackSpeed - speed) < 0.01
                        ) {
                            playbackSpeed = speed
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        case 3:
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(soundtrackPresets, id: \.self) { track in
                        editorOptionChip(title: track, isSelected: selectedSoundtrack == track) {
                            selectedSoundtrack = track
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        default:
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(lutPresets, id: \.self) { lut in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedLut = lut
                        } label: {
                            VStack(spacing: 5) {
                                Image(uiImage: item.image)
                                    .resizable()
                                    .scaledToFill()
                                    .saturation(lut == "Đơn sắc" ? 0.0 : (lut == "Cinematic" ? 1.2 : 1.0))
                                    .frame(width: 56, height: 56)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedLut == lut ? accentYellow : Color.clear, lineWidth: 2.5)
                                    )

                                Text(lut)
                                    .font(.system(size: 11, weight: selectedLut == lut ? .bold : .medium))
                                    .foregroundColor(selectedLut == lut ? accentYellow : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var bottomToolTabs: some View {
        HStack(spacing: 6) {
            editorToolTab(index: 0, title: "Màu sắc (LUT)")
            editorToolTab(index: 1, title: "Tỉ lệ \(selectedRatio)")
            editorToolTab(index: 2, title: String(format: "Tốc độ %.1fx", playbackSpeed))
            editorToolTab(index: 3, title: "Nhạc nền")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private func editorToolTab(index: Int, title: String) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            activeToolTab = index
        } label: {
            Text(title)
                .font(.system(size: 12, weight: activeToolTab == index ? .bold : .medium))
                .foregroundColor(activeToolTab == index ? accentYellow : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
        }
    }

    private func editorOptionChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .black : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(isSelected ? accentYellow : Color.secondary.opacity(0.16))
                )
        }
    }

    private var lutSaturation: Double {
        switch selectedLut {
        case "Đơn sắc": return 0.0
        case "Cinematic": return 1.18
        case "Teal/Orange": return 1.25
        case "Cổ điển": return 0.72
        default: return 1.0
        }
    }

    private var lutContrast: Double {
        switch selectedLut {
        case "Cinematic": return 1.16
        case "Teal/Orange": return 1.12
        case "Cổ điển": return 0.92
        default: return 1.0
        }
    }

    private var lutBrightness: Double {
        selectedLut == "Ấm áp" ? 0.04 : 0.0
    }

    private var lutTint: Color {
        switch selectedLut {
        case "Teal/Orange": return Color(red: 0.94, green: 1.0, blue: 0.98)
        case "Ấm áp": return Color(red: 1.0, green: 0.94, blue: 0.86)
        case "Cổ điển": return Color(red: 0.96, green: 0.93, blue: 0.85)
        default: return .white
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
