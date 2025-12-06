import SwiftUI

struct S38_ProgressView: View {
    @StateObject private var weightLogsManager = WeightLogsManager.shared
    @StateObject private var profileManager = UserProfileManager.shared
    @State private var selectedPeriod: ProgressPeriod = .week
    @State private var showAllMilestones: Bool = false
    @State private var showGoalEditor: Bool = false
    @State private var showBMIDetail: Bool = false
    
    private var daysRemaining: Int {
        weightLogsManager.daysRemaining
    }
    
    private var progressPercentage: Double {
        weightLogsManager.progressPercentage
    }
    
    // BMI計算（UserProfileManagerの身長を使用）
    private var bmi: Double {
        profileManager.bmi
    }
    
    private var bmiStatus: String {
        profileManager.bmiStatus
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    GoalCard(
                        currentWeight: weightLogsManager.currentWeight,
                        targetWeight: weightLogsManager.targetWeight,
                        targetDate: weightLogsManager.targetDate,
                        hasDeadline: weightLogsManager.hasDeadline
                    )
                    .onTapGesture {
                        showGoalEditor = true
                    }
                    
                    ProgressCard(
                        currentWeight: weightLogsManager.currentWeight,
                        startWeight: weightLogsManager.startWeight,
                        targetWeight: weightLogsManager.targetWeight,
                        daysRemaining: daysRemaining,
                        percentage: progressPercentage,
                        hasDeadline: weightLogsManager.hasDeadline
                    )
                    
                    MilestoneCardImproved(
                        startWeight: weightLogsManager.startWeight,
                        targetWeight: weightLogsManager.targetWeight,
                        currentWeight: weightLogsManager.currentWeight,
                        targetDate: weightLogsManager.targetDate,
                        showAll: $showAllMilestones,
                        hasDeadline: weightLogsManager.hasDeadline,
                        onSetDeadline: {
                            showGoalEditor = true
                        }
                    )
                    
                    PeriodSelector(selectedPeriod: $selectedPeriod)
                        .padding(.top, 8)
                    
                    SwipeableCalorieBarChartCard(selectedPeriod: $selectedPeriod)
                    
                    SwipeableWeightChartCard(selectedPeriod: $selectedPeriod)
                    
                    BMICard(bmi: bmi, status: bmiStatus) {
                        showBMIDetail = true
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("進捗")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showGoalEditor) {
                GoalEditorSheet(
                    currentWeight: Binding(
                        get: { weightLogsManager.currentWeight },
                        set: { weightLogsManager.addLog($0) }
                    ),
                    targetWeight: $weightLogsManager.targetWeight,
                    startWeight: $weightLogsManager.startWeight,
                    targetDate: $weightLogsManager.targetDate,
                    hasDeadline: $weightLogsManager.hasDeadline,
                    onSave: {
                        weightLogsManager.updateGoal(
                            targetWeight: weightLogsManager.targetWeight,
                            startWeight: weightLogsManager.startWeight,
                            targetDate: weightLogsManager.targetDate,
                            hasDeadline: weightLogsManager.hasDeadline
                        )
                    }
                )
            }
            .sheet(isPresented: $showBMIDetail) {
                BMIDetailView(bmi: bmi, status: bmiStatus)
            }
        }
    }
}

