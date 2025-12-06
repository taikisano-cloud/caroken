import SwiftUI

struct S38_ProgressView: View {
    var bottomPadding: CGFloat = 0
    
    @StateObject private var weightLogsManager = WeightLogsManager.shared
    @StateObject private var profileManager = UserProfileManager.shared
    @State private var selectedPeriod: ProgressPeriod = .week
    @State private var showAllMilestones: Bool = false
    @State private var showGoalEditor: Bool = false
    @State private var showBMIDetail: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 手動ヘッダー（S24_HomeViewと統一）
                HStack {
                    Text("進捗")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 60)
                
                GoalCard(
                    currentWeight: weightLogsManager.currentWeight,
                    targetWeight: weightLogsManager.targetWeight,
                    targetDate: weightLogsManager.targetDate,
                    hasDeadline: weightLogsManager.hasDeadline
                )
                .onTapGesture { showGoalEditor = true }
                .padding(.horizontal, 16)
                
                ProgressCard(
                    currentWeight: weightLogsManager.currentWeight,
                    startWeight: weightLogsManager.startWeight,
                    targetWeight: weightLogsManager.targetWeight,
                    daysRemaining: weightLogsManager.daysRemaining,
                    percentage: weightLogsManager.progressPercentage,
                    hasDeadline: weightLogsManager.hasDeadline
                )
                .padding(.horizontal, 16)
                
                MilestoneCardImproved(
                    startWeight: weightLogsManager.startWeight,
                    targetWeight: weightLogsManager.targetWeight,
                    currentWeight: weightLogsManager.currentWeight,
                    targetDate: weightLogsManager.targetDate,
                    showAll: $showAllMilestones,
                    hasDeadline: weightLogsManager.hasDeadline,
                    onSetDeadline: { showGoalEditor = true }
                )
                .padding(.horizontal, 16)
                
                PeriodSelector(selectedPeriod: $selectedPeriod)
                    .padding(.top, 8)
                
                SwipeableCalorieBarChartCard(selectedPeriod: $selectedPeriod)
                    .padding(.horizontal, 16)
                
                SwipeableWeightChartCard(selectedPeriod: $selectedPeriod)
                    .padding(.horizontal, 16)
                
                BMICard(bmi: profileManager.bmi, status: profileManager.bmiStatus) {
                    showBMIDetail = true
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 12 + bottomPadding)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
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
            BMIDetailView(bmi: profileManager.bmi, status: profileManager.bmiStatus)
        }
    }
}

// MARK: - 目標カード
struct GoalCard: View {
    let currentWeight: Double
    let targetWeight: Double
    let targetDate: Date
    let hasDeadline: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("目標").font(.system(size: 20, weight: .bold))
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 14)).foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                weightRow("現在の体重", currentWeight, false)
                weightRow("目標体重", targetWeight, true)
                HStack {
                    Text("期限").font(.system(size: 15)).foregroundColor(.secondary)
                    Spacer()
                    if hasDeadline {
                        Text(formatDate(targetDate)).font(.system(size: 20, weight: .bold))
                    } else {
                        Text("未設定").font(.system(size: 20, weight: .medium)).foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private func weightRow(_ title: String, _ value: Double, _ isTarget: Bool) -> some View {
        HStack {
            Text(title).font(.system(size: 15)).foregroundColor(.secondary)
            Spacer()
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(String(format: "%.1f", value)).font(.system(size: 24, weight: .bold)).foregroundColor(isTarget ? .orange : .primary)
                Text("kg").font(.system(size: 14)).foregroundColor(.secondary)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }
}

// MARK: - 進捗カード
struct ProgressCard: View {
    let currentWeight, startWeight, targetWeight: Double
    let daysRemaining: Int
    let percentage: Double
    let hasDeadline: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("進捗").font(.system(size: 20, weight: .bold))
                Spacer()
                if hasDeadline {
                    Text("あと\(daysRemaining)日")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(20)
                }
            }
            
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.systemGray4)).frame(height: 12)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(colors: [.orange.opacity(0.8), .orange], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(geo.size.width * (percentage / 100), 0), height: 12)
                    }
                }.frame(height: 12)
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("開始").font(.system(size: 11)).foregroundColor(.secondary)
                        Text(String(format: "%.1f kg", startWeight)).font(.system(size: 13, weight: .medium))
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text("現在").font(.system(size: 11)).foregroundColor(.orange)
                        Text(String(format: "%.1f kg", currentWeight)).font(.system(size: 13, weight: .bold)).foregroundColor(.orange)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("目標").font(.system(size: 11)).foregroundColor(.secondary)
                        Text(String(format: "%.1f kg", targetWeight)).font(.system(size: 13, weight: .medium))
                    }
                }
            }
            
            HStack {
                Text("達成率").font(.system(size: 14)).foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.1f%%", percentage)).font(.system(size: 18, weight: .bold)).foregroundColor(.orange)
            }
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - マイルストーンカード
struct MilestoneCardImproved: View {
    let startWeight, targetWeight, currentWeight: Double
    let targetDate: Date
    @Binding var showAll: Bool
    let hasDeadline: Bool
    var onSetDeadline: () -> Void
    
