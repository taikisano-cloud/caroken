import SwiftUI

struct S27_1_SettingsView: View {
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var weightLogsManager = WeightLogsManager.shared
    
    @State private var isHealthSyncEnabled: Bool = true
    @State private var showSignOutAlert: Bool = false
    @State private var navigateToOnboarding: Bool = false
    
    // 性別表示テキスト
    private var genderDisplayText: String {
        switch profileManager.gender {
        case "Male": return "男性"
        case "Female": return "女性"
        case "Other": return "その他"
        default: return "未設定"
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // 身体情報セクション
                    VStack(spacing: 0) {
                        NavigationLink {
                            S27_2_ProfileEditView()
                        } label: {
                            ProfileRow(label: "身長", value: "\(profileManager.height) cm")
                        }
                        
                        Divider().padding(.leading, 16)
                        
                        NavigationLink {
                            S27_2_ProfileEditView()
                        } label: {
                            ProfileRow(label: "体重", value: String(format: "%.1f kg", weightLogsManager.currentWeight))
                        }
                        
                        Divider().padding(.leading, 16)
                        
                        NavigationLink {
                            S27_2_ProfileEditView()
                        } label: {
                            ProfileRow(label: "性別", value: genderDisplayText)
                        }
                        
                        Divider().padding(.leading, 16)
                        
                        NavigationLink {
                            S27_2_ProfileEditView()
                        } label: {
                            ProfileRow(label: "生年月日", value: formatDate(profileManager.birthDate))
                        }
                    }
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    
                    // Apple Health同期
                    HStack(spacing: 12) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.pink)
                            .cornerRadius(8)
                        
                        Text("Apple Healthと同期")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Toggle("", isOn: $isHealthSyncEnabled)
                            .labelsHidden()
                    }
                    .padding(16)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    
                    // 栄養目標セクション
                    NavigationLink {
                        S27_3_NutritionGoalView()
                    } label: {
                        NutritionGoalCard(
                            calories: profileManager.calorieGoal,
                            carbs: profileManager.carbGoal,
                            protein: profileManager.proteinGoal,
                            fat: profileManager.fatGoal
                        )
                    }
                    .padding(.horizontal, 16)
                    
                    // その他の設定
                    VStack(spacing: 0) {
                        NavigationLink {
                            S27_5_FeatureRequestView()
                        } label: {
                            SettingsLinkRow(title: "機能リクエスト")
                        }
                        
                        Divider().padding(.leading, 16)
                        
                        NavigationLink {
                            S27_6_ContactView()
                        } label: {
                            SettingsLinkRow(title: "お問い合わせ")
                        }
                        
                        Divider().padding(.leading, 16)
                        
                        NavigationLink {
                            S27_4_NotificationSettingsView()
                        } label: {
                            SettingsLinkRow(title: "通知設定")
                        }
                    }
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    
                    // SNSセクション
                    VStack(spacing: 0) {
                        SocialLinkRow2(platform: "TikTok", urlString: "https://www.tiktok.com/@your_account")
                        Divider().padding(.leading, 16)
                        SocialLinkRow2(platform: "Instagram", urlString: "https://www.instagram.com/your_account")
                        Divider().padding(.leading, 16)
                        SocialLinkRow2(platform: "YouTube", urlString: "https://www.youtube.com/@your_account")
                        Divider().padding(.leading, 16)
                        SocialLinkRow2(platform: "X", urlString: "https://x.com/your_account")
                    }
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    
                    // 利用規約・プライバシーポリシー
                    VStack(spacing: 0) {
                        NavigationLink {
                            S27_7_TermsOfServiceView()
                        } label: {
                            SettingsLinkRow(title: "利用規約")
                        }
                        
                        Divider().padding(.leading, 16)
                        
                        NavigationLink {
                            S27_8_PrivacyPolicyView()
                        } label: {
                            SettingsLinkRow(title: "プライバシーポリシー")
                        }
                    }
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    
                    // アカウント管理
                    VStack(spacing: 0) {
                        Button {
                            showSignOutAlert = true
                        } label: {
                            HStack {
                                Text("サインアウト")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding(16)
                        }
                        
                        Divider().padding(.leading, 16)
                        
                        NavigationLink {
                            S27_9_DeleteAccountView(onAccountDeleted: {
                                navigateToOnboarding = true
                            })
                        } label: {
                            HStack {
                                Text("アカウント削除")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            .padding(16)
                        }
                    }
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    
                    // バージョン情報
                    Text("バージョン 1.0.0")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                }
                .padding(.top, 16)
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .alert("サインアウト", isPresented: $showSignOutAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("サインアウト", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("本当にサインアウトしますか？")
            }
            .fullScreenCover(isPresented: $navigateToOnboarding) {
                S1_OnboardingStartView()
            }
        }
    }
    
    private func signOut() {
        print("Signing out...")
        navigateToOnboarding = true
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月 d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - プロフィール行
struct ProfileRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text("\(label)：")
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding(16)
    }
}

// MARK: - 設定リンク行
struct SettingsLinkRow: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding(16)
    }
}

// MARK: - SNSリンク行（シンプル版）
struct SocialLinkRow2: View {
    let platform: String
    let urlString: String
    
    var body: some View {
        Button {
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack {
                Text(platform)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(16)
        }
    }
}

// MARK: - 栄養目標カード
struct NutritionGoalCard: View {
    let calories: Int
    let carbs: Int
    let protein: Int
    let fat: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("栄養目標")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            // 4つの円グラフ
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                NutritionCircle(
                    value: calories,
                    unit: "",
                    label: "kcal",
                    icon: "🔥",
                    color: .primary,
                    progress: 0.75
                )
                
                NutritionCircle(
                    value: carbs,
                    unit: "g",
                    label: "炭水化物",
                    icon: "🍞",
                    color: .orange,
                    progress: 0.7
                )
                
                NutritionCircle(
                    value: protein,
                    unit: "g",
                    label: "たんぱく質",
                    icon: "🥩",
                    color: Color.red.opacity(0.7),
                    progress: 0.65
                )
                
                NutritionCircle(
                    value: fat,
                    unit: "g",
                    label: "脂質",
                    icon: "🥑",
                    color: .blue,
                    progress: 0.6
                )
            }
        }
        .padding(20)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 栄養素サークル
struct NutritionCircle: View {
    let value: Int
    let unit: String
    let label: String
    let icon: String
    let color: Color
    let progress: Double
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Text(icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
            }
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                
                Text("\(value)\(unit)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
            }
        }
    }
}

#Preview {
    S27_1_SettingsView()
}