// MARK: - 目標カード
struct GoalCard: View {
    let currentWeight: Double
    let targetWeight: Double
    let targetDate: Date
    let hasDeadline: Bool
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: targetDate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("目標")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("現在の体重")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text(String(format: "%.1f", currentWeight))
                            .font(.system(size: 24, weight: .bold))
                        Text("kg")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("目標体重")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text(String(format: "%.1f", targetWeight))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.orange)
                        Text("kg")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("期限")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                    Spacer()
                    if hasDeadline {
                        Text(formattedDate)
                            .font(.system(size: 20, weight: .bold))
                    } else {
                        Text("未設定")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - 進捗カード
struct ProgressCard: View {
    let currentWeight: Double
    let startWeight: Double
    let targetWeight: Double
    let daysRemaining: Int
    let percentage: Double
    let hasDeadline: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("進捗")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                if hasDeadline {
                    Text("あと\(daysRemaining)日")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(20)
                }
            }
            
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(UIColor.systemGray4))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange.opacity(0.8), Color.orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(geometry.size.width * (percentage / 100), 0), height: 12)
                    }
                }
                .frame(height: 12)
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("開始")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f kg", startWeight))
                            .font(.system(size: 13, weight: .medium))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("現在")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                        Text(String(format: "%.1f kg", currentWeight))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("目標")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f kg", targetWeight))
                            .font(.system(size: 13, weight: .medium))
                    }
                }
            }
            
            HStack {
                Text("達成率")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.1f%%", percentage))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.orange)
            }
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - マイルストーンカード（改善版：現在週±2週間表示）
struct MilestoneCardImproved: View {
    let startWeight: Double
    let targetWeight: Double
    let currentWeight: Double
    let targetDate: Date
    @Binding var showAll: Bool
    let hasDeadline: Bool
    var onSetDeadline: () -> Void
    
    private var allMilestones: [(week: Int, targetWeight: Double, date: Date, isCompleted: Bool)] {
        guard hasDeadline else { return [] }
        let totalWeeks = max(Calendar.current.dateComponents([.weekOfYear], from: Date(), to: targetDate).weekOfYear ?? 8, 1)
        let weeklyLoss = (startWeight - targetWeight) / Double(totalWeeks)
        
        var result: [(Int, Double, Date, Bool)] = []
        for week in 1...totalWeeks {
            let weeklyTarget = startWeight - (weeklyLoss * Double(week))
            let weekDate = Calendar.current.date(byAdding: .weekOfYear, value: week, to: Date()) ?? Date()
            let isCompleted = currentWeight <= weeklyTarget
            result.append((week, weeklyTarget, weekDate, isCompleted))
        }
        return result
    }
    
    private var filteredMilestones: [(week: Int, targetWeight: Double, date: Date, isCompleted: Bool)] {
        if showAll {
            return allMilestones
        }
        
        let currentWeekIndex = allMilestones.firstIndex { !$0.isCompleted } ?? 0
        let startIndex = max(currentWeekIndex - 2, 0)
        let endIndex = min(currentWeekIndex + 1, allMilestones.count - 1)
        
        guard startIndex <= endIndex else { return [] }
        return Array(allMilestones[startIndex...endIndex])
    }
    
