import SwiftUI

struct S38_ProgressView: View {
    @State private var selectedPeriod: Period = .week
    @State private var currentWeight: Double = 71.5
    @State private var targetWeight: Double = 68.0
    @State private var targetDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date())!
    @State private var consecutiveDays: Int = 7
    @State private var calorieSavings: Int = 2450
    
    enum Period: String, CaseIterable {
            case week = "1週間"
            case month = "1ヶ月"
            case sixMonths = "6ヶ月"
            case year = "1年"
            case all = "ALL"
        }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 目標と記録日数（横並び）
                    HStack(spacing: 12) {
                        WeightGoalCard(
                            current: currentWeight,
                            target: targetWeight,
                            targetDate: targetDate
                        )
                        ConsecutiveDaysCard(
                            days: consecutiveDays,
                            weekRecords: [false, false, false, true, false, false, false]  // 仮データ：水曜のみ記録
                        )
                    }
                    
                    // 消費カロリー総量
                    VStack(alignment: .leading, spacing: 8) {
                        
                        CalorieSavingsCard(totalCalories: calorieSavings)
                    }
                    
                    // 期間選択
                    PeriodSelector(selectedPeriod: $selectedPeriod)
                    
                    // 体重推移グラフ
                    WeightChartCard(period: selectedPeriod)
                    
                    // カロリー推移グラフ
                    CalorieChartCard(period: selectedPeriod)
                    
                    
                    // BMIカード
                    BMICard(bmi: 21.8, status: "適正")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(Color.appGray)
            .navigationTitle("進捗")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
        }
    }
}
struct CalorieSavingsCard: View {
    let totalCalories: Int
    
    private var fatKg: Double {
        Double(abs(totalCalories)) / 7200.0
    }
    
    private var isPositive: Bool {
        totalCalories >= 0
    }
    
    private var formattedCalories: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = NSNumber(value: abs(totalCalories))
        let formatted = formatter.string(from: number) ?? "\(abs(totalCalories))"
        return (isPositive ? "+" : "-") + formatted
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .bottom, spacing: 16) {
                // 左側：カロリー
                VStack(alignment: .center, spacing: 4) {
                    Text("消費カロリー総量")
                        .font(.system(size: 13, weight: .semibold))
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        Text(formattedCalories)
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(isPositive ? .red : .blue)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        
                        Text("kcal")
                            .font(.system(size: 22))
                            .foregroundColor(.gray)
                            .padding(.bottom, 6)
                    }
                }
                
                Spacer()
                
                // 右側：脂肪換算
                VStack(alignment: .center, spacing: 4) {
                    Text("減った脂肪量")
                        .font(.system(size: 14))
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("🔥")
                            .font(.system(size: 32))
                            .padding(.bottom, 2)
                        Text(String(format: "%.2f", fatKg))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        Text("kg")
                            .font(.system(size: 22))
                            .foregroundColor(.gray)
                            .padding(.bottom, 4)
                    }
                }
            }
            .padding(12)
            
            // 右上のはてなマーク
            NavigationLink(destination: FatExplanationView()) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 18))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .padding(12)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct FatExplanationView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("減った脂肪量とは？")
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("摂取カロリーと消費カロリーの差から、理論上減少した脂肪量を計算した値です。")
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .lineSpacing(4)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("計算方法")
                        .font(.system(size: 18, weight: .bold))
                    
                    Text("体脂肪1kgを減らすためには、約7,200kcalのカロリー消費が必要とされています。")
                        .font(.system(size: 15))
                        .lineSpacing(4)
                    
                    Text("これは、脂肪1gあたり約9kcalのエネルギーを持っていますが、体脂肪細胞には水分や細胞膜などが約20%含まれているため、純粋な脂肪は約80%となります。")
                        .font(.system(size: 15))
                        .lineSpacing(4)
                    
                    Text("9kcal × 1,000g × 80% ＝ 約7,200kcal")
                        .font(.system(size: 15, weight: .semibold))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    Text("このアプリでは、目標摂取カロリーと実際の摂取カロリーの差を累計し、7,200kcalで割ることで減った脂肪量を算出しています。")
                        .font(.system(size: 15))
                        .lineSpacing(4)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("1ヶ月で1kg減らすには？")
                        .font(.system(size: 18, weight: .bold))
                    
                    Text("1ヶ月で1kgの脂肪を減らすためには、1日あたり約240kcal（7,200kcal ÷ 30日）のカロリー欠損が必要です。")
                        .font(.system(size: 15))
                        .lineSpacing(4)
                    
                    Text("240kcalの目安：")
                        .font(.system(size: 15, weight: .semibold))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("・ウォーキング約50分")
                        Text("・ジョギング約27分")
                        Text("・どら焼き1個分")
                        Text("・ビール中ジョッキ約1杯分")
                    }
                    .font(.system(size: 15))
                    .padding(.leading, 8)
                }
                
                Divider()
                
                // 注意事項
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("注意事項")
                            .font(.system(size: 18, weight: .bold))
                    }
                    
                    Text("この数値はあくまで理論上の推定値であり、実際の脂肪減少量を保証するものではありません。")
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .lineSpacing(4)
                    
                    Text("実際の脂肪減少量は、個人の基礎代謝、運動量、体質、ホルモンバランス、睡眠の質など、様々な要因によって異なります。")
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .lineSpacing(4)
                    
                    Text("健康的なダイエットのためには、極端な食事制限を避け、バランスの良い食事と適度な運動を心がけてください。")
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .lineSpacing(4)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(20)
        }
        .background(Color.appGray)
        .navigationTitle("減った脂肪量とは？")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// 体重目標カード
