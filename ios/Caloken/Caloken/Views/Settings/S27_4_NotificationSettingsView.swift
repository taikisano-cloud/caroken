import SwiftUI

struct S27_4_NotificationSettingsView: View {
    @State private var mealReminderEnabled: Bool = true
    @State private var mealReminderTimes: [Date] = [
        Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date(),
        Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date(),
        Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
    ]
    
    @State private var weightReminderEnabled: Bool = true
    @State private var weightReminderTime: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    
    @State private var weeklyReport: Bool = false
    
    var body: some View {
        Form {
            // 食事リマインダー
            Section {
                Toggle("食事記録リマインダー", isOn: $mealReminderEnabled)
                
                if mealReminderEnabled {
                    ForEach(mealReminderTimes.indices, id: \.self) { index in
                        HStack {
                            Text("通知時間 \(index + 1)")
                            Spacer()
                            DatePicker(
                                "",
                                selection: $mealReminderTimes[index],
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            
                            // 削除ボタン（2つ以上ある場合のみ）
                            if mealReminderTimes.count > 1 {
                                Button {
                                    mealReminderTimes.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    
                    // 通知時間追加ボタン（最大5つまで）
                    if mealReminderTimes.count < 5 {
                        Button {
                            let newTime = Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()
                            mealReminderTimes.append(newTime)
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                                Text("通知時間を追加")
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            } header: {
                Text("食事リマインダー")
            } footer: {
                Text("指定した時間に食事記録のリマインダーを送信します（最大5回まで）")
            }
            
            // 体重リマインダー
            Section {
                Toggle("体重記録リマインダー", isOn: $weightReminderEnabled)
                
                if weightReminderEnabled {
                    DatePicker(
                        "通知時間",
                        selection: $weightReminderTime,
                        displayedComponents: .hourAndMinute
                    )
                }
            } header: {
                Text("体重リマインダー")
            } footer: {
                Text("毎日指定した時間に体重記録のリマインダーを送信します")
            }
            
            // 週間レポート
            Section {
                Toggle("週間レポート", isOn: $weeklyReport)
            } header: {
                Text("レポート")
            } footer: {
                Text("毎週月曜日に1週間の振り返りレポートを送信します")
            }
        }
        .navigationTitle("通知設定")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        S27_4_NotificationSettingsView()
    }
}