    private var nextMilestoneIndex: Int? {
        allMilestones.firstIndex { !$0.isCompleted }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("マイルストーン")
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
                
                if hasDeadline && allMilestones.count > 4 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showAll.toggle()
                        }
                    } label: {
                        Text(showAll ? "最近のみ" : "全て表示")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.orange)
                    }
                }
            }
            
            if hasDeadline {
                VStack(spacing: 0) {
                    ForEach(Array(filteredMilestones.enumerated()), id: \.element.week) { index, milestone in
                        let isCurrentWeek = milestone.week == (nextMilestoneIndex.map { allMilestones[$0].week } ?? 0)
                        MilestoneRowImproved(
                            week: milestone.week,
                            targetWeight: milestone.targetWeight,
                            date: milestone.date,
                            isCompleted: milestone.isCompleted,
                            isCurrent: isCurrentWeek
                        )
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("期限を設定してください")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                    
                    Text("期限が確定するとマイルストーンが\n自動的に作成されます")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        onSetDeadline()
                    } label: {
                        Text("期限を設定する")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.orange)
                            .cornerRadius(10)
                    }
                }
                .padding(.vertical, 20)
            }
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct MilestoneRowImproved: View {
    let week: Int
    let targetWeight: Double
    let date: Date
    let isCompleted: Bool
    let isCurrent: Bool
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(isCompleted ? Color.green : (isCurrent ? Color.orange : Color(UIColor.systemGray3)), lineWidth: 2)
                    .frame(width: 22, height: 22)
                
                if isCompleted {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 22, height: 22)
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                } else if isCurrent {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 10, height: 10)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("週 \(week)")
                    .font(.system(size: 15, weight: isCurrent ? .semibold : .regular))
                    .foregroundColor(isCurrent ? .primary : .secondary)
                
                Text(dateString)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(String(format: "%.1f kg", targetWeight))
                .font(.system(size: 15, weight: isCurrent ? .semibold : .regular))
                .foregroundColor(isCompleted ? .green : (isCurrent ? .orange : .secondary))
            
            if isCurrent {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - 目標編集シート
struct GoalEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var currentWeight: Double
    @Binding var targetWeight: Double
    @Binding var startWeight: Double
    @Binding var targetDate: Date
    @Binding var hasDeadline: Bool
    var onSave: () -> Void
    
    @State private var tempCurrentWeight: Double = 0
    @State private var tempTargetWeight: Double = 0
    @State private var tempStartWeight: Double = 0
    @State private var tempTargetDate: Date = Date()
    @State private var tempHasDeadline: Bool = true
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("現在の体重")
                        Spacer()
                        HStack(spacing: 4) {
                            TextField("", value: $tempCurrentWeight, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            Text("kg")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("体重を記録")
                }
                
                Section {
                    HStack {
                        Text("開始時の体重")
                        Spacer()
                        HStack(spacing: 4) {
                            TextField("", value: $tempStartWeight, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            Text("kg")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("目標体重")
                        Spacer()
                        HStack(spacing: 4) {
                            TextField("", value: $tempTargetWeight, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            Text("kg")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("目標を変更")
                }
                
                Section {
                    Toggle("期限を設定する", isOn: $tempHasDeadline)
                    
                    if tempHasDeadline {
                        DatePicker(
                            "期限",
                            selection: $tempTargetDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                    }
                } header: {
                    Text("期限を変更")
                } footer: {
                    if !tempHasDeadline {
                        Text("期限を設定するとマイルストーンが自動的に作成されます")
                    }
                }
            }
            .navigationTitle("目標を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        currentWeight = tempCurrentWeight
                        targetWeight = tempTargetWeight
                        startWeight = tempStartWeight
                        targetDate = tempTargetDate
                        hasDeadline = tempHasDeadline
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("完了") {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                }
            }
            .onAppear {
                tempCurrentWeight = currentWeight
                tempTargetWeight = targetWeight
                tempStartWeight = startWeight
                tempTargetDate = targetDate
                tempHasDeadline = hasDeadline
            }
        }
    }
}

// MARK: - 期間選択
struct PeriodSelector: View {
    @Binding var selectedPeriod: ProgressPeriod
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ProgressPeriod.allCases, id: \.self) { period in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPeriod = period
                    }
                }) {
                    Text(period.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selectedPeriod == period ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedPeriod == period ? Color.orange : Color.clear
                        )
                        .cornerRadius(10)
                }
            }
        }
        .padding(4)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
}

