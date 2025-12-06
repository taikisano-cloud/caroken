import SwiftUI

struct S27_7_TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("最終更新日: 2025年12月1日")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                
                // 第1条
                TermsSection(
                    title: "第1条（適用）",
                    content: """
                    本規約は、ユーザーと当社との間の本サービスの利用に関わる一切の関係に適用されるものとします。
                    当社は本サービスに関し、本規約のほか、ご利用にあたってのルール等、各種の定め（以下「個別規定」といいます。）をすることがあります。
                    """
                )
                
                // 第2条
                TermsSection(
                    title: "第2条（利用登録）",
                    content: """
                    本サービスにおいては、登録希望者が本規約に同意の上、当社の定める方法によって利用登録を申請し、当社がこれを承認することによって、利用登録が完了するものとします。
                    当社は、利用登録の申請者に以下の事由があると判断した場合、利用登録の申請を承認しないことがあります。
                    """
                )
                
                // 第3条
                TermsSection(
                    title: "第3条（ユーザーIDおよびパスワードの管理）",
                    content: """
                    ユーザーは、自己の責任において、本サービスのユーザーIDおよびパスワードを適切に管理するものとします。
                    ユーザーは、いかなる場合にも、ユーザーIDおよびパスワードを第三者に譲渡または貸与し、もしくは第三者と共用することはできません。
                    """
                )
                
                // 第4条
                TermsSection(
                    title: "第4条（禁止事項）",
                    content: """
                    ユーザーは、本サービスの利用にあたり、以下の行為をしてはなりません。
                    ・法令または公序良俗に違反する行為
                    ・犯罪行為に関連する行為
                    ・当社、本サービスの他のユーザー、または第三者のサーバーまたはネットワークの機能を破壊したり、妨害したりする行為
                    ・当社のサービスの運営を妨害するおそれのある行為
                    """
                )
                
                // 第5条
                TermsSection(
                    title: "第5条（本サービスの提供の停止等）",
                    content: """
                    当社は、以下のいずれかの事由があると判断した場合、ユーザーに事前に通知することなく本サービスの全部または一部の提供を停止または中断することができるものとします。
                    ・本サービスにかかるコンピュータシステムの保守点検または更新を行う場合
                    ・地震、落雷、火災、停電または天災などの不可抗力により、本サービスの提供が困難となった場合
                    """
                )
                
                // 第6条
                TermsSection(
                    title: "第6条（免責事項）",
                    content: """
                    当社は、本サービスに事実上または法律上の瑕疵（安全性、信頼性、正確性、完全性、有効性、特定の目的への適合性、セキュリティなどに関する欠陥、エラーやバグ、権利侵害などを含みます。）がないことを明示的にも黙示的にも保証しておりません。
                    当社は、本サービスに起因してユーザーに生じたあらゆる損害について一切の責任を負いません。
                    """
                )
                
                Spacer(minLength: 32)
            }
            .padding(20)
        }
        .background(Color(UIColor.systemBackground))
        .navigationTitle("利用規約")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 規約セクション
struct TermsSection: View {
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
        S27_7_TermsOfServiceView()
    }
}