    private var allMilestones: [(week: Int, targetWeight: Double, date: Date, isCompleted: Bool)] {
        guard hasDeadline else { return [] }
        let totalWeeks = max(Calendar.current.dateComponents([.weekOfYear], from: Date(), to: targetDate).weekOfYear ?? 8, 1)
        let weeklyLoss = (startWeight - targetWeight) / Double(totalWeeks)
        return (1...totalWeeks).map { week in
            let wt = startWeight - (weeklyLoss * Double(week))
            let dt = Calendar.current.date(byAdding: .weekOfYear, value: week, to: Date()) ?? Date()
            return (week, wt, dt, currentWeight <= wt)
        }
    }
    
    private var filteredMilestones: [(week: Int, targetWeight: Double, date: Date, isCompleted: Bool)] {
        if showAll { return allMilestones }
        let idx = allMilestones.firstIndex { !$0.isCompleted } ?? 0
        let start = max(idx - 2, 0)
        let end = min(idx + 1, allMilestones.count - 1)
        guard start <= end else { return [] }
        return Array(allMilestones[start...end])
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("マイルストーン").font(.system(size: 20, weight: .bold))
                Spacer()
                if hasDeadline && allMilestones.count > 4 {
                    Button { withAnimation { showAll.toggle() } } label: {
                        Text(showAll ? "最近のみ" : "全て表示").font(.system(size: 13, weight: .medium)).foregroundColor(.orange)
                    }
                }
            }
            
            if hasDeadline {
                let nextIdx = allMilestones.firstIndex { !$0.isCompleted }
                VStack(spacing: 0) {
                    ForEach(filteredMilestones, id: \.week) { m in
                        let isCurrent = m.week == (nextIdx.map { allMilestones[$0].week } ?? 0)
                        MilestoneRow(week: m.week, targetWeight: m.targetWeight, date: m.date, isCompleted: m.isCompleted, isCurrent: isCurrent)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.plus").font(.system(size: 40)).foregroundColor(.secondary)
                    Text("期限を設定してください").font(.system(size: 15)).foregroundColor(.secondary)
                    Text("期限が確定するとマイルストーンが\n自動的に作成されます").font(.system(size: 13)).foregroundColor(.secondary).multilineTextAlignment(.center)
                    Button { onSetDeadline() } label: {
                        Text("期限を設定する").font(.system(size: 15, weight: .semibold)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 12).background(Color.orange).cornerRadius(10)
                    }
                }.padding(.vertical, 20)
            }
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct MilestoneRow: View {
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
            statusIcon
            weekInfo
            Spacer()
            weightText
            if isCurrent {
                Circle().fill(Color.orange).frame(width: 6, height: 6)
            }
        }
        .padding(.vertical, 10)
    }
    
    private var statusIcon: some View {
        ZStack {
            Circle()
                .stroke(iconColor, lineWidth: 2)
                .frame(width: 22, height: 22)
            if isCompleted {
                Circle().fill(Color.green).frame(width: 22, height: 22)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            } else if isCurrent {
                Circle().fill(Color.orange).frame(width: 10, height: 10)
            }
        }
    }
    