// MARK: - スワイプ対応の体重推移グラフ
struct SwipeableWeightChartCard: View {
    @Binding var selectedPeriod: ProgressPeriod
    @StateObject private var weightLogsManager = WeightLogsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("体重推移")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            TabView(selection: $selectedPeriod) {
                ForEach(ProgressPeriod.allCases, id: \.self) { period in
                    WeightChartContent(period: period)
                        .tag(period)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 220)
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - 体重グラフの中身
struct WeightChartContent: View {
    let period: ProgressPeriod
    @StateObject private var weightLogsManager = WeightLogsManager.shared
    @State private var selectedIndex: Int? = nil
    @State private var popoverPosition: CGPoint = .zero
    
    private var weightLogs: [WeightLogEntry] {
        let logs = weightLogsManager.logs(for: period)
        if logs.isEmpty {
            return []
        }
        return logs
    }
    
    private var dataPoints: [Double] {
        if weightLogs.isEmpty {
            return [weightLogsManager.currentWeight]
        }
        return weightLogs.map { $0.weight }
    }
    
    // 吹き出し用のラベル（実際のログ日付から取得）
    private func labelForIndex(_ index: Int) -> String {
        guard index < weightLogs.count else { return "" }
        let date = weightLogs[index].date
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今日"
        } else if calendar.isDateInYesterday(date) {
            return "昨日"
        } else {
            formatter.dateFormat = "M/d"
            return formatter.string(from: date)
        }
    }
    
    private var xAxisLabels: [String] {
        switch period {
        case .week:
            return ["月", "火", "水", "木", "金", "土", "日"]
        case .sixMonths:
            let formatter = DateFormatter()
            formatter.dateFormat = "M月"
            var labels: [String] = []
            for i in stride(from: 5, through: 0, by: -1) {
                if let date = Calendar.current.date(byAdding: .month, value: -i, to: Date()) {
                    labels.append(formatter.string(from: date))
                }
            }
            return labels
        case .year:
            return ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"]
        case .all:
            return ["開始", "", "", "", "", "", "", "", "", "", "", "現在"]
        }
    }
    
    private var yAxisRange: (min: Double, max: Double) {
        let minVal = (dataPoints.min() ?? 70.0) - 1
        let maxVal = (dataPoints.max() ?? 75.0) + 1
        return (min: floor(minVal), max: ceil(maxVal))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .trailing, spacing: 0) {
                    Text(String(format: "%.0f", yAxisRange.max))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.0f", (yAxisRange.max + yAxisRange.min) / 2))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.0f", yAxisRange.min))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .frame(width: 25, height: 150)
                
                GeometryReader { geometry in
                    let range = yAxisRange
                    let rangeSpan = range.max - range.min
                    
                    ZStack {
                        VStack(spacing: 0) {
                            ForEach(0..<3, id: \.self) { _ in
                                Divider()
                                Spacer()
                            }
                        }
                        
                        if dataPoints.count > 1 {
                            Path { path in
                                for (index, value) in dataPoints.enumerated() {
                                    let x = geometry.size.width * CGFloat(index) / CGFloat(dataPoints.count - 1)
                                    let y = geometry.size.height * (1 - CGFloat((value - range.min) / rangeSpan))
                                    
                                    if index == 0 {
                                        path.move(to: CGPoint(x: x, y: y))
                                    } else {
                                        path.addLine(to: CGPoint(x: x, y: y))
                                    }
                                }
                            }
                            .stroke(Color.blue, lineWidth: 2)
                            
                            // タップ可能な点
                            ForEach(0..<dataPoints.count, id: \.self) { index in
                                let x = geometry.size.width * CGFloat(index) / CGFloat(dataPoints.count - 1)
                                let y = geometry.size.height * (1 - CGFloat((dataPoints[index] - range.min) / rangeSpan))
                                
                                // タップ領域を広げるための透明な円
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 44, height: 44)
                                    .contentShape(Circle())
                                    .position(x: x, y: y)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            if selectedIndex == index {
                                                selectedIndex = nil
                                            } else {
                                                selectedIndex = index
                                                popoverPosition = CGPoint(x: x, y: y)
                                            }
                                        }
                                    }
                                
                                // 表示用の点
                                Circle()
                                    .fill(selectedIndex == index ? Color.blue : Color.blue.opacity(0.7))
                                    .frame(width: selectedIndex == index ? 14 : 8, height: selectedIndex == index ? 14 : 8)
                                    .overlay(
                                        selectedIndex == index ?
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                        : nil
                                    )
                                    .position(x: x, y: y)
                                    .allowsHitTesting(false)
                            }
                            