struct WeightGoalCard: View {
    let current: Double
    let target: Double
    let targetDate: Date
    
    var progress: Double {
        let startWeight = 78.0
        let totalLoss = startWeight - target
        let currentLoss = startWeight - current
        return min(max(currentLoss / totalLoss, 0), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("現在の体重")
                    .font(.system(size: 13))
                
                Text(String(format: "%.1f kg", current))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: geometry.size.width * progress, height: 4)
                            .cornerRadius(2)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 20)
                
                Text("目標 \(String(format: "%.0f", target)) kg")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            Spacer(minLength: 0)
            
            // ここを S49_WeightRecordView に変更
            NavigationLink(destination: S49_WeightRecordView(currentWeight: current)) {
                HStack {
                    Text("体重を記録")
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.black)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(Color.white)
        .cornerRadius(16)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ConsecutiveDaysCard: View {
    let days: Int
    let weekRecords: [Bool]
    
    let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
    
    private var todayIndex: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return weekday - 1
    }
    
    private var hasStreak: Bool {
        days > 0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 0)
            
            Image(systemName: "flame.fill")
                .font(.system(size: 44))
                .foregroundColor(hasStreak ? .orange : .gray.opacity(0.3))
            
            if hasStreak {
                Text("連続記録：\(days)日")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            } else {
                Text("連続記録が途切れました")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer(minLength: 0)
            
            HStack(spacing: 10) {
                ForEach(0..<7) { index in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(weekRecords[index] ? Color.appBrown : Color.gray.opacity(0.3))
                            .frame(width: 10, height: 10)
                        
                        Text(weekdays[index])
                            .font(.system(size: 12, weight: index == todayIndex ? .bold : .regular))
                            .foregroundColor(index == todayIndex ? .orange : .gray)
                    }
                }
            }
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// 期間選択
struct PeriodSelector: View {
    @Binding var selectedPeriod: S38_ProgressView.Period
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(S38_ProgressView.Period.allCases, id: \.self) { period in
                Button(action: {
                    selectedPeriod = period
                }) {
                    Text(period.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selectedPeriod == period ? .white : .gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedPeriod == period ? Color.appBrown : Color.white
                        )
                        .cornerRadius(20)
                }
            }
        }
        .padding(.horizontal, 4)
    }
}
// カロリー推移グラフ
struct CalorieChartCard: View {
    let period: S38_ProgressView.Period
    
    private var dataPoints: [Int] {
        switch period {
        case .week:
            return [1800, 2100, 1900, 2300, 2000, 1850, 2200]
        case .month:
            return [1900, 2000, 2150, 1800, 2100, 1950, 2050, 1900, 2200, 1850, 2000, 2100, 1950, 2000, 1900, 2150, 2050, 1800, 2100, 1900, 2000, 2150, 1950, 2000, 1850, 2100, 1900, 2050, 2000, 1950]
        case .sixMonths:
            return [2100, 2050, 1980, 1950, 1920, 1900]
        case .year:
            return [2200, 2150, 2100, 2050, 2000, 1980, 1950, 1920, 1900, 1880, 1860, 1850]
        case .all:
            return [2300, 2200, 2150, 2100, 2050, 2000, 1980, 1950, 1920, 1900, 1880, 1860, 1850, 1840, 1830]
        }
    }
    