    private var iconColor: Color {
        if isCompleted { return .green }
        if isCurrent { return .orange }
        return Color(UIColor.systemGray3)
    }
    
    private var weekInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("週 \(week)")
                .font(.system(size: 15, weight: isCurrent ? .semibold : .regular))
                .foregroundColor(isCurrent ? .primary : .secondary)
            Text(dateString)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
    
    private var weightText: some View {
        Text(String(format: "%.1f kg", targetWeight))
            .font(.system(size: 15, weight: isCurrent ? .semibold : .regular))
            .foregroundColor(weightColor)
    }
    
    private var weightColor: Color {
        if isCompleted { return .green }
        if isCurrent { return .orange }
        return .secondary
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
    
    @State private var tempCurrent: Double = 0
    @State private var tempTarget: Double = 0
    @State private var tempStart: Double = 0
    @State private var tempDate: Date = Date()
    @State private var tempHas: Bool = true
    
    var body: some View {
        NavigationStack {
            List {
                Section("体重を記録") { row("現在の体重", $tempCurrent) }
                Section("目標を変更") { row("開始時の体重", $tempStart); row("目標体重", $tempTarget) }
                Section(header: Text("期限を変更"), footer: !tempHas ? Text("期限を設定するとマイルストーンが自動的に作成されます") : nil) {
                    Toggle("期限を設定する", isOn: $tempHas)
                    if tempHas { DatePicker("期限", selection: $tempDate, in: Date()..., displayedComponents: .date).environment(\.locale, Locale(identifier: "ja_JP")) }
                }
            }
            .navigationTitle("目標を編集").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("保存") { save() }.fontWeight(.semibold) }
                ToolbarItem(placement: .keyboard) { HStack { Spacer(); Button("完了") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) } } }
            }
            .onAppear { tempCurrent = currentWeight; tempTarget = targetWeight; tempStart = startWeight; tempDate = targetDate; tempHas = hasDeadline }
        }
    }
    
    private func row(_ title: String, _ value: Binding<Double>) -> some View {
        HStack { Text(title); Spacer(); TextField("", value: value, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 60); Text("kg").foregroundColor(.secondary) }
    }
    
    private func save() { currentWeight = tempCurrent; targetWeight = tempTarget; startWeight = tempStart; targetDate = tempDate; hasDeadline = tempHas; onSave(); dismiss() }
}

// MARK: - 期間選択
struct PeriodSelector: View {
    @Binding var selectedPeriod: ProgressPeriod
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ProgressPeriod.allCases, id: \.self) { p in
                Button { withAnimation { selectedPeriod = p } } label: {
                    Text(p.rawValue).font(.system(size: 14, weight: .semibold)).foregroundColor(selectedPeriod == p ? .white : .secondary).frame(maxWidth: .infinity).padding(.vertical, 10).background(selectedPeriod == p ? Color.orange : Color.clear).cornerRadius(10)
                }
            }
        }.padding(4).background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(12).padding(.horizontal, 20)
    }
}

// MARK: - カロリー棒グラフ
struct SwipeableCalorieBarChartCard: View {
    @Binding var selectedPeriod: ProgressPeriod
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カロリー推移").font(.system(size: 16, weight: .semibold)).foregroundColor(.secondary).padding(.horizontal, 20).padding(.top, 20)
            TabView(selection: $selectedPeriod) {
                ForEach(ProgressPeriod.allCases, id: \.self) { CalorieBarContent(period: $0).tag($0) }
            }.tabViewStyle(.page(indexDisplayMode: .never)).frame(height: 200)
        }.background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(16)
    }
}

struct CalorieBarContent: View {
    let period: ProgressPeriod
    @StateObject private var manager = MealLogsManager.shared
    
    private var data: [Int] {
        let cal = Calendar.current
        let today = Date()
        
        switch period {
        case .week:
            return getWeekData(cal: cal, today: today)
        case .sixMonths:
            return getMonthlyAverage(cal: cal, today: today, months: 6)
        case .year:
            return getMonthlyAverage(cal: cal, today: today, months: 12)
        case .all:
            return Array(repeating: 0, count: 12)
        }
    }
    