                            // 吹き出しポップアップ
                            if let index = selectedIndex, index < dataPoints.count {
                                let x = geometry.size.width * CGFloat(index) / CGFloat(dataPoints.count - 1)
                                let y = geometry.size.height * (1 - CGFloat((dataPoints[index] - range.min) / rangeSpan))
                                
                                WeightPopoverView(
                                    label: labelForIndex(index),
                                    value: dataPoints[index],
                                    position: CGPoint(x: x, y: y),
                                    chartWidth: geometry.size.width
                                )
                            }
                        } else if dataPoints.count == 1 {
                            // 1点のみの場合
                            let y = geometry.size.height * (1 - CGFloat((dataPoints[0] - range.min) / rangeSpan))
                            
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 44, height: 44)
                                .contentShape(Circle())
                                .position(x: geometry.size.width / 2, y: y)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        if selectedIndex == 0 {
                                            selectedIndex = nil
                                        } else {
                                            selectedIndex = 0
                                            popoverPosition = CGPoint(x: geometry.size.width / 2, y: y)
                                        }
                                    }
                                }
                            
                            Circle()
                                .fill(selectedIndex == 0 ? Color.blue : Color.blue.opacity(0.7))
                                .frame(width: selectedIndex == 0 ? 14 : 8, height: selectedIndex == 0 ? 14 : 8)
                                .position(x: geometry.size.width / 2, y: y)
                                .allowsHitTesting(false)
                            
                            if selectedIndex == 0 {
                                WeightPopoverView(
                                    label: labelForIndex(0),
                                    value: dataPoints[0],
                                    position: CGPoint(x: geometry.size.width / 2, y: y),
                                    chartWidth: geometry.size.width
                                )
                            }
                        } else {
                            Text("データがありません")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .frame(height: 150)
            }
            .padding(.horizontal, 20)
            
            HStack {
                Spacer().frame(width: 33)
                ForEach(xAxisLabels.indices, id: \.self) { index in
                    Text(xAxisLabels[index])
                        .font(.system(size: 10))
                        .foregroundColor(selectedIndex == index ? .blue : .secondary)
                        .fontWeight(selectedIndex == index ? .semibold : .regular)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedIndex = nil
            }
        }
    }
}

// MARK: - 体重用吹き出しポップアップ
struct WeightPopoverView: View {
    let label: String
    let value: Double
    let position: CGPoint
    let chartWidth: CGFloat
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.8))
            Text(String(format: "%.1f kg", value))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.blue)
        .cornerRadius(8)
        .overlay(
            // 三角形の矢印（下向き）
            Triangle()
                .fill(Color.blue)
                .frame(width: 12, height: 8)
                .offset(y: 4),
            alignment: .bottom
        )
        .position(x: calculateXPosition(), y: max(position.y - 40, 25))
        .transition(.scale.combined(with: .opacity))
    }
    
    private func calculateXPosition() -> CGFloat {
        // 端の場合は吹き出しが画面外に出ないように調整
        let popoverWidth: CGFloat = 70
        let minX = popoverWidth / 2
        let maxX = chartWidth - popoverWidth / 2
        return min(max(position.x, minX), maxX)
    }
}

// MARK: - スワイプ対応のカロリー棒グラフ
struct SwipeableCalorieBarChartCard: View {
    @Binding var selectedPeriod: ProgressPeriod
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カロリー推移")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            TabView(selection: $selectedPeriod) {
                ForEach(ProgressPeriod.allCases, id: \.self) { period in
                    CalorieBarChartContent(period: period)
                        .tag(period)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 220)
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - カロリー棒グラフの中身
struct CalorieBarChartContent: View {
    let period: ProgressPeriod
    @StateObject private var mealLogsManager = MealLogsManager.shared
    
