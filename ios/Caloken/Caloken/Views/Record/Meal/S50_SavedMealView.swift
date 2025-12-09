import SwiftUI

struct S50_SavedMealView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var savedMealsManager = SavedMealsManager.shared
    
    @State private var selectedMeal: SavedMeal? = nil
    @State private var showMealDetail: Bool = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if savedMealsManager.savedMeals.isEmpty {
                    SavedItemEmptyView(
                        icon: "fork.knife",
                        title: "保存した食事がありません",
                        message: "よく食べる食事を保存して\nすばやく記録しましょう"
                    )
                } else {
                    ForEach(savedMealsManager.savedMeals) { meal in
                        SavedMealCard(
                            meal: meal,
                            onTap: {
                                selectedMeal = meal
                                showMealDetail = true
                            },
                            onRecord: { recordMeal(meal) },
                            onDelete: { deleteMeal(meal) }
                        )
                    }
                }
            }
            .padding(20)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("保存済み")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
        }
        .enableSwipeBack()
        .navigationDestination(isPresented: $showMealDetail) {
            if let meal = selectedMeal {
                S46_MealDetailView(
                    result: MealAnalysisData(
                        foodItems: [MealFoodItem(name: meal.name, amount: "1食分", calories: meal.calories, protein: meal.protein, fat: meal.fat, carbs: meal.carbs, sugar: 0, fiber: 0, sodium: 0)],
                        totalCalories: meal.calories,
                        totalProtein: meal.protein,
                        totalFat: meal.fat,
                        totalCarbs: meal.carbs,
                        totalSugar: 0,
                        totalFiber: 0,
                        totalSodium: 0,
                        mealImage: nil,
                        characterComment: "\(meal.name)だね！\nおいしそう〜🍴"
                    ),
                    capturedImage: meal.image,  // 保存された画像を渡す
                    isFromLog: true,
                    hideBookmark: true
                )
            }
        }
    }
    
    private func recordMeal(_ meal: SavedMeal) {
        let mealLog = MealLogEntry(
            name: meal.name,
            calories: meal.calories,
            protein: Int(meal.protein),
            fat: Int(meal.fat),
            carbs: Int(meal.carbs),
            emoji: meal.emoji,
            image: meal.imageData  // 画像も含めて記録
        )
        MealLogsManager.shared.addLog(mealLog)
        
        NotificationCenter.default.post(
            name: .showHomeToast,
            object: nil,
            userInfo: ["message": "「\(meal.name)」を記録しました", "color": Color.green]
        )
        
        NotificationCenter.default.post(name: .dismissAllMealScreens, object: nil)
    }
    
    private func deleteMeal(_ meal: SavedMeal) {
        savedMealsManager.removeMeal(meal)
    }
}

// MARK: - 保存した食事カード（画像表示対応）
struct SavedMealCard: View {
    let meal: SavedMeal
    let onTap: () -> Void
    let onRecord: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteAlert: Bool = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 画像またはEmoji表示
                if let image = meal.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 70, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 70, height: 70)
                        .overlay(Text(meal.emoji).font(.system(size: 32)))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(meal.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Text("\(meal.calories)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.orange)
                        Text("kcal")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 6) {
                        NutrientMiniIcon(icon: "🍖", value: meal.protein, unit: "g")
                        NutrientMiniIcon(icon: "🥑", value: meal.fat, unit: "g")
                        NutrientMiniIcon(icon: "🍚", value: meal.carbs, unit: "g")
                    }
                    .fixedSize(horizontal: true, vertical: false)
                }
                
                Spacer(minLength: 8)
                
                VStack(spacing: 8) {
                    // 記録ボタン（+）
                    Button(action: onRecord) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.orange)
                    }
                    
                    // 削除ボタン（ゴミ箱）
                    Button(action: { showDeleteAlert = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .alert("削除しますか？", isPresented: $showDeleteAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) { onDelete() }
        } message: {
            Text("「\(meal.name)」を保存リストから削除します")
        }
    }
}

// MARK: - 栄養素ミニアイコン
struct NutrientMiniIcon: View {
    let icon: String
    let value: Double
    let unit: String
    
    var body: some View {
        HStack(spacing: 2) {
            Text(icon).font(.system(size: 10))
            Text(String(format: "%.0f", value) + unit)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color(UIColor.tertiarySystemFill))
        .cornerRadius(4)
        .fixedSize()
    }
}

// MARK: - 空状態ビュー
struct SavedItemEmptyView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(Color(UIColor.systemGray3))
            
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