    private func getWeekData(cal: Calendar, today: Date) -> [Int] {
        var result: [Int] = []
        for offset in (0..<7).reversed() {
            if let date = cal.date(byAdding: .day, value: -offset, to: today) {
                result.append(manager.totalCalories(for: date))
            } else {
                result.append(0)
            }
        }
        return result
    }
    
    private func getMonthlyAverage(cal: Calendar, today: Date, months: Int) -> [Int] {
        var result: [Int] = []
        for offset in (0..<months).reversed() {
            guard let monthStart = cal.date(byAdding: .month, value: -offset, to: today),
                  let range = cal.range(of: .day, in: .month, for: monthStart) else {
                result.append(0)
                continue
            }
            
            var total = 0
            var count = 0
            let dayCount = min(range.count, 28)
            
            for day in 1...dayCount {
                if let date = cal.date(bySetting: .day, value: day, of: monthStart) {
                    let calories = manager.totalCalories(for: date)
                    if calories > 0 {
                        total += calories
                        count += 1
                    }
                }
            }
            result.append(count > 0 ? total / count : 0)
        }
        return result
    }
    
    private var labels: [String] {
        let cal = Calendar.current
        let today = Date()
        let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
        
        switch period {
        case .week:
            return getWeekLabels(cal: cal, today: today, weekdays: weekdays)
        case .sixMonths:
            return getMonthLabels(cal: cal, today: today, months: 6)
        case .year:
            return ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"]
        case .all:
            return ["開始", "", "", "", "", "", "", "", "", "", "", "現在"]
        }
    }
    
    private func getWeekLabels(cal: Calendar, today: Date, weekdays: [String]) -> [String] {
        var result: [String] = []
        for offset in (0..<7).reversed() {
            if let date = cal.date(byAdding: .day, value: -offset, to: today) {
                let weekday = cal.component(.weekday, from: date) - 1
                result.append(weekdays[weekday])
            } else {
                result.append("")
            }
        }
        return result
    }
    
    private func getMonthLabels(cal: Calendar, today: Date, months: Int) -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月"
        var result: [String] = []
        for offset in (0..<months).reversed() {
            if let date = cal.date(byAdding: .month, value: -offset, to: today) {
                result.append(formatter.string(from: date))
            }
        }
        return result
    }
    
    private var avg: Int {
        let nonZero = data.filter { $0 > 0 }
        return nonZero.isEmpty ? 0 : nonZero.reduce(0, +) / nonZero.count
    }
    
    private var maxV: Int {
        max(data.max() ?? 2500, 2500)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            averageHeader
            chartContent
            xAxisLabels
        }
    }
    
    private var averageHeader: some View {
        HStack {
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("平均")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text(avg > 0 ? "\(avg) kcal" : "-- kcal")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
    
    private var chartContent: some View {
        HStack(alignment: .bottom, spacing: 6) {
            yAxisLabels
            barsView
        }
        .frame(height: 110)
        .padding(.horizontal, 20)
    }
    
    private var yAxisLabels: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text("\(maxV)")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
            Spacer()
            Text("\(maxV / 2)")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
            Spacer()
            Text("0")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .frame(width: 28, height: 100)
    }
    
    private var barsView: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                CalorieBar(value: value, maxValue: maxV, isLast: index == data.count - 1)
            }
        }
    }
    
    private var xAxisLabels: some View {
        HStack {
            Spacer().frame(width: 36)
            ForEach(labels.indices, id: \.self) { index in
                Text(labels[index])
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 16)
    }
}

struct CalorieBar: View {
    let value: Int
    let maxValue: Int
    let isLast: Bool
    
    private var barHeight: CGFloat {
        value > 0 ? max(CGFloat(value) / CGFloat(maxValue) * 100, 8) : 8
    }
    
    private var barColor: Color {
        if value > 0 {
            return isLast ? Color.orange : Color.orange.opacity(0.5)
        }
        return Color(UIColor.systemGray5)
    }
    
