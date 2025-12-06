import SwiftUI

struct S27_8_PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("最終更新日: 2025年12月1日")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                
                // はじめに
                PrivacySection(
                    title: "はじめに",
                    content: """
                    本プライバシーポリシーは、当社が提供するカロ研（以下「本アプリ」といいます。）において、ユーザーの個人情報をどのように収集、使用、共有するかについて説明しています。
                    本アプリをご利用いただくことにより、本プライバシーポリシーに同意いただいたものとみなします。
                    """
                )
                
                // 収集する情報
                PrivacySection(
                    title: "収集する情報",
                    content: """
                    当社は、以下の情報を収集することがあります。
                    
                    【ユーザーが提供する情報】
                    ・アカウント情報（メールアドレス、パスワード）
                    ・プロフィール情報（身長、体重、性別、生年月日）
                    ・食事記録データ
                    ・運動記録データ
                    ・体重記録データ
                    
                    【自動的に収集される情報】
                    ・デバイス情報
                    ・利用状況データ
                    ・Apple HealthKitから取得するデータ（ユーザーの許可がある場合のみ）
                    """
                )
                
                // 情報の使用目的
                PrivacySection(
                    title: "情報の使用目的",
                    content: """
                    収集した情報は、以下の目的で使用します。
                    
                    ・本アプリのサービス提供および改善
                    ・カロリー計算および栄養管理機能の提供
                    ・ユーザーサポートの提供
                    ・統計データの作成（個人を特定できない形式で）
                    ・重要なお知らせの送信
                    """
                )
                
                // 情報の共有
                PrivacySection(
                    title: "情報の共有",
                    content: """
                    当社は、以下の場合を除き、ユーザーの個人情報を第三者と共有することはありません。
                    
                    ・ユーザーの同意がある場合
                    ・法令に基づく場合
                    ・人の生命、身体または財産の保護のために必要がある場合
                    ・サービス提供に必要な業務委託先との共有
                    """
                )
                
                // データの保護
                PrivacySection(
                    title: "データの保護",
                    content: """
                    当社は、ユーザーの個人情報を保護するために、適切な技術的および組織的措置を講じています。
                    ただし、インターネット上のデータ送信や電子的な保存方法は、100%安全であるとは保証できません。
                    """
                )
                
                // ユーザーの権利
                PrivacySection(
                    title: "ユーザーの権利",
                    content: """
                    ユーザーは、以下の権利を有します。
                    
                    ・自己の個人情報へのアクセス
                    ・個人情報の訂正または削除の要求
                    ・個人情報の処理に対する異議申立て
                    ・アカウントの削除
                    
                    これらの権利を行使する場合は、アプリ内の設定またはお問い合わせからご連絡ください。
                    """
                )
                
                // お問い合わせ
                PrivacySection(
                    title: "お問い合わせ",
                    content: """
                    本プライバシーポリシーに関するお問い合わせは、アプリ内の「お問い合わせ」機能よりご連絡ください。
                    """
                )
                
                Spacer(minLength: 32)
            }
            .padding(20)
        }
        .background(Color(UIColor.systemBackground))
        .navigationTitle("プライバシーポリシー")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - プライバシーセクション
struct PrivacySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
            
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
    }
}

#Preview {
    NavigationStack {
        S27_8_PrivacyPolicyView()
    }
}
