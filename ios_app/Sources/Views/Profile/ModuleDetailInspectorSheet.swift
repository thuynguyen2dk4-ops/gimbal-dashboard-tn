//
//  ModuleDetailInspectorSheet.swift
//  SmartGimbalPro
//
//  T-Flow Pro S1 — Modular SwiftUI Architecture (iOS 16.0+)
//

import SwiftUI

struct ModuleDetailInspectorSheet: View {
    let detail: ModuleDetailItem
    @ObservedObject var store: SupabaseModuleStore
    @Environment(\.dismiss) var dismiss

    private let goldAccent = Color(red: 0.98, green: 0.72, blue: 0.10)

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                HStack(spacing: 12) {
                    Image(systemName: detail.icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(goldAccent)
                        .frame(width: 46, height: 46)
                        .background(goldAccent.opacity(0.14))
                        .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(detail.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        Text(detail.desc)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(UIColor.secondarySystemGroupedBackground)))

                let isEnabled = store.modules.indices.contains(detail.index) ? store.modules[detail.index] : true
                HStack {
                    Text("Trạng thái kích hoạt")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Button(isEnabled ? "TẮT MODULE" : "BẬT MODULE") {
                        store.toggleModule(at: detail.index)
                    }
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background((isEnabled ? Color.red : Color.green).opacity(0.18))
                    .foregroundColor(isEnabled ? .red : .green)
                    .cornerRadius(10)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(UIColor.secondarySystemGroupedBackground)))

                Spacer()
            }
            .padding(16)
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Chi Tiết Module")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
    }
}