    var body: some View {
        VStack {
            Spacer()
            RoundedRectangle(cornerRadius: 4)
                .fill(barColor)
                .frame(height: barHeight)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 体重グラフ
struct SwipeableWeightChartCard: View {
    @Binding var selectedPeriod: ProgressPeriod
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("体重推移").font(.system(size: 16, weight: .semibold)).foregroundColor(.secondary).padding(.horizontal, 20).padding(.top, 20)
            TabView(selection: $selectedPeriod) {
                ForEach(ProgressPeriod.allCases, id: \.self) { WeightChartContent(period: $0).tag($0) }
            }.tabViewStyle(.page(indexDisplayMode: .never)).frame(height: 200)
        }.background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(16)
    }
}

struct WeightChartContent: View {
    let period: ProgressPeriod
    @StateObject private var manager = WeightLogsManager.shared
    
    private var data: [Double] {
        let logs = manager.logs(for: period)
        return logs.isEmpty ? [manager.currentWeight] : logs.map { $0.weight }
    }
    
    private var yRange: (min: Double, max: Double) {
        let minVal = floor((data.min() ?? 70) - 1)
        let maxVal = ceil((data.max() ?? 75) + 1)
        return (minVal, maxVal)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            chartArea
            xAxisLabels
        }
    }
    
    private var chartArea: some View {
        HStack(alignment: .top, spacing: 8) {
            yAxisLabels
            chartGraph
        }
        .padding(.horizontal, 20)
    }
    
    private var yAxisLabels: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(String(format: "%.0f", yRange.max))
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Spacer()
            Text(String(format: "%.0f", (yRange.max + yRange.min) / 2))
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Spacer()
            Text(String(format: "%.0f", yRange.min))
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(width: 25, height: 130)
    }
    
    private var chartGraph: some View {
        GeometryReader { geo in
            ZStack {
                gridLines
                chartLine(in: geo)
                chartPoints(in: geo)
            }
        }
        .frame(height: 130)
    }
    
    private var gridLines: some View {
        VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { _ in
                Divider()
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private func chartLine(in geo: GeometryProxy) -> some View {
        if data.count > 1 {
            Path { path in
                let span = yRange.max - yRange.min
                for (index, value) in data.enumerated() {
                    let x = geo.size.width * CGFloat(index) / CGFloat(data.count - 1)
                    let y = geo.size.height * (1 - CGFloat((value - yRange.min) / span))
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.blue, lineWidth: 2)
        }
    }
    
    @ViewBuilder
    private func chartPoints(in geo: GeometryProxy) -> some View {
        let span = yRange.max - yRange.min
        
        if data.count > 1 {
            ForEach(0..<data.count, id: \.self) { index in
                let x = geo.size.width * CGFloat(index) / CGFloat(data.count - 1)
                let y = geo.size.height * (1 - CGFloat((data[index] - yRange.min) / span))
                Circle()
                    .fill(Color.blue.opacity(0.7))
                    .frame(width: 8, height: 8)
                    .position(x: x, y: y)
            }
        } else {
            let y = geo.size.height * (1 - CGFloat((data[0] - yRange.min) / span))
            Circle()
                .fill(Color.blue.opacity(0.7))
                .frame(width: 8, height: 8)
                .position(x: geo.size.width / 2, y: y)
        }
    }
    
    private var xAxisLabels: some View {
        HStack {
            Spacer().frame(width: 33)
            ForEach(["月", "火", "水", "木", "金", "土", "日"], id: \.self) { day in
                Text(day)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

// MARK: - BMIカード
struct BMICard: View {
    let bmi: Double, status: String
    let onInfoTap: () -> Void
    
    private var pos: Double { min(max((bmi - 16) / 16, 0), 1) }
    private var color: Color { switch status { case "低体重": return .cyan; case "適正": return .green; case "過体重": return .yellow; case "肥満": return .red; default: return .green } }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Text("BMI").font(.system(size: 16, weight: .semibold)).foregroundColor(.secondary); Spacer(); Button { onInfoTap() } label: { Image(systemName: "questionmark.circle").font(.system(size: 20)).foregroundColor(.secondary) } }
            HStack(alignment: .center, spacing: 12) { Text(String(format: "%.1f", bmi)).font(.system(size: 36, weight: .bold)); Text(status).font(.system(size: 14, weight: .semibold)).foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 4).background(color).cornerRadius(12) }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    LinearGradient(colors: [.cyan, .green, .yellow, .orange, .red], startPoint: .leading, endPoint: .trailing).frame(height: 8).cornerRadius(4)
                    Rectangle().fill(Color.primary).frame(width: 3, height: 16).cornerRadius(1.5).position(x: geo.size.width * pos, y: 4)
                }
            }.frame(height: 16)
            HStack { Text("低体重").foregroundColor(.cyan); Spacer(); Text("適正").foregroundColor(.green); Spacer(); Text("過体重").foregroundColor(.yellow); Spacer(); Text("肥満").foregroundColor(.red) }.font(.system(size: 11))
        }.padding(20).background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(16)
    }
}

