//
//  S27_1_SettingsView.swift
//  Caloken
//
//  Created by sano taiki on 2025/11/25.
//

import SwiftUI

struct S27_1_SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("ユーザー情報") {
                    NavigationLink("プロフィール編集") {
                        Text("プロフィール編集画面（実装予定）")
                    }
                    NavigationLink("栄養素目標") {
                        Text("栄養素目標画面（実装予定）")
                    }
                }
                
                Section("アプリ設定") {
                    Toggle("Apple Healthと同期", isOn: .constant(true))
                    NavigationLink("通知設定") {
                        Text("通知設定画面（実装予定）")
                    }
                }
                
                Section("サポート") {
                    NavigationLink("機能リクエスト") {
                        Text("機能リクエスト画面（実装予定）")
                    }
                    NavigationLink("お問い合わせ") {
                        Text("お問い合わせ画面（実装予定）")
                    }
                }
                
                Section("その他") {
                    NavigationLink("利用規約") {
                        Text("利用規約（実装予定）")
                    }
                    NavigationLink("プライバシーポリシー") {
                        Text("プライバシーポリシー（実装予定）")
                    }
                    Button("サインアウト") {
                        // サインアウト処理
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("設定")
        }
    }
}

#Preview {
    S27_1_SettingsView()
}