    private var xAxisLabels: [String] {
        switch period {
        case .week:
            return ["月", "火", "水", "木", "金", "土", "日"]
        case .month:
            return ["1", "5", "10", "15", "20", "25", "30"]
        case .sixMonths:
            return ["6月", "7月", "8月", "9月", "10月", "11月"]
        case .year:
            return ["1月", "3月", "5月", "7月", "9月", "11月"]
        case .all:
            return ["開始", "", "", "", "", "", "", "", "", "", "", "", "", "", "現在"]
        }
    }
    
    let yAxisLabels = [2500, 2000, 1500, 1000, 500, 0]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カロリー推移")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray)
            
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(yAxisLabels, id: \.self) { value in
                        Text("\(value)")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        if value != 0 {
                            Spacer()
                        }
                    }
                }
                .frame(width: 35, height: 200)
                
                ZStack {
                    VStack(spacing: 0) {
                        ForEach(0..<5) { _ in
                            Divider()
                            Spacer()
                        }
                        Divider()
                    }
                    
                    GeometryReader { geometry in
                        Path { path in
                            let maxValue = 2500.0
                            let width = geometry.size.width
                            let height = geometry.size.height
                            let stepX = width / CGFloat(dataPoints.count - 1)
                            
                            for (index, value) in dataPoints.enumerated() {
                                let x = CGFloat(index) * stepX
                                let y = height - (CGFloat(value) / CGFloat(maxValue) * height)
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color.appBrown, lineWidth: 2)
                        
                        ForEach(0..<dataPoints.count, id: \.self) { index in
                            let maxValue = 2500.0
                            let stepX = geometry.size.width / CGFloat(dataPoints.count - 1)
                            let x = CGFloat(index) * stepX
                            let y = geometry.size.height - (CGFloat(dataPoints[index]) / CGFloat(maxValue) * geometry.size.height)
                            
                            Circle()
                                .fill(Color.appBrown)
                                .frame(width: 6, height: 6)
                                .position(x: x, y: y)
                        }
                    }
                }
                .frame(height: 200)
            }
            
            HStack {
                Spacer().frame(width: 43)
                ForEach(xAxisLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// 体重推移グラフ
struct WeightChartCard: View {
    let period: S38_ProgressView.Period
    
    private var dataPoints: [Double] {
        switch period {
        case .week:
            return [72.5, 72.3, 72.0, 71.8, 71.5, 71.3, 71.0]
        case .month:
            return [74.0, 73.8, 73.5, 73.3, 73.0, 72.8, 72.5, 72.3, 72.0, 71.8, 71.5, 71.3, 71.0]
        case .sixMonths:
            return [76.0, 75.0, 74.0, 73.0, 72.0, 71.0]
        case .year:
            return [78.0, 77.0, 76.0, 75.0, 74.5, 74.0, 73.5, 73.0, 72.5, 72.0, 71.5, 71.0]
        case .all:
            return [80.0, 79.0, 78.0, 77.0, 76.0, 75.0, 74.0, 73.5, 73.0, 72.5, 72.0, 71.5, 71.0]
        }
    }
    
    private var xAxisLabels: [String] {
        switch period {
        case .week:
            return ["月", "火", "水", "木", "金", "土", "日"]
        case .month:
            return ["1", "5", "10", "15", "20", "25", "30"]
        case .sixMonths:
            return ["6月", "7月", "8月", "9月", "10月", "11月"]
        case .year:
            return ["1月", "3月", "5月", "7月", "9月", "11月"]
        case .all:
            return ["開始", "", "", "", "", "", "", "", "", "", "", "", "現在"]
        }
    }
    
    private var yAxisRange: (min: Double, max: Double) {
        let minVal = (dataPoints.min() ?? 70.0) - 1
        let maxVal = (dataPoints.max() ?? 75.0) + 1
        return (min: floor(minVal), max: ceil(maxVal))
    }
    
    private var yAxisLabels: [Double] {
        let range = yAxisRange
        let step = (range.max - range.min) / 5
        return (0...5).map { range.max - Double($0) * step }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("体重推移")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray)
            
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(yAxisLabels, id: \.self) { value in
                        Text(String(format: "%.0f", value))
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        if value != yAxisLabels.last {
                            Spacer()
                        }
                    }
                }
                .frame(width: 25, height: 200)
                
                ZStack {
                    VStack(spacing: 0) {
                        ForEach(0..<5) { _ in
                            Divider()
                            Spacer()
                        }
                        Divider()
                    }
                    
                    GeometryReader { geometry in
                        Path { path in
                            let range = yAxisRange
                            let rangeSpan = range.max - range.min
                            let width = geometry.size.width
                            let height = geometry.size.height
                            let stepX = width / CGFloat(dataPoints.count - 1)
                            
                            for (index, value) in dataPoints.enumerated() {
                                let x = CGFloat(index) * stepX
                                let normalizedValue = (value - range.min) / rangeSpan
                                let y = height - (CGFloat(normalizedValue) * height)
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color.blue, lineWidth: 2)
                        
                        ForEach(0..<dataPoints.count, id: \.self) { index in
                            let range = yAxisRange
                            let rangeSpan = range.max - range.min
                            let stepX = geometry.size.width / CGFloat(dataPoints.count - 1)
                            let x = CGFloat(index) * stepX
                            let normalizedValue = (dataPoints[index] - range.min) / rangeSpan
                            let y = geometry.size.height - (CGFloat(normalizedValue) * geometry.size.height)
                            
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 6, height: 6)
                                .position(x: x, y: y)
                        }
                    }
                }
                .frame(height: 200)
            }
            
            HStack {
                Spacer().frame(width: 33)
                ForEach(xAxisLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// BMIカード
struct BMICard: View {
    let bmi: Double
    let status: String
    
    private var bmiPosition: Double {
        let minBMI = 16.0
        let maxBMI = 32.0
        let clamped = min(max(bmi, minBMI), maxBMI)
        return (clamped - minBMI) / (maxBMI - minBMI)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your BMI")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray)
                
                Spacer()
                
                NavigationLink(destination: BMIDetailView(bmi: bmi, status: status)) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                }
            }
            
            HStack(alignment: .center, spacing: 12) {
                Text(String(format: "%.1f", bmi))
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Your weight is")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Text(status)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.green)
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
                        .fill(Color.black)
                        .frame(width: 3, height: 20)
                        .cornerRadius(1.5)
                        .position(x: geometry.size.width * bmiPosition, y: 4)
                }
            }
            .frame(height: 20)
            
            HStack(spacing: 0) {
                Label("低体重", systemImage: "circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.cyan)
                Spacer()
                Label("適正", systemImage: "circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.green)
                Spacer()
                Label("過体重", systemImage: "circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.yellow)
                Spacer()
                Label("肥満", systemImage: "circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.red)
            }
            .labelStyle(BMILabelStyle())
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// カスタムラベルスタイル
struct BMILabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon
                .font(.system(size: 8))
            configuration.title
        }
    }
}

// BMI詳細ページ
struct BMIDetailView: View {
    let bmi: Double
    let status: String
    
    private var bmiPosition: Double {
        let minBMI = 16.0
        let maxBMI = 32.0
        let clamped = min(max(bmi, minBMI), maxBMI)
        return (clamped - minBMI) / (maxBMI - minBMI)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Text("あなたの体重は")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        
                        Text(status)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    
                    Text(String(format: "%.1f", bmi))
                        .font(.system(size: 48, weight: .bold))
                    
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
                                .fill(Color.black)
                                .frame(width: 3, height: 20)
                                .cornerRadius(1.5)
                                .position(x: geometry.size.width * bmiPosition, y: 4)
                        }
                    }
                    .frame(height: 20)
                    
                    HStack(spacing: 0) {
                        Label("低体重", systemImage: "circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.cyan)
                        Spacer()
                        Label("適正", systemImage: "circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.green)
                        Spacer()
                        Label("過体重", systemImage: "circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.yellow)
                        Spacer()
                        Label("肥満", systemImage: "circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    }
                    .labelStyle(BMILabelStyle())
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("注意事項")
                        .font(.system(size: 18, weight: .bold))
                    
                    Text("他の多くの健康指標と同様に、BMIは完璧な指標ではありません。例えば、妊娠中や筋肉量が多い場合は結果が正確でないことがあります。また、子どもや高齢者の健康を測る指標としては適切でない場合があります。")
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .lineSpacing(4)
                    
                    Text("では、なぜBMIが重要なのでしょうか？")
                        .font(.system(size: 18, weight: .bold))
                        .padding(.top, 8)
                    
                    Text("一般的に、BMIが高いほど、体重過多に関連するさまざまな疾患のリスクが高まります。例えば：")
                        .font(.system(size: 15))
                        .lineSpacing(4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("・糖尿病")
                        Text("・関節炎")
                        Text("・肝臓病")
                        Text("・いくつかの種類のがん（乳がん、大腸がん、前立腺がんなど）")
                        Text("・高血圧")
                        Text("・高コレステロール")
                        Text("・睡眠時無呼吸症候群")
                    }
                    .font(.system(size: 15))
                    
                    Button(action: {}) {
                        Text("出典")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .underline()
                    }
                }
            }
            .padding(20)
        }
        .background(Color.appGray)
        .navigationTitle("BMI")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    S38_ProgressView()
}
