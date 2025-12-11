import Foundation
import HealthKit
import Combine

/// HealthKit連携を管理するシングルトンクラス
/// 体重、歩数、アクティブカロリー、栄養データの読み書きに対応
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    
    // MARK: - Published Properties
    @Published var isAuthorized: Bool = false
    @Published var todaySteps: Int = 0
    @Published var todayActiveCalories: Double = 0
    @Published var latestWeight: Double? = nil
    
    // MARK: - HealthKit Types
    
    /// 読み取りを許可するデータタイプ
    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        
        // 身体測定
        if let weight = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            types.insert(weight)
        }
        if let height = HKQuantityType.quantityType(forIdentifier: .height) {
            types.insert(height)
        }
        
        // アクティビティ
        if let steps = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            types.insert(steps)
        }
        if let activeEnergy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergy)
        }
        
        // 栄養
        if let calories = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            types.insert(calories)
        }
        if let protein = HKQuantityType.quantityType(forIdentifier: .dietaryProtein) {
            types.insert(protein)
        }
        if let carbs = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates) {
            types.insert(carbs)
        }
        if let fat = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal) {
            types.insert(fat)
        }
        
        return types
    }
    
    /// 書き込みを許可するデータタイプ
    private var writeTypes: Set<HKSampleType> {
        var types: Set<HKSampleType> = []
        
        // 身体測定
        if let weight = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            types.insert(weight)
        }
        
        // 栄養データ
        if let calories = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            types.insert(calories)
        }
        if let protein = HKQuantityType.quantityType(forIdentifier: .dietaryProtein) {
            types.insert(protein)
        }
        if let carbs = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates) {
            types.insert(carbs)
        }
        if let fat = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal) {
            types.insert(fat)
        }
        
        return types
    }
    
    // MARK: - Initialization
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// HealthKitが利用可能かチェック
    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    /// 認証状態をチェック
    func checkAuthorizationStatus() {
        guard isHealthDataAvailable else {
            isAuthorized = false
            return
        }
        
        // 体重の認証状態をチェック（代表として）
        if let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            let status = healthStore.authorizationStatus(for: weightType)
            DispatchQueue.main.async {
                self.isAuthorized = (status == .sharingAuthorized)
            }
        }
    }
    
    /// HealthKitへのアクセス許可をリクエスト
    func requestAuthorization() async throws {
        guard isHealthDataAvailable else {
            throw HealthKitError.notAvailable
        }
        
        try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
        
        await MainActor.run {
            self.isAuthorized = true
        }
        
        // 初回データ取得
        await fetchTodayData()
    }
    
    // MARK: - Fetch Data
    
    /// 今日のデータを一括取得
    func fetchTodayData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchTodaySteps() }
            group.addTask { await self.fetchTodayActiveCalories() }
            group.addTask { await self.fetchLatestWeight() }
        }
    }
    
    /// 今日の歩数を取得
    func fetchTodaySteps() async {
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        do {
            let steps = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: stepsType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    let sum = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    continuation.resume(returning: Int(sum))
                }
                
                healthStore.execute(query)
            }
            
            await MainActor.run {
                self.todaySteps = steps
            }
        } catch {
            print("Failed to fetch steps: \(error)")
        }
    }
    
    /// 今日のアクティブカロリーを取得
    func fetchTodayActiveCalories() async {
        guard let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        do {
            let calories = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: caloriesType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    let sum = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                    continuation.resume(returning: sum)
                }
                
                healthStore.execute(query)
            }
            
            await MainActor.run {
                self.todayActiveCalories = calories
            }
        } catch {
            print("Failed to fetch active calories: \(error)")
        }
    }
    
    /// 最新の体重を取得
    func fetchLatestWeight() async {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        do {
            let weight = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double?, Error>) in
                let query = HKSampleQuery(
                    sampleType: weightType,
                    predicate: nil,
                    limit: 1,
                    sortDescriptors: [sortDescriptor]
                ) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let sample = samples?.first as? HKQuantitySample else {
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    let kg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                    continuation.resume(returning: kg)
                }
                
                healthStore.execute(query)
            }
            
            await MainActor.run {
                self.latestWeight = weight
            }
        } catch {
            print("Failed to fetch weight: \(error)")
        }
    }
    
    // MARK: - Save Data
    
    /// 体重を保存
    func saveWeight(_ kg: Double, date: Date = Date()) async throws {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitError.typeNotAvailable
        }
        
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg)
        let sample = HKQuantitySample(
            type: weightType,
            quantity: quantity,
            start: date,
            end: date
        )
        
        try await healthStore.save(sample)
        
        // 最新の体重を更新
        await MainActor.run {
            self.latestWeight = kg
        }
    }
    
    /// 栄養データを保存（食事記録時）
    func saveNutrition(
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        date: Date = Date()
    ) async throws {
        var samples: [HKQuantitySample] = []
        
        // カロリー
        if let caloriesType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
            samples.append(HKQuantitySample(type: caloriesType, quantity: quantity, start: date, end: date))
        }
        
        // タンパク質
        if let proteinType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein) {
            let quantity = HKQuantity(unit: .gram(), doubleValue: protein)
            samples.append(HKQuantitySample(type: proteinType, quantity: quantity, start: date, end: date))
        }
        
        // 炭水化物
        if let carbsType = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates) {
            let quantity = HKQuantity(unit: .gram(), doubleValue: carbs)
            samples.append(HKQuantitySample(type: carbsType, quantity: quantity, start: date, end: date))
        }
        
        // 脂質
        if let fatType = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal) {
            let quantity = HKQuantity(unit: .gram(), doubleValue: fat)
            samples.append(HKQuantitySample(type: fatType, quantity: quantity, start: date, end: date))
        }
        
        try await healthStore.save(samples)
    }
    
    // MARK: - Background Delivery (Optional)
    
    /// バックグラウンド更新を有効化（歩数の変化を監視）
    func enableBackgroundDelivery() {
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        healthStore.enableBackgroundDelivery(for: stepsType, frequency: .hourly) { success, error in
            if let error = error {
                print("Background delivery error: \(error)")
            }
        }
    }
}

// MARK: - Error Types

enum HealthKitError: LocalizedError {
    case notAvailable
    case typeNotAvailable
    case authorizationDenied
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "このデバイスではHealthKitを利用できません"
        case .typeNotAvailable:
            return "指定されたデータタイプが利用できません"
        case .authorizationDenied:
            return "HealthKitへのアクセスが拒否されました"
        }
    }
}
