import SwiftUI
import MessageUI

struct S27_6_ContactView: View {
    @State private var contactType: ContactType = .bug
    @State private var contactText: String = ""
    @State private var email: String = ""
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = "送信完了"
    @State private var alertMessage: String = "お問い合わせをお送りしました。"
    @State private var showMailComposer: Bool = false
    @State private var isSending: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    private let supportEmail = "support@stellacreation.com"
    
    enum ContactType: String, CaseIterable {
        case bug = "不具合報告"
        case question = "質問"
        case other = "その他"
        
        var emailSubject: String {
            switch self {
            case .bug: return "[カロ研] 不具合報告"
            case .question: return "[カロ研] お問い合わせ"
            case .other: return "[カロ研] その他のお問い合わせ"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("お問い合わせ種別") {
                    Picker("種別", selection: $contactType) {
                        ForEach(ContactType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("メールアドレス（任意）") {
                    ZStack(alignment: .leading) {
                        if email.isEmpty {
                            Text("example@email.com")
                                .foregroundColor(Color(UIColor.placeholderText))
                        }
                        TextField("", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                    }
                }
                
                Section {
                    ZStack(alignment: .topLeading) {
                        if contactText.isEmpty {
                            Text("お問い合わせ内容を入力してください...")
                                .foregroundColor(Color(UIColor.placeholderText))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $contactText)
                            .frame(minHeight: 150)
                            .opacity(contactText.isEmpty ? 0.25 : 1)
                    }
                } header: {
                    Text("お問い合わせ内容")
                }
            }
            
            // 送信ボタン
            Button {
                sendContact()
            } label: {
                if isSending {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("送信中...")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.gray)
                    .cornerRadius(12)
                } else {
                    Text("送信")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(contactText.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
            }
            .disabled(contactText.isEmpty || isSending)
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .navigationTitle("お問い合わせ")
        .navigationBarTitleDisplayMode(.inline)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if alertTitle == "送信完了" {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showMailComposer) {
            MailComposerView(
                toEmail: supportEmail,
                subject: contactType.emailSubject,
                body: buildEmailBody(),
                onResult: handleMailResult
            )
        }
    }
    
    private func buildEmailBody() -> String {
        var body = """
        【お問い合わせ種別】
        \(contactType.rawValue)
        
        【内容】
        \(contactText)
        
        """
        
        if !email.isEmpty {
            body += """
            【返信先メールアドレス】
            \(email)
            
            """
        }
        
        // デバイス情報を追加
        let device = UIDevice.current
        body += """
        ──────────────
        【デバイス情報】
        機種: \(device.model)
        OS: \(device.systemName) \(device.systemVersion)
        アプリバージョン: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "不明")
        """
        
        return body
    }
    
    private func sendContact() {
        // MFMailComposeViewControllerが使える場合はそれを使用
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else {
            // 使えない場合はmailto:スキームを使用
            openMailApp()
        }
    }
    
    private func openMailApp() {
        let subject = contactType.emailSubject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let body = buildEmailBody().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "mailto:\(supportEmail)?subject=\(subject)&body=\(body)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url) { success in
                    if success {
                        DispatchQueue.main.async {
                            alertTitle = "メールアプリを開きました"
                            alertMessage = "メールアプリから送信を完了してください。"
                            showAlert = true
                        }
                    } else {
                        DispatchQueue.main.async {
                            alertTitle = "エラー"
                            alertMessage = "メールアプリを開けませんでした。\n\(supportEmail) へ直接お問い合わせください。"
                            showAlert = true
                        }
                    }
                }
            } else {
                alertTitle = "メール送信不可"
                alertMessage = "メールアプリが設定されていません。\n\(supportEmail) へ直接お問い合わせください。"
                showAlert = true
            }
        }
    }
    
    private func handleMailResult(_ result: Result<MFMailComposeResult, Error>) {
        switch result {
        case .success(let mailResult):
            switch mailResult {
            case .sent:
                alertTitle = "送信完了"
                alertMessage = "お問い合わせをお送りしました。\nご返信までしばらくお待ちください。"
                showAlert = true
            case .saved:
                alertTitle = "下書き保存"
                alertMessage = "メールを下書きに保存しました。"
                showAlert = true
            case .cancelled:
                // キャンセルの場合は何もしない
                break
            case .failed:
                alertTitle = "送信失敗"
                alertMessage = "メールの送信に失敗しました。\n後でもう一度お試しください。"
                showAlert = true
            @unknown default:
                break
            }
        case .failure(let error):
            alertTitle = "エラー"
            alertMessage = "エラーが発生しました: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

// MARK: - Mail Composer View
struct MailComposerView: UIViewControllerRepresentable {
    let toEmail: String
    let subject: String
    let body: String
    let onResult: (Result<MFMailComposeResult, Error>) -> Void
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients([toEmail])
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onResult: onResult)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onResult: (Result<MFMailComposeResult, Error>) -> Void
        
        init(onResult: @escaping (Result<MFMailComposeResult, Error>) -> Void) {
            self.onResult = onResult
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                onResult(.failure(error))
            } else {
                onResult(.success(result))
            }
            controller.dismiss(animated: true)
        }
    }
}

#Preview {
    NavigationStack {
        S27_6_ContactView()
    }
}
