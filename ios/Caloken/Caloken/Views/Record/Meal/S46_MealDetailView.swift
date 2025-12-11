import SwiftUI

struct S46_MealDetailView: View {
    @Environment(\.dismiss) var dismiss
    let result: MealAnalysisData
    var capturedImage: UIImage? = nil
    var existingLogId: UUID? = nil
    var existingLogDate: Date? = nil
    var isFromLog: Bool = false
    var isFromManualEntry: Bool = false
    var hideBookmark: Bool = false  // ✅ trueの場合は保存済みからの遷移
    
    @State private var currentImage: UIImage? = nil
    @State private var quantity: Int = 1
    @State private var isBookmarked: Bool = false
    @State private var showCamera: Bool = false
    @State private var showBookmarkAlert: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var selectedDate: Date = Date()
    
    @State private var editedMealName: String = ""
    @State private var editedCalories: Int = 0
    @State private var editedProtein: Double = 0
    @State private var editedFat: Double = 0
    @State private var editedCarbs: Double = 0
    @State private var editedSugar: Double = 0
    @State private var editedFiber: Double = 0
    @State private var editedSodium: Double = 0
    
    @State private var editingField: EditingField? = nil
    @State private var characterComment: String = ""
    @State private var isLoadingComment: Bool = false
    @FocusState private var focusedField: EditingField?
    @FocusState private var isMealNameFocused: Bool
    
    var isEditMode: Bool { existingLogId != nil }
    
    // ✅ 保存済みからの遷移かどうか（hideBookmarkで判定）
    var isFromSavedMeals: Bool { hideBookmark }
    