    private var dataPoints: [Int] {
        let calendar = Calendar.current
        let today = Date()
        
        switch period {
        case .week:
            // 過去7日間のカロリーデータ
            var data: [Int] = []
            for i in stride(from: 6, through: 0, by: -1) {
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    let calories = mealLogsManager.totalCalories(for: date)
                    data.append(calories > 0 ? calories : 0)
                }
            }
            return data.isEmpty ? [0, 0, 0, 0, 0, 0, 0] : data
            
        case .sixMonths:
            // 過去6ヶ月の月別平均
            var data: [Int] = []
            for i in stride(from: 5, through: 0, by: -1) {
                if let monthStart = calendar.date(byAdding: .month, value: -i, to: today) {
                    let range = calendar.range(of: .day, in: .month, for: monthStart)!
                    var total = 0
                    var count = 0
                    for day in 1...range.count {
                        if let date = calendar.date(bySetting: .day, value: day, of: monthStart) {
                            let calories = mealLogsManager.totalCalories(for: date)
                            if calories > 0 {
                                total += calories
                                count += 1
                            }
                        }
                    }
                    data.append(count > 0 ? total / count : 0)
                }
            }
            return data.isEmpty ? [0, 0, 0, 0, 0, 0] : data
            
        case .year:
            // 過去12ヶ月の月別平均
            var data: [Int] = []
            for i in stride(from: 11, through: 0, by: -1) {
                if let monthStart = calendar.date(byAdding: .month, value: -i, to: today) {
                    let range = calendar.range(of: .day, in: .month, for: monthStart)!
                    var total = 0
                    var count = 0
                    for day in 1...min(range.count, 28) {
                        if let date = calendar.date(bySetting: .day, value: day, of: monthStart) {
                            let calories = mealLogsManager.totalCalories(for: date)
                            if calories > 0 {
                                total += calories
                                count += 1
                            }
                        }
                    }
                    data.append(count > 0 ? total / count : 0)
                }
            }
            return data.isEmpty ? Array(repeating: 0, count: 12) : data
            
        case .all:
            // 全期間のデータ（12区間に分割）
            let allLogs = mealLogsManager.allLogs
            guard !allLogs.isEmpty else { return Array(repeating: 0, count: 12) }
            
            let sortedLogs = allLogs.sorted { $0.date < $1.date }
            let firstDate = sortedLogs.first?.date ?? today
            let totalDays = max(1, calendar.dateComponents([.day], from: firstDate, to: today).day ?? 1)
            let interval = totalDays / 12
            
            var data: [Int] = []
            for i in 0..<12 {
                let startDay = i * interval
                let endDay = (i + 1) * interval
                var total = 0
                var count = 0
                for log in sortedLogs {
                    let dayOffset = calendar.dateComponents([.day], from: firstDate, to: log.date).day ?? 0
                    if dayOffset >= startDay && dayOffset < endDay {
                        total += log.calories
                        count += 1
                    }
                }
                data.append(count > 0 ? total / count : 0)
            }
            return data
        }
    }
    
