//
//  S45_CameraView.swift
//  Caloken
//
//  Created by sano taiki on 2025/11/25.
//

import SwiftUI

struct S45_CameraView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("カメラ画面")
                    .font(.title)
                Text("（実装予定）")
                    .foregroundColor(.gray)
            }
            .navigationTitle("食事を撮影")
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
    S45_CameraView()
}