    enum EditingField {
        case calories, protein, fat, carbs, sugar, fiber, sodium
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    photoAndCharacterSection
                    mealNameSection
                    calorieCardSection
                    nutrientGridUpperSection
                    nutrientGridLowerSection
                    editHintSection
                }
                .padding(.bottom, 10)
            }
            .onTapGesture {
                editingField = nil
                focusedField = nil
            }
            
            bottomButtonsSection
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar { toolbarContent }
        .fullScreenCover(isPresented: $showCamera) {
            S45_CameraView()
        }
        .sheet(isPresented: $showDatePicker) {
            MealDatePickerSheet(selectedDate: $selectedDate)
        }
        .onAppear {
            loadOriginalData()
        }
        .onChange(of: editingField) { oldValue, newValue in
            focusedField = newValue
        }
        .enableSwipeBack()
    }
    
    // MARK: - 写真とキャラクターセクション
    private var photoAndCharacterSection: some View {
        ZStack {
            photoView
            characterOverlay
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 5)
    }
    
    @ViewBuilder
    private var photoView: some View {
        if let image = currentImage {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 220, height: 220)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        } else if let imageName = result.mealImage, UIImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 220, height: 220)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        } else {
            Circle()
                .fill(Color(UIColor.systemGray4))
                .frame(width: 220, height: 220)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 60))
                        .foregroundColor(Color(UIColor.systemGray2))
                )
        }
    }
    
    private var characterOverlay: some View {
        VStack {
            Spacer()
            HStack {
                HStack(alignment: .top, spacing: 0) {
                    characterImage
                    speechBubble
                }
                Spacer()
            }
        }
        .frame(width: 320, height: 280)
    }
    
    @ViewBuilder
    private var characterImage: some View {
        if UIImage(named: "caloken_full") != nil {
            Image("caloken_full")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
        } else {
            Circle()
                .fill(Color.orange.opacity(0.3))
                .frame(width: 80, height: 80)
                .overlay(Text("🐱").font(.system(size: 40)))
        }
    }
    
    private var speechBubble: some View {
        HStack(spacing: 0) {
            SpeechBubbleTriangle()
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .frame(width: 10, height: 16)
            
            Group {
                if isLoadingComment {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("考え中...")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text(getDisplayComment())
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            .padding(10)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
        .offset(y: 10)
    }
    
    // ✅ 表示するコメントを取得
    private func getDisplayComment() -> String {
        if !characterComment.isEmpty {
            return characterComment
        } else {
            return "美味しそうだにゃ！🐱"
        }
    }
    
    // MARK: - 料理名セクション
    private var mealNameSection: some View {
        HStack {
            if !hideBookmark {
                bookmarkButton
            }
            
            TextField("料理名", text: $editedMealName)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
                .textFieldStyle(.plain)
                .focused($isMealNameFocused)
                .submitLabel(.done)
                .onSubmit { isMealNameFocused = false }
            
            Spacer()
            
            quantityControl
        }
        .padding(.horizontal, 20)
    }
    
    private var bookmarkButton: some View {
        Button(action: {
            if !isBookmarked {
                isBookmarked = true
                addToSavedMeals()
                NotificationCenter.default.post(
                    name: .showHomeToast,
                    object: nil,
                    userInfo: ["message": "保存済みに追加しました", "color": Color.green]
                )
            }
        }) {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                .foregroundColor(isBookmarked ? .orange : Color(UIColor.systemGray))
                .font(.system(size: 24))
        }
    }
    
    private var quantityControl: some View {
        HStack(spacing: 16) {
            Button(action: { if quantity > 1 { quantity -= 1 } }) {
                Image(systemName: "minus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Text("\(quantity)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 24)
            
            Button(action: { quantity += 1 }) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(UIColor.tertiarySystemFill))
        .cornerRadius(20)
    }
    
    // MARK: - カロリーカードセクション
    private var calorieCardSection: some View {
        ZStack(alignment: .topTrailing) {
            calorieCardContent
            dateButton
        }
        .padding(.horizontal, 20)
    }
    
    private var calorieCardContent: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: "flame.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.orange)
            }
            
            TappableCalorieField(
                value: $editedCalories,
                quantity: quantity,
                isEditing: editingField == .calories,
                onTap: { editingField = .calories },
                onSubmit: { editingField = nil }
            )
            .focused($focusedField, equals: .calories)
            
            Spacer()
        }
        .padding(18)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var dateButton: some View {
        Button(action: { showDatePicker = true }) {
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                Text(formatDateTime(selectedDate))
                    .font(.system(size: 13))
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(UIColor.tertiarySystemFill))
            .cornerRadius(8)
            .padding(12)
        }
    }
    
    // MARK: - 栄養素グリッド（上段）
    private var nutrientGridUpperSection: some View {
        HStack(spacing: 10) {
            TappableNutrientCard(icon: "🍖", name: "たんぱく質", value: $editedProtein, unit: "g", quantity: quantity, isEditing: editingField == .protein, onTap: { editingField = .protein }, onSubmit: { editingField = nil })
                .focused($focusedField, equals: .protein)
            
            TappableNutrientCard(icon: "🥑", name: "脂質", value: $editedFat, unit: "g", quantity: quantity, isEditing: editingField == .fat, onTap: { editingField = .fat }, onSubmit: { editingField = nil })
                .focused($focusedField, equals: .fat)
            
            TappableNutrientCard(icon: "🍚", name: "炭水化物", value: $editedCarbs, unit: "g", quantity: quantity, isEditing: editingField == .carbs, onTap: { editingField = .carbs }, onSubmit: { editingField = nil })
                .focused($focusedField, equals: .carbs)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - 栄養素グリッド（下段）
    private var nutrientGridLowerSection: some View {
        HStack(spacing: 10) {
            TappableNutrientCard(icon: "🍬", name: "糖分", value: $editedSugar, unit: "g", quantity: quantity, isEditing: editingField == .sugar, onTap: { editingField = .sugar }, onSubmit: { editingField = nil })
                .focused($focusedField, equals: .sugar)
            
            TappableNutrientCard(icon: "🌾", name: "食物繊維", value: $editedFiber, unit: "g", quantity: quantity, isEditing: editingField == .fiber, onTap: { editingField = .fiber }, onSubmit: { editingField = nil })
                .focused($focusedField, equals: .fiber)
            
            TappableNutrientCard(icon: "🧂", name: "ナトリウム", value: $editedSodium, unit: "mg", quantity: quantity, isEditing: editingField == .sodium, onTap: { editingField = .sodium }, onSubmit: { editingField = nil })
                .focused($focusedField, equals: .sodium)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - 編集ヒント
    private var editHintSection: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Text("数値をタップして編集できます")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.top, 0)
    }
    
    // MARK: - 下部ボタンセクション
    private var bottomButtonsSection: some View {
        HStack(spacing: 12) {
            // ✅ 保存済みからの遷移でない場合のみ左側ボタンを表示
            if !isFromSavedMeals {
                leftActionButton
            }
            saveButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
    }
    
    @ViewBuilder
    private var leftActionButton: some View {
        if isFromLog {
            // ✅ 食事ログからの遷移時のみ削除ボタンを表示
            secondaryButton(icon: "trash", title: "削除") {
                if let logId = existingLogId {
                    MealLogsManager.shared.removeLog(id: logId)
                    NotificationCenter.default.post(
                        name: .showHomeToast,
                        object: nil,
                        userInfo: ["message": "食事を削除しました", "color": Color.orange]
                    )
                }
                dismiss()
            }
        } else if isFromManualEntry {
            secondaryButton(icon: "pencil", title: "再入力") {
                NotificationCenter.default.post(name: .returnToManualEntry, object: nil)
                dismiss()
            }
        } else {
            secondaryButton(icon: "camera", title: "再撮影") {
                showCamera = true
            }
        }
    }
    
    private func secondaryButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(25)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color(UIColor.systemGray3), lineWidth: 1)
            )
        }
    }
    
    private var saveButton: some View {
        Button(action: { saveToHome() }) {
            Text(getSaveButtonTitle())
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.orange)
                .cornerRadius(25)
        }
    }
    
    // ✅ 保存ボタンのタイトルを取得
    private func getSaveButtonTitle() -> String {
        if isFromSavedMeals {
            return "今日の食事として記録"
        } else if isEditMode {
            return "更新"
        } else if isFromLog {
            return "今日の食事として記録"
        } else {
            return "保存"
        }
    }
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
        
        ToolbarItem(placement: .keyboard) {
            HStack {
                Spacer()
                Button("完了") {
                    editingField = nil
                    focusedField = nil
                    isMealNameFocused = false
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadOriginalData() {
        if result.foodItems.count == 1 {
            editedMealName = result.foodItems.first?.name ?? "食事"
        } else {
            editedMealName = result.foodItems.map { $0.name }.joined(separator: "と")
        }
        
        editedCalories = result.totalCalories
        editedProtein = result.totalProtein
        editedFat = result.totalFat
        editedCarbs = result.totalCarbs
        editedSugar = result.totalSugar
        editedFiber = result.totalFiber
        editedSodium = result.totalSodium
        
        currentImage = capturedImage
        
        if let existingDate = existingLogDate {
            selectedDate = existingDate
        }
        
        // ✅ まずresult.characterCommentを初期値として設定
        if !result.characterComment.isEmpty {
            characterComment = result.characterComment
        }
        
        // ✅ 既存のログから数量とコメントを復元
        if let logId = existingLogId,
           let existingLog = MealLogsManager.shared.getLog(by: logId) {
            quantity = existingLog.quantity
            
            // ✅ 保存されたコメントがあれば復元（優先）
            if !existingLog.characterComment.isEmpty {
                characterComment = existingLog.characterComment
            }
            
            // 1個あたりの値に戻す
            if existingLog.quantity > 1 {
                editedCalories = existingLog.calories
                editedProtein = Double(existingLog.protein)
                editedFat = Double(existingLog.fat)
                editedCarbs = Double(existingLog.carbs)
                editedSugar = Double(existingLog.sugar)
                editedFiber = Double(existingLog.fiber)
                editedSodium = Double(existingLog.sodium)
            }
        }
        
        if isEditMode {
            checkIfAlreadySaved()
        } else {
            isBookmarked = false
            // ✅ コメントがまだない場合のみAIに取得させる
            if characterComment.isEmpty {
                fetchCharacterComment()
            }
        }
    }
    
    // ✅ AIにコメントを生成させる
    private func fetchCharacterComment() {
        // 既にコメントがある場合はスキップ
        guard characterComment.isEmpty else { return }
        
        isLoadingComment = true
        
        Task {
            do {
                let comment = try await NetworkManager.shared.fetchMealComment(
                    mealName: getMealName(),
                    calories: editedCalories,
                    protein: editedProtein,
                    fat: editedFat,
                    carbs: editedCarbs,
                    sugar: editedSugar,
                    fiber: editedFiber,
                    sodium: editedSodium
                )
                await MainActor.run {
                    characterComment = comment
                    isLoadingComment = false
                }
            } catch {
                await MainActor.run {
                    characterComment = "美味しそうだにゃ！🐱"
                    isLoadingComment = false
                }
            }
        }
    }
    
    private func checkIfAlreadySaved() {
        let mealName = getMealName()
        isBookmarked = SavedMealsManager.shared.savedMeals.contains { $0.name == mealName }
    }
    
    private func saveToHome() {
        // ✅ コメントを決定（空の場合はデフォルト）
        let finalComment: String
        if !characterComment.isEmpty {
            finalComment = characterComment
        } else if !result.characterComment.isEmpty {
            finalComment = result.characterComment
        } else {
            finalComment = "美味しそうだにゃ！🐱"
        }
        
        // ✅ 保存済みからの遷移の場合は新規ログとして追加
        let logId: UUID
        if isFromSavedMeals {
            logId = UUID()  // 新しいIDを生成
        } else {
            logId = existingLogId ?? UUID()
        }
        
        // ✅ 1個あたりの値を保存（quantityは別で保存）
        let mealLog = MealLogEntry(
            id: logId,
            name: getMealName(),
            calories: editedCalories,
            protein: Int(editedProtein),
            fat: Int(editedFat),
            carbs: Int(editedCarbs),
            sugar: Int(editedSugar),
            fiber: Int(editedFiber),
            sodium: Int(editedSodium),
            emoji: selectEmoji(),
            date: selectedDate,
            time: selectedDate,
            image: currentImage?.jpegData(compressionQuality: 0.7),
            quantity: quantity,
            characterComment: finalComment  // ✅ コメントを確実に保存
        )
        
        // ✅ 保存済みからの遷移または新規の場合は追加、それ以外は更新
        if isFromSavedMeals || !isEditMode {
            MealLogsManager.shared.addLog(mealLog)
        } else {
            MealLogsManager.shared.updateLog(mealLog)
        }
        
        let message = "\(getMealName())を\(isEditMode && !isFromSavedMeals ? "更新" : "記録")しました"
        NotificationCenter.default.post(
            name: .showHomeToast,
            object: nil,
            userInfo: ["message": message, "color": Color.green]
        )
        
        NotificationCenter.default.post(name: .dismissAllMealScreens, object: nil)
        dismiss()
    }
    
    private func addToSavedMeals() {
        let mealName = getMealName()
        let savedMeal = SavedMeal(
            name: mealName,
            calories: editedCalories * quantity,
            protein: editedProtein * Double(quantity),
            fat: editedFat * Double(quantity),
            carbs: editedCarbs * Double(quantity),
            sugar: editedSugar * Double(quantity),
            fiber: editedFiber * Double(quantity),
            sodium: editedSodium * Double(quantity),
            emoji: selectEmoji(),
            imageData: currentImage?.jpegData(compressionQuality: 0.7)
        )
        SavedMealsManager.shared.addMeal(savedMeal)
    }
    
    private func selectEmoji() -> String {
        let name = getMealName().lowercased()
        if name.contains("ラーメン") || name.contains("麺") { return "🍜" }
        if name.contains("ご飯") || name.contains("米") || name.contains("丼") { return "🍚" }
        if name.contains("パン") { return "🍞" }
        if name.contains("サラダ") { return "🥗" }
        if name.contains("肉") || name.contains("ステーキ") { return "🥩" }
        if name.contains("魚") || name.contains("寿司") { return "🍣" }
        if name.contains("卵") { return "🍳" }
        if name.contains("カレー") { return "🍛" }
        if name.contains("ピザ") { return "🍕" }
        if name.contains("ハンバーガー") { return "🍔" }
        if name.contains("パスタ") { return "🍝" }
        return "🍽️"
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "今日 HH:mm"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "昨日 HH:mm"
        } else {
            formatter.dateFormat = "M/d HH:mm"
        }
        return formatter.string(from: date)
    }
    
    private func getMealName() -> String {
        if editedMealName.isEmpty {
            if result.foodItems.count == 1 {
                return result.foodItems.first?.name ?? "食事"
            } else {
                return result.foodItems.map { $0.name }.joined(separator: "と")
            }
        }
        return editedMealName
    }
}

// MARK: - 吹き出し三角形
struct SpeechBubbleTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - タップで編集可能なカロリーフィールド
struct TappableCalorieField: View {
    @Binding var value: Int
    let quantity: Int
    let isEditing: Bool
    let onTap: () -> Void
    let onSubmit: () -> Void
    
    @State private var textValue: String = ""
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            if isEditing {
                TextField("0", text: $textValue)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                    .keyboardType(.numberPad)
                    .frame(width: 100)
                    .multilineTextAlignment(.center)
                    .padding(8)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)
                    .onAppear { textValue = String(value) }
                    .onChange(of: textValue) { oldValue, newValue in
                        if let intValue = Int(newValue) { value = intValue }
                    }
            } else {
                Text("\(value * quantity)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.primary)
                    .onTapGesture { onTap() }
            }
            Text("kcal")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
        }
    }
}

