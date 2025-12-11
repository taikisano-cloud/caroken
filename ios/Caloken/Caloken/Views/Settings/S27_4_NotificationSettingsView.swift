import SwiftUI

struct S27_4_NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showPermissionAlert: Bool = false
    
    var body: some View {
        Form {
            // 通知許可セクション
            if notificationManager.authorizationStatus == .denied {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("通知が無効になっています")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Button("設定で通知を有効にする") {
                        notificationManager.openSettings()
                    }
                    .foregroundColor(.blue)
                } footer: {
                    Text("リマインダーを受け取るには、設定アプリで通知を有効にしてください。")
                }
            } else if notificationManager.authorizationStatus == .notDetermined {
                Section {
                    Button("通知を有効にする") {
                        requestNotificationPermission()
                    }
                    .foregroundColor(.blue)
                } footer: {
                    Text("リマインダーを受け取るには、通知を有効にしてください。")
                }
            }
            
            // 食事リマインダー
            Section {
                Toggle("食事記録リマインダー", isOn: Binding(
                    get: { notificationManager.mealReminderEnabled },
                    set: { newValue in
                        if newValue && notificationManager.authorizationStatus != .authorized {
                            showPermissionAlert = true
                        } else {
                            notificationManager.mealReminderEnabled = newValue
                        }
                    }
                ))
                
                if notificationManager.mealReminderEnabled {
                    ForEach(notificationManager.mealReminderTimes.indices, id: \.self) { index in
                        HStack {
                            Text(mealLabel(for: index))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { notificationManager.mealReminderTimes[index] },
                                    set: { newValue in
                                        var times = notificationManager.mealReminderTimes
                                        times[index] = newValue
                                        notificationManager.mealReminderTimes = times
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            
                            // 削除ボタン（2つ以上ある場合のみ）
                            if notificationManager.mealReminderTimes.count > 1 {
                                Button {
                                    withAnimation {
                                        notificationManager.removeMealReminderTime(at: index)
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // 通知時間追加ボタン（最大5つまで）
                    if notificationManager.mealReminderTimes.count < 5 {
                        Button {
                            withAnimation {
                                let newTime = Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()
                                notificationManager.addMealReminderTime(newTime)
                            }
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
                Toggle("体重記録リマインダー", isOn: Binding(
                    get: { notificationManager.weightReminderEnabled },
                    set: { newValue in
                        if newValue && notificationManager.authorizationStatus != .authorized {
                            showPermissionAlert = true
                        } else {
                            notificationManager.weightReminderEnabled = newValue
                        }
                    }
                ))
                
                if notificationManager.weightReminderEnabled {
                    DatePicker(
                        "通知時間",
                        selection: Binding(
                            get: { notificationManager.weightReminderTime },
                            set: { notificationManager.weightReminderTime = $0 }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                }
            } header: {
                Text("体重リマインダー")
            } footer: {
                Text("毎日指定した時間に体重記録のリマインダーを送信します")
            }
            
            // デバッグセクション（開発中のみ）
            #if DEBUG
            Section {
                Button("予定された通知を確認") {
                    notificationManager.debugPrintPendingNotifications()
                }
                
                Button("テスト通知を送信（5秒後）") {
                    scheduleTestNotification()
                }
                
                Button("すべての通知をクリア") {
                    notificationManager.removeAllNotifications()
                }
                .foregroundColor(.red)
            } header: {
                Text("デバッグ")
            }
            #endif
        }
        .navigationTitle("通知設定")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            notificationManager.checkAuthorizationStatus()
        }
        .alert("通知の許可が必要です", isPresented: $showPermissionAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("設定を開く") {
                notificationManager.openSettings()
            }
        } message: {
            Text("リマインダーを設定するには、通知を有効にしてください。")
        }
    }
    
    // MARK: - Helper Methods
    
    private func mealLabel(for index: Int) -> String {
        switch index {
        case 0: return "朝食"
        case 1: return "昼食"
        case 2: return "夕食"
        default: return "通知 \(index + 1)"
        }
    }
    
    private func requestNotificationPermission() {
        Task {
            do {
                let granted = try await notificationManager.requestAuthorization()
                if !granted {
                    await MainActor.run {
                        showPermissionAlert = true
                    }
                }
            } catch {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    // MARK: - Debug Methods
    
    #if DEBUG
    private func scheduleTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🧪 テスト通知"
        content.body = "通知設定が正常に動作しています！"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "test", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Test notification error: \(error)")
            } else {
                print("Test notification scheduled!")
            }
        }
    }
    #endif
}

#Preview {
    NavigationStack {
        S27_4_NotificationSettingsView()
    }
}
