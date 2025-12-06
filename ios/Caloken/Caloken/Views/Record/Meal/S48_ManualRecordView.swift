import SwiftUI

struct S48_ManualRecordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var mealDescription: String = ""
    @State private var isAnalyzing: Bool = false
    @State private var rotation: Double = 0
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // メインコンテンツ
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("何を食べましたか？")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            TextField("例：ご飯1杯、焼き鮭、味噌汁、サラダ", text: $mealDescription, axis: .vertical)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                                .lineLimit(5...10)
                                .padding(16)
                                .frame(minHeight: 150, alignment: .topLeading)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                                .focused($isTextFieldFocused)
                                .disabled(isAnalyzing)
                        }
                        
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 16))
                            
                            Text("量や個数を入れるとより正確に計算できます")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.yellow.opacity(0.15))
                        .cornerRadius(12)
                    }
                    .padding(20)
                }
                
                VStack(spacing: 0) {
                    Divider()
                    
                    Button(action: { startAnalysis() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text("AIでマクロ計算")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            mealDescription.isEmpty || isAnalyzing
                                ? Color(UIColor.systemGray3)
                                : Color.orange
                        )
                        .cornerRadius(16)
                    }
                    .disabled(mealDescription.isEmpty || isAnalyzing)
                    .padding(20)
                }
                .background(Color(UIColor.systemBackground))
            }
            .background(Color(UIColor.systemGroupedBackground))
            .opacity(isAnalyzing ? 0.3 : 1.0)
            
            // 分析中オーバーレイ（短く表示）
            if isAnalyzing {
                VStack(spacing: 32) {
                    ZStack {
                        Circle()
                            .stroke(Color(UIColor.systemGray5), lineWidth: 4)
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(rotation))
                        
                        Text("📝")
                            .font(.system(size: 36))
                    }
                    
                    Text("記録中...")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
        }
        .navigationTitle("手動で入力")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
                .disabled(isAnalyzing)
            }
            
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("完了") {
                        isTextFieldFocused = false
                    }
                }
            }
        }
        .enableSwipeBack()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTextFieldFocused = true
            }
        }
    }
    
    private func startAnalysis() {
        isTextFieldFocused = false
        isAnalyzing = true
        
        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        
        // 少し待ってからホームに戻る
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // ホーム画面のログに追加して分析開始
            AnalyzingManager.shared.startManualMealAnalyzing(description: mealDescription, for: Date())
            
            // 即座にホームに戻る
            NotificationCenter.default.post(name: .dismissAllMealScreens, object: nil)
            dismiss()
        }
    }
}
