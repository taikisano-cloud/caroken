import SwiftUI

struct S27_2_ProfileEditView: View {
    @ObservedObject private var profileManager = UserProfileManager.shared
    @ObservedObject private var weightLogsManager = WeightLogsManager.shared
    
    @Environment(\.dismiss) private var dismiss
    
    // 編集用シート表示フラグ
    @State private var showHeightPicker: Bool = false
    @State private var showWeightPicker: Bool = false
    @State private var showGenderPicker: Bool = false
    @State private var showDatePicker: Bool = false
    
    
    // ローカル編集値
    @State private var editHeight: Int = 170
    @State private var editWeight: Double = 65.0
    @State private var editGender: String = "未設定"
    @State private var editBirthDate: Date = Date()
    // 編集用シート表示フラグに追加
    @State private var showNameEditor: Bool = false

    // ローカル編集値に追加
    @State private var editName: String = ""
    
    
    // 性別の表示名
    private func genderDisplayName(_ gender: String) -> String {
        switch gender {
        case "Male": return "男性"
        case "Female": return "女性"
        case "Other": return "その他"
        default: return "未設定"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 身長
                ProfileEditRow(
                    label: "身長",
                    value: "\(Int(profileManager.height)) cm"
                ) {
                    editHeight = Int(profileManager.height)
                    showHeightPicker = true
                }
                
                // 体重
                ProfileEditRow(
                    label: "体重",
                    value: String(format: "%.1f kg", weightLogsManager.currentWeight)
                ) {
                    editWeight = weightLogsManager.currentWeight
                    showWeightPicker = true
                }
                
                // 性別
                ProfileEditRow(
                    label: "性別",
                    value: genderDisplayName(profileManager.gender)
                ) {
                    editGender = profileManager.gender
                    showGenderPicker = true
                }
                
                // 生年月日
                ProfileEditRow(
                    label: "生年月日",
                    value: formatDate(profileManager.birthDate)
                ) {
                    editBirthDate = profileManager.birthDate
                    showDatePicker = true
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .background(Color(UIColor.systemBackground))
        .navigationTitle("プロフィール編集")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
        }
        // 身長ピッカー
        .sheet(isPresented: $showHeightPicker) {
            HeightPickerSheet(height: $editHeight, onSave: {
                profileManager.height = Double(editHeight)
                profileManager.saveProfile()
            })
            .presentationDetents([.height(300)])
        }
        // 体重ピッカー
        .sheet(isPresented: $showWeightPicker) {
            WeightPickerSheetDouble(weight: $editWeight, onSave: {
                weightLogsManager.addLog(editWeight)
            })
            .presentationDetents([.height(300)])
        }
        // 性別ピッカー
        .sheet(isPresented: $showGenderPicker) {
            GenderPickerSheet(gender: $editGender, onSave: {
                profileManager.gender = editGender
                profileManager.saveProfile()
            })
            .presentationDetents([.height(300)])
        }
        // 生年月日ピッカー
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(date: $editBirthDate, onSave: {
                profileManager.birthDate = editBirthDate
                profileManager.saveProfile()
            })
            .presentationDetents([.height(350)])
        }
        // 名前編集シート
        .sheet(isPresented: $showNameEditor) {
            NameEditorSheet(name: $editName, onSave: {
                profileManager.name = editName
                profileManager.saveProfile()
            })
            .presentationDetents([.height(200)])
        }
        .enableSwipeBack()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年 M月 d日"
        return formatter.string(from: date)
    }
}

// MARK: - プロフィール編集行
struct ProfileEditRow: View {
    let label: String
    let value: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - 身長ピッカーシート
struct HeightPickerSheet: View {
    @Binding var height: Int
    var onSave: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("身長", selection: $height) {
                    ForEach(100...250, id: \.self) { h in
                        Text("\(h) cm").tag(h)
                    }
                }
                .pickerStyle(.wheel)
            }
            .navigationTitle("身長")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 体重ピッカーシート（Double対応）
struct WeightPickerSheetDouble: View {
    @Binding var weight: Double
    var onSave: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    
    @State private var weightWhole: Int = 70
    @State private var weightDecimal: Int = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack(spacing: 0) {
                    Picker("整数部", selection: $weightWhole) {
                        ForEach(30..<201) { w in
                            Text("\(w)").tag(w)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80)
                    .clipped()
                    
                    Text(".")
                        .font(.system(size: 20, weight: .bold))
                    
                    Picker("小数部", selection: $weightDecimal) {
                        ForEach(0..<10) { d in
                            Text("\(d)").tag(d)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 60)
                    .clipped()
                    
                    Text("kg")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("体重")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        weight = Double(weightWhole) + Double(weightDecimal) / 10.0
                        onSave()
                        dismiss()
                    }
                }
            }
            .onAppear {
                weightWhole = Int(weight)
                weightDecimal = Int((weight - Double(Int(weight))) * 10)
            }
        }
    }
}

// MARK: - 体重ピッカーシート（Int用 - 互換性のため残す）
struct WeightPickerSheet: View {
    @Binding var weight: Int
    var onSave: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("体重", selection: $weight) {
                    ForEach(30...200, id: \.self) { w in
                        Text("\(w) kg").tag(w)
                    }
                }
                .pickerStyle(.wheel)
            }
            .navigationTitle("体重")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 性別ピッカーシート（その他追加）
struct GenderPickerSheet: View {
    @Binding var gender: String
    var onSave: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Button {
                    gender = "Male"
                    onSave()
                    dismiss()
                } label: {
                    HStack {
                        Text("男性")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                        Spacer()
                        if gender == "Male" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                }
                
                Button {
                    gender = "Female"
                    onSave()
                    dismiss()
                } label: {
                    HStack {
                        Text("女性")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                        Spacer()
                        if gender == "Female" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                }
                
                Button {
                    gender = "Other"
                    onSave()
                    dismiss()
                } label: {
                    HStack {
                        Text("その他")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                        Spacer()
                        if gender == "Other" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("性別")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 生年月日ピッカーシート
struct DatePickerSheet: View {
    @Binding var date: Date
    var onSave: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "生年月日",
                    selection: $date,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "ja_JP"))
            }
            .navigationTitle("生年月日")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}
// MARK: - 名前編集シート
struct NameEditorSheet: View {
    @Binding var name: String
    var onSave: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("名前を入力", text: $name)
                    .font(.system(size: 18))
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    .focused($isFocused)
                
                Text("カロちゃんがこの名前で呼びかけます")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("名前")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        onSave()
                        dismiss()
                    }
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }
}
#Preview {
    NavigationStack {
        S27_2_ProfileEditView()
    }
}