// MARK: - タップで編集可能な栄養素カード
struct TappableNutrientCard: View {
    let icon: String
    let name: String
    @Binding var value: Double
    let unit: String
    let quantity: Int
    let isEditing: Bool
    let onTap: () -> Void
    let onSubmit: () -> Void
    
    @State private var textValue: String = ""
    
    var body: some View {
        VStack(spacing: 6) {
            headerView
            valueView
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    private var headerView: some View {
        HStack(spacing: 4) {
            Text(icon).font(.system(size: 16))
            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var valueView: some View {
        if isEditing {
            HStack(spacing: 2) {
                TextField("0", text: $textValue)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 50)
                    .padding(6)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(6)
                    .onAppear { textValue = formatValue(value) }
                    .onChange(of: textValue) { oldValue, newValue in
                        if let doubleValue = Double(newValue) { value = doubleValue }
                    }
                Text(unit)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        } else {
            Text(formatValue(value * Double(quantity)) + unit)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .onTapGesture { onTap() }
        }
    }
    
    private func formatValue(_ value: Double) -> String {
        if value >= 100 { return String(format: "%.0f", value) }
        else if value >= 10 { return String(format: "%.0f", value) }
        else { return String(format: "%.1f", value) }
    }
}

// MARK: - 食事日付選択シート
struct MealDatePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedDate: Date
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("記録日時", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .environment(\.locale, Locale(identifier: "ja_JP"))
                    .padding()
                Spacer()
            }
            .navigationTitle("日時を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
