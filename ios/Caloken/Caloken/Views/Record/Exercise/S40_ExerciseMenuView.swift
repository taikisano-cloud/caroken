//
//  S40_ExerciseMenuView.swift
//  Caloken
//
//  Created by sano taiki on 2025/11/25.
//

import SwiftUI

struct S40_ExerciseMenuView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("運動記録画面")
                    .font(.title)
                Text("（実装予定）")
                    .foregroundColor(.gray)
            }
            .navigationTitle("運動を記録")
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
    S40_ExerciseMenuView()
}