    private var xAxisLabels: [String] {
        let calendar = Calendar.current
        let today = Date()
        
        switch period {
        case .week:
            let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]
            var labels: [String] = []
            for i in stride(from: 6, through: 0, by: -1) {
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    let weekday = calendar.component(.weekday, from: date) - 1
                    labels.append(weekdaySymbols[weekday])
                }
            }
            return labels
        case .sixMonths:
            let formatter = DateFormatter()
            formatter.dateFormat = "M月"
            var labels: [String] = []
            for i in stride(from: 5, through: 0, by: -1) {
                if let date = calendar.date(byAdding: .month, value: -i, to: today) {
                    labels.append(formatter.string(from: date))
                }
            }
            return labels
        case .year:
            return ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"]
        case .all:
            return ["開始", "", "", "", "", "", "", "", "", "", "", "現在"]
        }
    }
    
    private var averageCalories: Int {
        let nonZero = dataPoints.filter { $0 > 0 }
        guard !nonZero.isEmpty else { return 0 }
        return nonZero.reduce(0, +) / nonZero.count
    }
    
    private var maxValue: Int {
        max(dataPoints.max() ?? 2500, 2500)
    }
    
    @State private var selectedIndex: Int? = nil
    @State private var popoverPosition: CGPoint = .zero
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("平均")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(averageCalories > 0 ? "\(averageCalories) kcal" : "-- kcal")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                
                GeometryReader { geometry in
                    HStack(alignment: .bottom, spacing: 8) {
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("\(maxValue)")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(maxValue / 2)")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("0")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 28, height: 120)
                        
                        HStack(alignment: .bottom, spacing: 6) {
                            ForEach(Array(dataPoints.enumerated()), id: \.offset) { index, value in
                                GeometryReader { barGeometry in
                                    let barHeight = value > 0 ? max(CGFloat(value) / CGFloat(maxValue) * 120, 8) : 8
                                    
                                    VStack(spacing: 0) {
                                        Spacer()
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(selectedIndex == index ? Color.orange : (value > 0 ? (index == dataPoints.count - 1 ? Color.orange : Color.orange.opacity(0.5)) : Color(UIColor.systemGray5)))
                                            .frame(height: barHeight)
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        let barFrame = barGeometry.frame(in: .named("chartArea"))
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            if selectedIndex == index {
                                                selectedIndex = nil
                                            } else {
                                                selectedIndex = index
                                                popoverPosition = CGPoint(
                                                    x: barFrame.midX,
                                                    y: 120 - barHeight - 10
                                                )
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .frame(height: 130)
                    .coordinateSpace(name: "chartArea")
                    .overlay {
                        // 吹き出しポップアップ
                        if let index = selectedIndex, index < dataPoints.count {
                            CaloriePopoverView(
                                label: xAxisLabels[safe: index] ?? "",
                                value: dataPoints[index],
                                position: popoverPosition,
                                barCount: dataPoints.count,
                                selectedIndex: index
                            )
                        }
                    }
                }
                .frame(height: 130)
                .padding(.horizontal, 20)
                
                HStack {
                    Spacer().frame(width: 36)
                    ForEach(xAxisLabels.indices, id: \.self) { index in
                        Text(xAxisLabels[index])
                            .font(.system(size: 10))
                            .foregroundColor(selectedIndex == index ? .orange : .secondary)
                            .fontWeight(selectedIndex == index ? .semibold : .regular)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 16)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedIndex = nil
            }
        }
    }
}

// MARK: - カロリー用吹き出しポップアップ
struct CaloriePopoverView: View {
    let label: String
    let value: Int
    let position: CGPoint
    let barCount: Int
    let selectedIndex: Int
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.8))
            Text(value > 0 ? "\(value) kcal" : "記録なし")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.orange)
        .cornerRadius(8)
        .overlay(
            // 三角形の矢印
            Triangle()
                .fill(Color.orange)
                .frame(width: 12, height: 8)
                .offset(y: 4),
            alignment: .bottom
        )
        .offset(y: -8)
        .position(x: calculateXPosition(), y: position.y)
        .transition(.scale.combined(with: .opacity))
    }
    
    private func calculateXPosition() -> CGFloat {
        // バーの中央に配置、端の場合は少し内側にオフセット
        let barWidth = (UIScreen.main.bounds.width - 80) / CGFloat(barCount)
        let baseX = 36 + barWidth * CGFloat(selectedIndex) + barWidth / 2
        
        // 端の場合は吹き出しが画面外に出ないように調整
        let popoverWidth: CGFloat = 80
        if selectedIndex == 0 {
            return max(baseX, popoverWidth / 2 + 10)
        } else if selectedIndex == barCount - 1 {
            return min(baseX, UIScreen.main.bounds.width - 60 - popoverWidth / 2)
        }
        return baseX
    }
}

// MARK: - 三角形シェイプ
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - 安全な配列アクセス
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - BMIカード
struct BMICard: View {
    let bmi: Double
    let status: String
    let onInfoTap: () -> Void
    
    private var bmiPosition: Double {
        let minBMI = 16.0
        let maxBMI = 32.0
        let clamped = min(max(bmi, minBMI), maxBMI)
        return (clamped - minBMI) / (maxBMI - minBMI)
    }
    
