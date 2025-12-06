import SwiftUI

struct S47_ShareMealView: View {
    @Environment(\.dismiss) var dismiss
    let result: MealAnalysisData
    var capturedImage: UIImage? = nil  // 追加: 撮影した画像を受け取る
    
    @State private var shareImage: UIImage?
    @State private var showShareSheet: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // プレビューカード
                ShareCardView(result: result, capturedImage: capturedImage)
                
                Spacer()
                
                // 共有ボタン
                VStack(spacing: 12) {
                    Button(action: {
                        generateShareImage()
                        showShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("画像を共有")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.orange)
                        .cornerRadius(25)
                    }
                    
                    Button(action: {
                        generateShareImage()
                        if let image = shareImage {
                            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        }
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("画像を保存")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color(UIColor.systemGray3), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("シェア")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = shareImage {
                    ShareSheet(items: [image])
                }
            }
        }
    }
    
    private func generateShareImage() {
        let shareCard = ShareCardForExport(result: result, capturedImage: capturedImage)
        let controller = UIHostingController(rootView: shareCard)
        let targetSize = CGSize(width: 350, height: 560)
        
        controller.view.bounds = CGRect(origin: .zero, size: targetSize)
        controller.view.backgroundColor = .white
        
        // レイアウトを強制更新
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        
        // 少し遅延させてレンダリングを確実にする
        DispatchQueue.main.async {
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            self.shareImage = renderer.image { context in
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: targetSize))
                controller.view.layer.render(in: context.cgContext)
            }
        }
    }
}

// MARK: - 共有カードビュー（プレビュー用）
struct ShareCardView: View {
    let result: MealAnalysisData
    var capturedImage: UIImage? = nil  // 追加
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // 食事の写真（固定高さ、幅いっぱい）
            ZStack(alignment: .bottomLeading) {
                // 撮影画像 > アセット画像 > プレースホルダー
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .clipped()
                } else if let imageName = result.mealImage, UIImage(named: imageName) != nil {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color(UIColor.systemGray5))
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .overlay(
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color(UIColor.systemGray3))
                        )
                }
                
                // グラデーションオーバーレイ
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: 220)
                
                // 料理名とカロリー
                VStack(alignment: .leading, spacing: 4) {
                    Text(getMealName())
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.orange)
                        Text("\(result.totalCalories)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Text("kcal")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(16)
            }
            .frame(height: 220)
            
            // コンテンツエリア
            VStack(spacing: 12) {
                // キャラクターとコメント
                HStack(alignment: .top, spacing: 0) {
                    if UIImage(named: "caloken_character") != nil {
                        Image("caloken_character")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 70, height: 70)
                    } else {
                        Circle()
                            .fill(Color.orange.opacity(0.3))
                            .frame(width: 70, height: 70)
                            .overlay(
                                Text("🐱")
                                    .font(.system(size: 32))
                            )
                    }
                    
                    HStack(spacing: 0) {
                        ShareSpeechTriangle()
                            .fill(commentBackgroundColor)
                            .frame(width: 12, height: 16)
                        
                        Text(result.characterComment)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(commentTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(commentBackgroundColor)
                            .cornerRadius(14)
                    }
                }
                .padding(.top, 14)
                
                // 栄養素（コンパクトに1行）
                HStack(spacing: 6) {
                    CompactNutrientItem(icon: "🍖", value: result.totalProtein, unit: "g")
                    CompactNutrientItem(icon: "🥑", value: result.totalFat, unit: "g")
                    CompactNutrientItem(icon: "🍚", value: result.totalCarbs, unit: "g")
                    CompactNutrientItem(icon: "🍬", value: result.totalSugar, unit: "g")
                    CompactNutrientItem(icon: "🌾", value: result.totalFiber, unit: "g")
                }
                
                // フッター
                HStack {
                    HStack(spacing: 4) {
                        if UIImage(named: "caloken_character") != nil {
                            Image("caloken_character")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 18, height: 18)
                        }
                        Text("カロ研")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(currentDateString())
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(UIColor.systemGray4), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var commentBackgroundColor: Color {
        colorScheme == .dark
            ? Color(UIColor.systemGray5)
            : Color.orange.opacity(0.15)
    }
    
    private var commentTextColor: Color {
        colorScheme == .dark
            ? Color.white
            : Color.primary
    }
    
    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: Date())
    }
    
    private func getMealName() -> String {
        if result.foodItems.count == 1 {
            return result.foodItems.first?.name ?? "食事"
        } else {
            return result.foodItems.map { $0.name }.joined(separator: "と")
        }
    }
}

// MARK: - シェア用エクスポートビュー（白背景固定）
struct ShareCardForExport: View {
    let result: MealAnalysisData
    var capturedImage: UIImage? = nil  // 追加
    