// MARK: - BMI詳細
struct BMIDetailView: View {
    let bmi: Double
    let status: String
    @Environment(\.dismiss) private var dismiss
    
    private var pos: Double { min(max((bmi - 16) / 16, 0), 1) }
    
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
            headerBar
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    bmiSummarySection
                    disclaimerSection
                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
        }
        .background(Color(UIColor.systemBackground))
    }
    
    private var headerBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            Spacer()
            Text("BMI")
                .font(.system(size: 17, weight: .semibold))
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
    }
    
    private var bmiSummarySection: some View {
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
            
            bmiGradientBar
            bmiLegend
        }
        .padding(.horizontal, 20)
    }
    
    private var bmiGradientBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                LinearGradient(colors: [.cyan, .green, .yellow, .orange, .red], startPoint: .leading, endPoint: .trailing)
                    .frame(height: 10)
                    .cornerRadius(5)
                Rectangle()
                    .fill(Color.primary)
                    .frame(width: 3, height: 20)
                    .cornerRadius(1.5)
                    .position(x: geo.size.width * pos, y: 5)
            }
        }
        .frame(height: 20)
    }
    
    private var bmiLegend: some View {
        HStack(spacing: 16) {
            legendItem("低体重", .cyan)
            legendItem("適正", .green)
            legendItem("過体重", .yellow)
            legendItem("肥満", .red)
        }
        .font(.system(size: 12))
    }
    
    private func legendItem(_ text: String, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text).foregroundColor(.secondary)
        }
    }
    
    private var disclaimerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("免責事項")
                .font(.system(size: 20, weight: .bold))
            
            Text("BMIは健康の完全な指標ではありません。例えば、妊娠中や筋肉量が多い場合は結果が正確でないことがあり、また子供や高齢者の健康を測る指標としては適切でない場合があります。")
                .font(.system(size: 15))
                .lineSpacing(4)
            
            Text("では、なぜBMIが重要なのでしょうか？")
                .font(.system(size: 18, weight: .bold))
                .padding(.top, 8)
            
            Text("一般的に、BMIが高いほど、体重過多に関連するさまざまな疾患のリスクが高くなります。")
                .font(.system(size: 15))
                .lineSpacing(4)
            
            Text("関連する疾患には以下が含まれます：")
                .font(.system(size: 15))
            
            diseaseList
            sourceButton
        }
        .padding(.horizontal, 20)
    }
    
    private var diseaseList: some View {
        VStack(alignment: .leading, spacing: 6) {
            bulletPoint("糖尿病")
            bulletPoint("関節炎")
            bulletPoint("肝臓疾患")
            bulletPoint("各種がん")
            bulletPoint("高血圧")
            bulletPoint("高コレステロール")
            bulletPoint("睡眠時無呼吸症候群")
        }
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
        .font(.system(size: 15))
    }
    
    private var sourceButton: some View {
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
}

// MARK: - 三角形
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path(); p.move(to: CGPoint(x: rect.midX, y: rect.maxY)); p.addLine(to: CGPoint(x: rect.minX, y: rect.minY)); p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY)); p.closeSubpath(); return p
    }
}

extension Array { subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil } }
