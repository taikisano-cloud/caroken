import SwiftUI
import AuthenticationServices

struct S23_LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var navigateToPaywall: Bool = false
    @State private var navigateToTerms: Bool = false
    @State private var navigateToPrivacy: Bool = false
    @State private var isSigningIn: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        ZStack {
            // 背景
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // iPhone モックアップ
                LoginPhoneMockupView()
                    .padding(.top, 40)
                
                Spacer()
                
                // ログインセクション
                VStack(spacing: 20) {
                    // ドラッグインジケーター
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color(UIColor.systemGray3))
                        .frame(width: 36, height: 5)
                        .padding(.top, 10)
                    
                    // Appleでサインイン
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleAppleSignIn(result: result)
                    }
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 54)
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    .disabled(isSigningIn)
                    
                    // Googleでサインイン
                    Button {
                        navigateToPaywall = true
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 24, height: 24)
                                
                                Text("G")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.red, .yellow, .green, .blue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            Text("Googleで続ける")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(UIColor.separator), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 24)
                    .disabled(isSigningIn)
                    
                    // 開発用スキップボタン
                    Button {
                        navigateToPaywall = true
                    } label: {
                        Text("スキップ（開発用）")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                    
                    // 利用規約とプライバシーポリシー
                    VStack(spacing: 4) {
                        Text("続行することで、カロ研の")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Button {
                                navigateToTerms = true
                            } label: {
                                Text("利用規約")
                                    .font(.system(size: 13))
                                    .foregroundColor(.orange)
                            }
                            
                            Text("と")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            
                            Button {
                                navigateToPrivacy = true
                            } label: {
                                Text("プライバシーポリシー")
                                    .font(.system(size: 13))
                                    .foregroundColor(.orange)
                            }
                            
                            Text("に同意します")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 30)
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(LoginRoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
            }
            
            // ローディングオーバーレイ
            if isSigningIn {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .navigationBarBackButtonHidden(false)
        .navigationDestination(isPresented: $navigateToPaywall) {
            S51_PaywallView()
        }
        .navigationDestination(isPresented: $navigateToTerms) {
            S27_7_TermsOfServiceView()
        }
        .navigationDestination(isPresented: $navigateToPrivacy) {
            S27_8_PrivacyPolicyView()
        }
        .alert("サインインエラー", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                isSigningIn = true
                
                let userIdentifier = appleIDCredential.user
                let fullName = appleIDCredential.fullName
                let email = appleIDCredential.email
                
                print("✅ Apple Sign In Success")
                print("   User ID: \(userIdentifier)")
                if let givenName = fullName?.givenName {
                    print("   Name: \(givenName)")
                }
                if let email = email {
                    print("   Email: \(email)")
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isSigningIn = false
                    navigateToPaywall = true
                }
            }
        case .failure(let error):
            print("❌ Apple Sign In Error: \(error.localizedDescription)")
            
            if let authError = error as? ASAuthorizationError {
                handleAuthorizationError(authError)
            } else {
                errorMessage = "サインインに失敗しました: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    private func handleAuthorizationError(_ authError: ASAuthorizationError) {
        switch authError.code {
        case .canceled:
            print("   User canceled")
        case .unknown:
            print("   Unknown error")
            errorMessage = "Apple Sign Inを使用するには、Xcodeで'Sign in with Apple' Capabilityを追加してください。\n\n開発中は「スキップ」ボタンをお使いください。"
            showError = true
        case .invalidResponse:
            print("   Invalid response")
            errorMessage = "サーバーからの応答が無効です。もう一度お試しください。"
            showError = true
        case .notHandled:
            print("   Not handled")
            errorMessage = "認証リクエストが処理されませんでした。"
            showError = true
        case .failed:
            print("   Failed")
            errorMessage = "認証に失敗しました。もう一度お試しください。"
            showError = true
        case .notInteractive:
            print("   Not interactive")
        @unknown default:
            print("   Unknown case")
            errorMessage = "予期しないエラーが発生しました。"
            showError = true
        }
    }
}

// MARK: - iPhone モックアップ（S23専用）
struct LoginPhoneMockupView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // iPhone フレーム
            RoundedRectangle(cornerRadius: 40)
                .fill(Color(red: 0.85, green: 0.65, blue: 0.2))
                .frame(width: 280, height: 560)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            
            RoundedRectangle(cornerRadius: 35)
                .fill(Color.black)
                .frame(width: 268, height: 548)
            
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(UIColor.systemBackground))
                .frame(width: 256, height: 536)
            
            // アプリ画面のモック
            VStack(spacing: 0) {
                HStack {
                    Text("22:22")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "cellularbars")
                        Image(systemName: "wifi")
                        Image(systemName: "battery.100")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                HStack {
                    Text("🏠")
                        .font(.system(size: 20))
                    Text("カロ研")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "gearshape")
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                HStack(spacing: 8) {
                    ForEach(["火", "水", "木", "金", "土", "日", "月"], id: \.self) { day in
                        VStack(spacing: 4) {
                            Text(day)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            
                            Circle()
                                .stroke(day == "土" ? Color.orange : Color(UIColor.systemGray4), lineWidth: 1)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Text("\(3 + (["火", "水", "木", "金", "土", "日", "月"].firstIndex(of: day) ?? 0))")
                                        .font(.system(size: 10))
                                        .foregroundColor(.primary)
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .trim(from: 0.5, to: 1)
                            .stroke(Color(UIColor.systemGray4), lineWidth: 8)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0.5, to: 0.53)
                            .stroke(Color.orange, lineWidth: 8)
                            .frame(width: 120, height: 120)
                        
                        VStack(spacing: 0) {
                            HStack(alignment: .lastTextBaseline, spacing: 0) {
                                Text("150")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)
                                Text("/2241")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            Text("摂取kcal")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .offset(y: 10)
                    }
                    .frame(height: 80)
                    
                    VStack(spacing: 6) {
                        LoginNutrientBar(emoji: "🍖", label: "たんぱく質", current: 2, total: 162)
                        LoginNutrientBar(emoji: "🥑", label: "脂質", current: 1, total: 62)
                        LoginNutrientBar(emoji: "🍚", label: "炭水化物", current: 38, total: 258)
                    }
                    .padding(.horizontal, 12)
                }
                .padding(12)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                
                Spacer()
                
                HStack {
                    Spacer()
                    VStack(spacing: 2) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 18))
                        Text("ホーム")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 18))
                        Text("進捗")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.bottom, 8)
            }
            .frame(width: 256, height: 536)
        }
    }
}

struct LoginNutrientBar: View {
    let emoji: String
    let label: String
    let current: Int
    let total: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(emoji) \(label)")
                .font(.system(size: 9))
                .foregroundColor(.primary)
                .frame(width: 70, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(UIColor.systemGray4))
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(UIColor.systemGray2))
                        .frame(width: geometry.size.width * CGFloat(current) / CGFloat(total))
                }
            }
            .frame(height: 6)
            
            Text("\(current)/\(total)g")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .trailing)
        }
    }
}

// MARK: - 角丸Shape（S23専用）
struct LoginRoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    NavigationStack {
        S23_LoginView()
    }
}
