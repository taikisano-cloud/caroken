import SwiftUI

struct S27_9_DeleteAccountView: View {
    @State private var showFinalConfirmation: Bool = false
    @State private var selectedReason: DeleteReason? = nil
    @State private var otherReason: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var onAccountDeleted: (() -> Void)?
    
    enum DeleteReason: String, CaseIterable, Identifiable {
        case notUseful = "アプリが役に立たなかった"
        case tooComplicated = "使い方が難しかった"
        case foundBetter = "他のアプリを使うことにした"
        case goalAchieved = "目標を達成した"
        case privacy = "プライバシーが心配"
        case other = "その他"
        
        var id: String { rawValue }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 悲しいイラスト
                VStack(spacing: 16) {
                    Text("😢")
                        .font(.system(size: 80))
                    
                    Text("本当に退会しますか？")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("あなたがいなくなると寂しいです...")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                
                // 失うものリスト
                VStack(alignment: .leading, spacing: 16) {
                    Text("退会すると失われるもの")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    LossItemRow(icon: "chart.line.uptrend.xyaxis", text: "これまでの記録データすべて", color: .blue)
                    LossItemRow(icon: "flame.fill", text: "連続記録の達成状況", color: .orange)
                    LossItemRow(icon: "star.fill", text: "獲得したバッジ・実績", color: .yellow)
                    LossItemRow(icon: "person.fill", text: "プロフィール情報", color: .green)
                    LossItemRow(icon: "clock.arrow.circlepath", text: "過去の体重変化履歴", color: .purple)
                }
                .padding(20)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal, 16)
                
                // 代替案の提案
                VStack(alignment: .leading, spacing: 16) {
                    Text("こんな方法もあります")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    AlternativeRow(
                        icon: "bell.slash.fill",
                        title: "通知をオフにする",
                        description: "設定から通知を無効にできます"
                    )
                    
                    AlternativeRow(
                        icon: "pause.circle.fill",
                        title: "しばらくお休みする",
                        description: "データは保持したまま休憩できます"
                    )
                    
                    AlternativeRow(
                        icon: "envelope.fill",
                        title: "ご意見をお聞かせください",
                        description: "改善のためのフィードバックを送る"
                    )
                }
                .padding(20)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal, 16)
                
                // 退会理由
                VStack(alignment: .leading, spacing: 12) {
                    Text("退会理由を教えてください")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    ForEach(DeleteReason.allCases) { reason in
                        Button {
                            selectedReason = reason
                        } label: {
                            HStack {
                                Image(systemName: selectedReason == reason ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedReason == reason ? .blue : .gray)
                                Text(reason.rawValue)
                                    .font(.system(size: 15))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    
                    if selectedReason == .other {
                        TextField("理由を入力してください", text: $otherReason)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding(20)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal, 16)
                
                // ボタン
                VStack(spacing: 12) {
                    // 継続ボタン（目立たせる）
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "heart.fill")
                            Text("やっぱり続ける")
                        }
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.orange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    
                    // 退会ボタン（控えめ）
                    Button {
                        showFinalConfirmation = true
                    } label: {
                        Text("退会手続きを進める")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .underline()
                    }
                    .disabled(selectedReason == nil)
                    .opacity(selectedReason == nil ? 0.5 : 1)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .background(Color(UIColor.systemBackground))
        .navigationTitle("アカウント削除")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFinalConfirmation) {
            FinalConfirmationView(
                reason: selectedReason?.rawValue ?? "",
                otherReason: otherReason,
                onDeleted: {
                    dismiss()
                    onAccountDeleted?()
                }
            )
        }
    }
}

// MARK: - 失うものアイテム
struct LossItemRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red.opacity(0.7))
        }
    }
}

// MARK: - 代替案アイテム
struct AlternativeRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}

// MARK: - 最終確認画面
struct FinalConfirmationView: View {
    let reason: String
    let otherReason: String
    
    @State private var confirmText: String = ""
    @State private var isDeleting: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared
    
    var onDeleted: (() -> Void)?
    
    private let requiredText = "削除"
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // 警告アイコン
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                Text("最終確認")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("この操作は取り消すことができません。\nすべてのデータが完全に削除されます。")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                // 確認入力
                VStack(alignment: .leading, spacing: 8) {
                    Text("確認のため「\(requiredText)」と入力してください")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    TextField("", text: $confirmText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // ボタン
                VStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Text("キャンセル")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    Button {
                        deleteAccount()
                    } label: {
                        if isDeleting {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("削除中...")
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red.opacity(0.5))
                            .cornerRadius(12)
                        } else {
                            Text("アカウントを削除する")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(confirmText == requiredText ? Color.red : Color.gray)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(confirmText != requiredText || isDeleting)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle("アカウント削除")
            .navigationBarTitleDisplayMode(.inline)
            .alert("エラー", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func deleteAccount() {
        isDeleting = true
        
        print("🗑️ Starting account deletion...")
        print("   Reason: \(reason)")
        if !otherReason.isEmpty {
            print("   Other reason: \(otherReason)")
        }
        
        Task {
            do {
                // AuthServiceでアカウント削除を実行（理由も送信）
                try await authService.deleteAccount(reason: reason, otherReason: otherReason)
                
                await MainActor.run {
                    isDeleting = false
                    print("✅ Account deleted successfully")
                    
                    // UserProfileManagerもリセット
                    UserProfileManager.shared.resetAllData()
                    
                    dismiss()
                    onDeleted?()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    errorMessage = "アカウント削除に失敗しました: \(error.localizedDescription)"
                    showError = true
                    print("❌ Delete account error: \(error)")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        S27_9_DeleteAccountView()
    }
}