    var body: some View {
        ZStack {
            Color.white
            
            VStack(spacing: 0) {
                // 食事の写真
                ZStack(alignment: .bottomLeading) {
                    // 撮影画像 > アセット画像 > プレースホルダー
                    if let image = capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 220)
                            .frame(maxWidth: .infinity)
                            .clipped()
                    } else if let imageName = result.mealImage, UIImage(named: imageName) != nil {
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 220)
                            .frame(maxWidth: .infinity)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color(white: 0.9))
                            .frame(height: 220)
                            .frame(maxWidth: .infinity)
                            .overlay(
                                Image(systemName: "fork.knife.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(Color(white: 0.7))
                            )
                    }
                    
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.7)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    .frame(height: 220)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(getMealName())
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.orange)
                            Text("\(result.totalCalories)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            Text("kcal")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(16)
                }
                .frame(height: 220)
                
                VStack(spacing: 12) {
                    HStack(alignment: .top, spacing: 0) {
                        if UIImage(named: "caloken_character") != nil {
                            Image("caloken_character")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 70, height: 70)
                        } else {
                            Circle()
                                .fill(Color.orange.opacity(0.3))
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Text("🐱")
                                        .font(.system(size: 32))
                                )
                        }
                        
                        HStack(spacing: 0) {
                            ExportSpeechTriangle()
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 12, height: 16)
                            
                            Text(result.characterComment)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(Color.orange.opacity(0.15))
                                .cornerRadius(14)
                        }
                    }
                    .padding(.top, 14)
                    
                    HStack(spacing: 6) {
                        ExportNutrientItem(icon: "🍖", value: result.totalProtein, unit: "g")
                        ExportNutrientItem(icon: "🥑", value: result.totalFat, unit: "g")
                        ExportNutrientItem(icon: "🍚", value: result.totalCarbs, unit: "g")
                        ExportNutrientItem(icon: "🍬", value: result.totalSugar, unit: "g")
                        ExportNutrientItem(icon: "🌾", value: result.totalFiber, unit: "g")
                    }
                    
                    HStack {
                        HStack(spacing: 4) {
                            if UIImage(named: "caloken_character") != nil {
                                Image("caloken_character")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 18, height: 18)
                            }
                            Text("カロ研")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Text(currentDateString())
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .background(Color.white)
            }
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(white: 0.85), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .padding(10)
        }
    }
    
    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: Date())
    }
    
    private func getMealName() -> String {
        if result.foodItems.count == 1 {
            return result.foodItems.first?.name ?? "食事"
        } else {
            return result.foodItems.map { $0.name }.joined(separator: "と")
        }
    }
}

// MARK: - コンパクト栄養素アイテム（プレビュー用）
struct CompactNutrientItem: View {
    let icon: String
    let value: Double
    let unit: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(icon)
                .font(.system(size: 14))
            Text(formatValue(value) + unit)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(UIColor.tertiarySystemFill))
        .cornerRadius(8)
    }
    
    private func formatValue(_ value: Double) -> String {
        if value >= 100 {
            return String(format: "%.0f", value)
        } else if value >= 10 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
}

// MARK: - エクスポート用栄養素アイテム
struct ExportNutrientItem: View {
    let icon: String
    let value: Double
    let unit: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(icon)
                .font(.system(size: 14))
            Text(formatValue(value) + unit)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(white: 0.95))
        .cornerRadius(8)
    }
    
    private func formatValue(_ value: Double) -> String {
        if value >= 100 {
            return String(format: "%.0f", value)
        } else if value >= 10 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
}

// MARK: - 共有用吹き出し三角形
struct ShareSpeechTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - エクスポート用吹き出し三角形
struct ExportSpeechTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - 共有シート
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    S47_ShareMealView(
        result: MealAnalysisData(
            foodItems: [
                MealFoodItem(name: "ラーメン", amount: "1杯", calories: 500, protein: 20.0, fat: 15.0, carbs: 65.0, sugar: 5.0, fiber: 2.0, sodium: 1500),
                MealFoodItem(name: "餃子", amount: "6個", calories: 280, protein: 10.0, fat: 12.0, carbs: 30.0, sugar: 2.0, fiber: 1.5, sodium: 450)
            ],
            totalCalories: 780,
            totalProtein: 30.0,
            totalFat: 27.0,
            totalCarbs: 95.0,
            totalSugar: 7.0,
            totalFiber: 3.5,
            totalSodium: 1950,
            mealImage: "ramen_sample",
            characterComment: "ラーメンと餃子！\nボリューム満点だね〜🍜🥟"
        )
    )
}
