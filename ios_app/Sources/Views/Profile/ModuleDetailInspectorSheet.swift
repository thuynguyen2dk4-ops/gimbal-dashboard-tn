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

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: detail.icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.10))
                Text(detail.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.top, 24)

            Text(detail.desc)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider().background(Color.white.opacity(0.1))

            let isEnabled = store.modules.indices.contains(detail.index) ? store.modules[detail.index] : true
            HStack {
                Text("Trạng thái kích hoạt cục bộ:")
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                Spacer()
                Button(isEnabled ? "TẮT MODULE" : "BẬT MODULE") {
                    store.toggleModule(at: detail.index)
                }
                .font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background((isEnabled ? Color.red : Color.green).opacity(0.2))
                .foregroundColor(isEnabled ? .red : .green)
                .cornerRadius(8)
            }

            Spacer()
        }
        .padding(20)
        .background(Color(red: 0.11, green: 0.11, blue: 0.14).ignoresSafeArea())
    }
}
