//
//  S48_ManualRecordView.swift
//  Caloken
//
//  Created by sano taiki on 2025/11/25.
//

import SwiftUI

struct S48_ManualRecordView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("手動記録画面")
                    .font(.title)
                Text("（実装予定）")
                    .foregroundColor(.gray)
            }
            .navigationTitle("手動で記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    S48_ManualRecordView()
}
