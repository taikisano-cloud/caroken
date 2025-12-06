import SwiftUI

struct S27_6_ContactView: View {
    @State private var contactType: ContactType = .bug
    @State private var contactText: String = ""
    @State private var email: String = ""
    @State private var showAlert: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    enum ContactType: String, CaseIterable {
        case bug = "不具合報告"
        case question = "質問"
        case other = "その他"
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
                    TextField("example@email.com", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section {
                    TextEditor(text: $contactText)
                        .frame(minHeight: 150)
                } header: {
                    Text("お問い合わせ内容")
                }
            }
            
            // 送信ボタン
            Button {
                sendContact()
            } label: {
                Text("送信")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(contactText.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(12)
            }
            .disabled(contactText.isEmpty)
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .navigationTitle("お問い合わせ")
        .navigationBarTitleDisplayMode(.inline)
        .alert("送信完了", isPresented: $showAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("お問い合わせをお送りしました。")
        }
    }
    
    private func sendContact() {
        // 送信処理（後で実装）
        showAlert = true
    }
}

#Preview {
    NavigationStack {
        S27_6_ContactView()
    }
}
