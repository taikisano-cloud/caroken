//
//  S26_NewsView.swift
//  Caloken
//
//  Created by sano taiki on 2025/11/25.
//

import SwiftUI

struct S26_NewsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("ニュース画面")
                        .font(.title)
                    Text("（実装予定）")
                        .foregroundColor(.gray)
                }
                .padding()
            }
            .navigationTitle("ニュース")
        }
    }
}

#Preview {
    S26_NewsView()
}
