import Foundation
import UserNotifications
import Combine
import UIKit
/// ローカル通知を管理するシングルトンクラス
/// 食事リマインダーと体重記録リマインダーに対応
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Published Properties
    @Published var isAuthorized: Bool = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    // MARK: - UserDefaults Keys
    private let mealReminderEnabledKey = "mealReminderEnabled"
    private let mealReminderTimesKey = "mealReminderTimes"
    private let weightReminderEnabledKey = "weightReminderEnabled"
    private let weightReminderTimeKey = "weightReminderTime"
    
    // MARK: - Notification Identifiers
    private let mealReminderPrefix = "caloken.meal.reminder."
    private let weightReminderIdentifier = "caloken.weight.reminder"
    
    // MARK: - Settings
    @Published var mealReminderEnabled: Bool {
        didSet {
            UserDefaults.standard.set(mealReminderEnabled, forKey: mealReminderEnabledKey)
            Task { await updateMealReminders() }
        }
    }
    
    @Published var mealReminderTimes: [Date] {
        didSet {
            saveMealReminderTimes()
            Task { await updateMealReminders() }
        }
    }
    
    @Published var weightReminderEnabled: Bool {
        didSet {
            UserDefaults.standard.set(weightReminderEnabled, forKey: weightReminderEnabledKey)
            Task { await updateWeightReminder() }
        }
    }
    
    @Published var weightReminderTime: Date {
        didSet {
            saveWeightReminderTime()
            Task { await updateWeightReminder() }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // UserDefaultsから設定を読み込み
        self.mealReminderEnabled = UserDefaults.standard.bool(forKey: mealReminderEnabledKey)
        self.weightReminderEnabled = UserDefaults.standard.bool(forKey: weightReminderEnabledKey)
        
        // 食事リマインダー時間を読み込み（デフォルト: 8:00, 12:00, 20:00）
        if let data = UserDefaults.standard.data(forKey: mealReminderTimesKey),
           let times = try? JSONDecoder().decode([Date].self, from: data) {
            self.mealReminderTimes = times
        } else {
            self.mealReminderTimes = Self.defaultMealTimes()
        }
        
        // 体重リマインダー時間を読み込み（デフォルト: 7:00）
        if let timeInterval = UserDefaults.standard.object(forKey: weightReminderTimeKey) as? TimeInterval {
            self.weightReminderTime = Date(timeIntervalSince1970: timeInterval)
        } else {
            self.weightReminderTime = Self.defaultWeightTime()
        }
        
        // 初回起動時はデフォルトでON
        if !UserDefaults.standard.bool(forKey: "notificationSettingsInitialized") {
            self.mealReminderEnabled = true
            self.weightReminderEnabled = true
            UserDefaults.standard.set(true, forKey: "notificationSettingsInitialized")
        }
        
        checkAuthorizationStatus()
    }
    
    // MARK: - Default Values
    
    private static func defaultMealTimes() -> [Date] {
        let calendar = Calendar.current
        return [
            calendar.date(from: DateComponents(hour: 8, minute: 0)) ?? Date(),
            calendar.date(from: DateComponents(hour: 12, minute: 0)) ?? Date(),
            calendar.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
        ]
    }
    
    private static func defaultWeightTime() -> Date {
        Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    }
    
    // MARK: - Persistence
    
    private func saveMealReminderTimes() {
        if let data = try? JSONEncoder().encode(mealReminderTimes) {
            UserDefaults.standard.set(data, forKey: mealReminderTimesKey)
        }
    }
    
    private func saveWeightReminderTime() {
        UserDefaults.standard.set(weightReminderTime.timeIntervalSince1970, forKey: weightReminderTimeKey)
    }
    
    // MARK: - Authorization
    
    /// 通知の許可状態を確認
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// 通知の許可をリクエスト
    func requestAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        let granted = try await notificationCenter.requestAuthorization(options: options)
        
        await MainActor.run {
            self.isAuthorized = granted
            self.authorizationStatus = granted ? .authorized : .denied
        }
        
        if granted {
            // 許可が得られたらリマインダーを設定
            await updateMealReminders()
            await updateWeightReminder()
        }
        
        return granted
    }
    
    /// 設定アプリの通知設定を開く
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Meal Reminders
    
    /// 食事リマインダーを更新
    func updateMealReminders() async {
        // 既存の食事リマインダーを削除
        await removeAllMealReminders()
        
        guard mealReminderEnabled && isAuthorized else { return }
        
        for (index, time) in mealReminderTimes.enumerated() {
            await scheduleMealReminder(at: time, index: index)
        }
    }
    
    /// 食事リマインダーをスケジュール
    private func scheduleMealReminder(at time: Date, index: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "🍽️ 食事記録の時間です"
        content.body = "今日の食事を記録しましょう！カロ研で簡単に記録できます。"
        content.sound = .default
        content.badge = 1
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let identifier = "\(mealReminderPrefix)\(index)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            print("Scheduled meal reminder \(index) at \(components.hour ?? 0):\(components.minute ?? 0)")
        } catch {
            print("Failed to schedule meal reminder: \(error)")
        }
    }
    
    /// すべての食事リマインダーを削除
    private func removeAllMealReminders() async {
        let identifiers = (0..<5).map { "\(mealReminderPrefix)\($0)" }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    /// 食事リマインダー時間を追加
    func addMealReminderTime(_ time: Date) {
        guard mealReminderTimes.count < 5 else { return }
        mealReminderTimes.append(time)
    }
    
    /// 食事リマインダー時間を削除
    func removeMealReminderTime(at index: Int) {
        guard mealReminderTimes.count > 1, mealReminderTimes.indices.contains(index) else { return }
        mealReminderTimes.remove(at: index)
    }
    
    // MARK: - Weight Reminder
    
    /// 体重リマインダーを更新
    func updateWeightReminder() async {
        // 既存の体重リマインダーを削除
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [weightReminderIdentifier])
        
        guard weightReminderEnabled && isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "⚖️ 体重記録の時間です"
        content.body = "毎日の体重を記録して、健康管理を続けましょう！"
        content.sound = .default
        content.badge = 1
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: weightReminderTime)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: weightReminderIdentifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("Scheduled weight reminder at \(components.hour ?? 0):\(components.minute ?? 0)")
        } catch {
            print("Failed to schedule weight reminder: \(error)")
        }
    }
    
    // MARK: - Utility
    
    /// すべての通知を削除
    func removeAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    /// バッジをクリア
    func clearBadge() {
        Task { @MainActor in
            UNUserNotificationCenter.current().setBadgeCount(0)
        }
    }
    
    /// 予定されている通知をデバッグ出力
    func debugPrintPendingNotifications() {
        notificationCenter.getPendingNotificationRequests { requests in
            print("=== Pending Notifications ===")
            for request in requests {
                print("ID: \(request.identifier)")
                if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                    print("  Time: \(trigger.dateComponents)")
                }
            }
            print("=============================")
        }
    }
}