    private var statusColor: Color {
        switch status {
        case "低体重": return .cyan
        case "適正": return .green
        case "過体重": return .yellow
        case "肥満": return .red
        default: return .green
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("BMI")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    onInfoTap()
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(alignment: .center, spacing: 12) {
                Text(String(format: "%.1f", bmi))
                    .font(.system(size: 36, weight: .bold))
                
                Text(status)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(statusColor)
                    .cornerRadius(12)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    LinearGradient(
                        gradient: Gradient(colors: [.cyan, .green, .yellow, .orange, .red]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 8)
                    .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.primary)
                        .frame(width: 3, height: 16)
                        .cornerRadius(1.5)
                        .position(x: geometry.size.width * bmiPosition, y: 4)
                }
            }
            .frame(height: 16)
            
            HStack {
                Text("低体重")
                    .foregroundColor(.cyan)
                Spacer()
                Text("適正")
                    .foregroundColor(.green)
                Spacer()
                Text("過体重")
                    .foregroundColor(.yellow)
                Spacer()
                Text("肥満")
                    .foregroundColor(.red)
            }
            .font(.system(size: 11))
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - BMI詳細画面
struct BMIDetailView: View {
    let bmi: Double
    let status: String
    @Environment(\.dismiss) private var dismiss
    
    private var bmiPosition: Double {
        let minBMI = 16.0
        let maxBMI = 32.0
        let clamped = min(max(bmi, minBMI), maxBMI)
        return (clamped - minBMI) / (maxBMI - minBMI)
    }
    
    private var statusColor: Color {
        switch status {
        case "低体重": return .cyan
        case "適正": return .green
        case "過体重": return .yellow
        case "肥満": return .red
        default: return .green
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                Text("BMI")
                    .font(.system(size: 17, weight: .semibold))
                
                Spacer()
                
                Color.clear
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Text("あなたの体重は")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                            
                            Text(status)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(statusColor)
                                .cornerRadius(12)
                        }
                        
                        Text(String(format: "%.1f", bmi))
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.primary)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                LinearGradient(
                                    gradient: Gradient(colors: [.cyan, .green, .yellow, .orange, .red]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(height: 10)
                                .cornerRadius(5)
                                
                                Rectangle()
                                    .fill(Color.primary)
                                    .frame(width: 3, height: 20)
                                    .cornerRadius(1.5)
                                    .position(x: geometry.size.width * bmiPosition, y: 5)
                            }
                        }
                        .frame(height: 20)
                        
                        HStack(spacing: 16) {
                            LegendItem(color: .cyan, text: "低体重")
                            LegendItem(color: .green, text: "適正")
                            LegendItem(color: .yellow, text: "過体重")
                            LegendItem(color: .red, text: "肥満")
                        }
                        .font(.system(size: 12))
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("免責事項")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("BMIは健康の完全な指標ではありません。例えば、妊娠中や筋肉量が多い場合は結果が正確でないことがあり、また子供や高齢者の健康を測る指標としては適切でない場合があります。")
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                            .lineSpacing(4)
                        
                        Text("では、なぜBMIが重要なのでしょうか？")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        Text("一般的に、BMIが高いほど、体重過多に関連するさまざまな疾患のリスクが高くなります。")
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                            .lineSpacing(4)
                        
                        Text("関連する疾患には以下が含まれます：")
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            BulletPoint(text: "糖尿病")
                            BulletPoint(text: "関節炎")
                            BulletPoint(text: "肝臓疾患")
                            BulletPoint(text: "各種がん（乳がん、大腸がん、前立腺がんなど）")
                            BulletPoint(text: "高血圧")
                            BulletPoint(text: "高コレステロール")
                            BulletPoint(text: "睡眠時無呼吸症候群")
                        }
                        
                        Button {
                            if let url = URL(string: "https://kennet.mhlw.go.jp/information/information/dictionary/metabolic/ym-002") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text("ソース")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .underline()
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}

struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .foregroundColor(.secondary)
        }
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 15))
                .foregroundColor(.primary)
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    S38_ProgressView()
}
