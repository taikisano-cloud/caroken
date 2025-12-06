import SwiftUI

struct S45_1_AnalyzingView: View {
    @Environment(\.dismiss) var dismiss
    
    // 画像入力（カメラから）
    var capturedImage: UIImage? = nil
    // テキスト入力（手動入力から）
    var mealDescription: String? = nil
    
    @State private var showMealDetail = false
    @State private var progress: CGFloat = 0
    @State private var statusText = "画像を解析中..."
    @State private var isDataReady = false
    
    // 分析結果（仮データ）
    @State private var analysisResult: MealAnalysisData?
    
    // クロップされた画像
    @State private var croppedImage: UIImage?
    
    var body: some View {
        ZStack {
            // 背景
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // 撮影画像のプレビュー（円形）
                if let image = croppedImage ?? capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 200)
                        .clipShape(Circle())  // 円形にクロップ
                        .overlay(
                            Circle()
                                .stroke(Color.orange.opacity(0.6), lineWidth: 3)
                        )
                        .shadow(color: .orange.opacity(0.4), radius: 15, x: 0, y: 5)
                } else if let description = mealDescription, !description.isEmpty {
                    // テキスト入力の場合
                    VStack(spacing: 12) {
                        Image(systemName: "text.alignleft")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(4)
                            .padding(.horizontal, 16)
                    }
                    .frame(width: 200, height: 200)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.orange.opacity(0.6), lineWidth: 3)
                    )
                    .shadow(color: .orange.opacity(0.4), radius: 15, x: 0, y: 5)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 200, height: 200)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                        )
                }
                
                // ローディングインジケーター
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                    }
                    
                    Text(statusText)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("AIが食事の栄養素を分析しています")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Text("キャンセル")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 40)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(25)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // 画像をクロップ
            if let image = capturedImage {
                croppedImage = cropToSquare(image: image)
            }
            startAnalysis()
        }
        .fullScreenCover(isPresented: $showMealDetail) {
            if let result = analysisResult {
                NavigationStack {
                    S46_MealDetailView(result: result, capturedImage: croppedImage ?? capturedImage)
                }
            }
        }
        .onChange(of: isDataReady) { _, newValue in
            if newValue && analysisResult != nil {
                // データ準備完了後に遷移
                showMealDetail = true
            }
        }
    }
    
    // 画像を正方形にクロップ（中央部分を切り取り）
    private func cropToSquare(image: UIImage) -> UIImage {
        let originalSize = image.size
        let minSide = min(originalSize.width, originalSize.height)
        
        // 中央を基準にクロップ
        let cropRect = CGRect(
            x: (originalSize.width - minSide) / 2,
            y: (originalSize.height - minSide) / 2,
            width: minSide,
            height: minSide
        )
        
        guard let cgImage = image.cgImage,
              let croppedCGImage = cgImage.cropping(to: cropRect) else {
            return image
        }
        
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    private func startAnalysis() {
        // テキスト入力の場合はステータスを変更
        if mealDescription != nil {
            statusText = "テキストを解析中..."
        }
        
        withAnimation(.easeInOut(duration: 2.0)) {
            progress = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            statusText = "食材を認識中..."
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            statusText = "栄養素を計算中..."
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            statusText = "完了！"
        }
        
        // データを先に準備
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            analysisResult = createMockAnalysisResult()
        }
        
        // 2.5秒後にデータ準備完了フラグを立てる（確実にデータが準備されてから）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isDataReady = true
        }
    }
    
    private func createMockAnalysisResult() -> MealAnalysisData {
        // テキスト入力の場合は、そのテキストを名前として使用
        let mealName = mealDescription ?? "検出された食事"
        
        return MealAnalysisData(
            foodItems: [
                MealFoodItem(
                    name: mealName,
                    amount: "1人前",
                    calories: 450,
                    protein: 18.0,
                    fat: 12.0,
                    carbs: 55.0,
                    sugar: 8.0,
                    fiber: 3.0,
                    sodium: 800
                )
            ],
            totalCalories: 450,
            totalProtein: 18.0,
            totalFat: 12.0,
            totalCarbs: 55.0,
            totalSugar: 8.0,
            totalFiber: 3.0,
            totalSodium: 800,
            mealImage: nil,
            characterComment: "美味しそう！\n栄養バランスをチェック📊"
        )
    }
}
