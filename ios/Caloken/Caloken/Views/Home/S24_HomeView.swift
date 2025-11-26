import SwiftUI

struct S24_HomeView: View {
    @State private var selectedDate = Date()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // カスタムヘッダー（スクロールと同期）
                HStack(spacing: 0) {
                    Image("caloken_character")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .offset(x: 4)
                    
                    Text("Caloken")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(Color.appBrown)
                        .offset(x: -4, y: -3)
                    
                    Spacer()
                }
                .padding(.top, 60)
                
                // カレンダー
                WeekCalendarView(selectedDate: $selectedDate)
                    .padding(.horizontal, 16)
                
                // メトリクス
                MetricsTabView()
                    .padding(.top, 4)  // 8 → 4 に変更
                
                // 最近のログ
                RecentLogsCard()
                    .padding(.horizontal, 16)
            }
        }
        .background(Color.appGray)
        .ignoresSafeArea(edges: .top)
    }
}


struct WeekCalendarView: View {
    @Binding var selectedDate: Date
    @State private var currentWeekOffset: Int = 0
    
    private let calendar = Calendar.current
    private let weekdays = ["月", "火", "水", "木", "金", "土", "日"]
    
    // 仮のログ記録データ
    private let hasLogDates: Set<Int> = [20, 24, 25]
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentWeekOffset) {
                ForEach(-52...52, id: \.self) { weekOffset in
                    weekView(offset: weekOffset)
                        .tag(weekOffset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 90)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func weekView(offset: Int) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { index in
                let date = getDate(for: index, weekOffset: offset)
                let day = calendar.component(.day, from: date)
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                let isToday = calendar.isDateInToday(date)
                let hasLog = hasLogDates.contains(day)
                
                VStack(spacing: 4) {
                    // 曜日（上）
                    Text(weekdays[index])
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                    
                    // 日付と背景（下）
                    ZStack {
                        if isToday {
                            // 今日：点線の円（茶色）
                            Circle()
                                .stroke(
                                    Color.appBrown,
                                    style: StrokeStyle(lineWidth: 2, dash: [3, 3])
                                )
                                .frame(width: 40, height: 40)
                        } else if hasLog {
                            // ログがある日：塗りつぶした円（茶色）
                            Circle()
                                .fill(Color.appBrown)
                                .frame(width: 40, height: 40)
                        } else {
                            // ログがない日：点線の円（グレー）
                            Circle()
                                .stroke(
                                    Color.gray.opacity(0.3),
                                    style: StrokeStyle(lineWidth: 2, dash: [3, 3])
                                )
                                .frame(width: 40, height: 40)
                        }
                        
                        // 選択中の強調表示
                        if isSelected && !isToday {
                            Circle()
                                .stroke(Color.appBrown, lineWidth: 3)
                                .frame(width: 44, height: 44)
                        }
                        
                        // 日付テキスト
                        Text("\(day)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(
                                hasLog && !isToday ? .white : .primary
                            )
                    }
                }
                .frame(maxWidth: .infinity)
                .onTapGesture {
                    selectedDate = date
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
    }
    
    private func getDate(for weekdayIndex: Int, weekOffset: Int) -> Date {
        let today = Date()
        
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        guard let startOfWeek = calendar.date(from: components) else {
            return today
        }
        
        guard let offsetWeek = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: startOfWeek) else {
            return today
        }
        
        return calendar.date(byAdding: .day, value: weekdayIndex, to: offsetWeek) ?? today
    }
}
struct MetricsTabView: View {
    @State private var currentPage = 0
    
    var body: some View {
        VStack(spacing: 4) {
            TabView(selection: $currentPage) {
                CalorieCardImproved()
                    .tag(0)
                
                ActivityCard()
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 380)  // 400 → 380
            
            HStack(spacing: 8) {
                ForEach(0..<2) { index in
                    Circle()
                        .fill(currentPage == index ? Color.appBrown : Color.gray.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.bottom, 4)
        }
    }
}

struct CalorieCardImproved: View {
    let current: Int = 2000
    let target: Int = 2740
    let exerciseBonus: Int = 250
    let hasExerciseRecord: Bool = true
    
    var progress: Double {
        return min(Double(current) / Double(target), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {  // 12 → 8
            VStack(spacing: 8) {
                ZStack {
                    SemiCircle()
                        .stroke(Color.gray.opacity(0.4), lineWidth: 20)
                        .frame(width: 240, height: 120)
                    
                    SemiCircle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.appBrown, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 240, height: 120)
                    
                    VStack(spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(current)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("/\(target)")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                if hasExerciseRecord {
                                    HStack(spacing: 2) {
                                        Image(systemName: "figure.run")
                                            .font(.system(size: 12, weight: .semibold))
                                        Text("+\(exerciseBonus)")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                    .offset(x: 6, y: 4)
                                }
                            }
                        }
                        
                        Text("摂取kcal")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                            .offset(y: 4)
                    }
                    .offset(y: 20)
                }
                .padding(.top, 12)  // 20 → 12
                .padding(.bottom, 4)  // 8 → 4
            }
            .frame(maxWidth: .infinity, minHeight: 190)  // 200 → 190
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            // 栄養素カード
            HStack(spacing: 8) {
                NutrientSemiCircleImproved(
                    current: 60,
                    target: 160,
                    color: Color.red.opacity(0.7),
                    icon: "🥩",
                    name: "たんぱく質"
                )
                
                NutrientSemiCircleImproved(
                    current: 60,
                    target: 69,
                    color: Color.blue,
                    icon: "🥑",
                    name: "脂質"
                )
                
                NutrientSemiCircleImproved(
                    current: 300,
                    target: 307,
                    color: Color.orange.opacity(0.7),
                    icon: "🍚",
                    name: "炭水化物"
                )
            }
            .padding(.vertical, 12)  // 16 → 12
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 140)  // 150 → 140
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)  // 8 → 4
    }
}

// 栄養素カード（改善版）
struct NutrientCardRow: View {
    var body: some View {
        HStack(spacing: 8) {
            NutrientSemiCircleImproved(
                current: 60,
                target: 160,
                color: Color.red.opacity(0.7),
                icon: "🥩",
                name: "たんぱく質"
            )
            
            NutrientSemiCircleImproved(
                current: 60,
                target: 69,
                color: Color.blue,
                icon: "🥑",
                name: "脂質"
            )
            
            NutrientSemiCircleImproved(
                current: 300,
                target: 307,
                color: Color.orange.opacity(0.7),
                icon: "🍚",
                name: "炭水化物"
            )
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 160)  // 130 → 160
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct NutrientSemiCircleImproved: View {
    let current: Int
    let target: Int
    let color: Color
    let icon: String
    let name: String
    var unit: String = "g"
    
    var progress: Double {
        return min(Double(current) / Double(target), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 6) {  // 10 → 6
            ZStack {
                SemiCircle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 90, height: 45)
                
                SemiCircle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 90, height: 45)
                
                Text(icon)
                    .font(.system(size: 26))
                    .offset(y: 14)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text("\(current)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(color)
                
                Text("/\(target)\(unit)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            Text(name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .offset(y: -4)  // -12 → -4
        }
        .frame(maxWidth: .infinity)
    }
}
struct ActivityCard: View {
    let steps: Int = 3982
    let target: Int = 10000
    let caloriesBurned: Int = 112
    
    var progress: Double {
        return min(Double(steps) / Double(target), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {  // 12 → 8
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("今日の歩数")
                        .font(.system(size: 18, weight: .medium))
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(steps)")
                            .font(.system(size: 36, weight: .bold))
                        Text("/ \(target)")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.primary.opacity(0.6))
                    }
                    
                    Spacer()
                        .frame(height: 4)  // 8 → 4
                    
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 32))
                        Text("\(caloriesBurned)")
                            .font(.system(size: 36, weight: .bold))
                            .offset(y: 1)
                        Text("kcal")
                            .font(.system(size: 26))
                            .foregroundColor(.gray)
                            .offset(y: 2)
                    }
                }
                .padding(.leading, 20)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 14)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    Text("👟")
                        .font(.system(size: 32))
                }
                .padding(.trailing, 20)
            }
            .frame(maxWidth: .infinity, minHeight: 190)  // 180 → 190（カロリーカードと合わせる）
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            // 栄養素カード
            HStack(spacing: 8) {
                NutrientSemiCircleImproved(
                    current: 20,
                    target: 25,
                    color: .purple,
                    icon: "🍬",
                    name: "糖分"
                )
                
                NutrientSemiCircleImproved(
                    current: 1,
                    target: 28,
                    color: .orange,
                    icon: "🌾",
                    name: "食物繊維"
                )
                
                NutrientSemiCircleImproved(
                    current: 100,
                    target: 1800,
                    color: .gray,
                    icon: "🧂",
                    name: "ナトリウム",
                    unit: "mg"
                )
            }
            .padding(.vertical, 12)  // 16 → 12
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 140)  // 150 → 140
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)  // 8 → 4
    }
}

struct NutrientSemiCircle: View {
    let current: Int
    let target: Int
    let color: Color
    let icon: String
    let name: String
    var unit: String = "g"
    
    var progress: Double {
        return min(Double(current) / Double(target), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {  // 4 → 8
            ZStack {
                SemiCircle()
                    .stroke(Color.appLightGray, lineWidth: 10)  // 7 → 10
                    .frame(width: 80, height: 40)  // 60, 30 → 80, 40
                
                SemiCircle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 80, height: 40)
                
                Text(icon)
                    .font(.system(size: 24))  // 18 → 24
                    .offset(y: 12)  // 8 → 12
            }
            
            Text("\(current)/\(target)\(unit)")
                .font(.system(size: 16, weight: .bold))  // 12 → 16, .semibold → .bold
                .offset(y: 4)
                .foregroundColor(.primary)
            
            Text(name)
                .font(.system(size: 14, weight: .medium))  // 10 → 14, 太さ追加
                .foregroundColor(.primary)  // .gray → .primary（黒に）
        }
        .frame(maxWidth: .infinity)
    }
}

struct SemiCircle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.maxY),
            radius: rect.width / 2,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        return path
    }
}

// 最近のログ（改善版）
struct RecentLogsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            Text("最近のログ")
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 4)
            
            // ログアイテム（それぞれ独立したカード）
            MealLogItem(
                imageName: "meal_fried_rice",
                name: "炒飯セット",
                time: "22:28",
                calories: 1200,
                protein: 45,
                fat: 30,
                carbs: 150
            )
            
            MealLogItem(
                imageName: "meal_udon",
                name: "うどん",
                time: "15:06",
                calories: 800,
                protein: 20,
                fat: 10,
                carbs: 120
            )
            
            ExerciseLogItem(
                icon: "figure.run",
                name: "ランニング",
                time: "14:30",
                caloriesBurned: 300,
                duration: 30
            )
        }
        .padding(.vertical, 8)
    }
}

// 食事ログアイテム
struct MealLogItem: View {
    let imageName: String
    let name: String
    let time: String
    let calories: Int
    let protein: Int
    let fat: Int
    let carbs: Int
    
    var body: some View {
        HStack(spacing: 0) {
            // 左側：食事画像
            if let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                // 画像がない場合は絵文字で代替
                Text("🍚")
                    .font(.system(size: 36))
                    .frame(width: 70, height: 70)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // 中央・右側の情報全体
            VStack(spacing: 0) {
                // 上部：名前と時間
                HStack(alignment: .top) {
                    Text(name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(time)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)  // グレー → 黒に変更
                }
                .padding(.bottom, 6)
                
                // 下部：カロリーと栄養素
                HStack(alignment: .bottom, spacing: 0) {
                    // カロリー（さらに大きく）
                    HStack(spacing: 1) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.orange)
                            .offset(y: -14)
                        
                        Text("\(calories)")
                            .font(.system(size: 36, weight: .bold))  // 24 → 32
                            .foregroundColor(.primary)
                            .offset(y: -14)
                        
                        Text("kcal")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                            .offset(y: -10)
                    }
                    
                    Spacer()
                    
                    // 3大栄養素（縦並び、右寄せ）
                    VStack(alignment: .trailing, spacing: 2) {  // .leading → .trailing
                        NutrientRow(icon: "🥩", value: protein, unit: "g", color: .red)
                        NutrientRow(icon: "🥑", value: fat, unit: "g", color: .blue)
                        NutrientRow(icon: "🍚", value: carbs, unit: "g", color: .orange)
                    }
                }
            }
            .padding(.leading, 10)
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)  // 影を少し強化
    }
}

// 運動ログアイテム
struct ExerciseLogItem: View {
    let icon: String
    let name: String
    let time: String
    let caloriesBurned: Int
    let duration: Int
    
    var body: some View {
        HStack(spacing: 0) {
            // 左側：アイコン
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.white)
                .frame(width: 70, height: 70)
                .background(
                    LinearGradient(  // グラデーション追加
                        colors: [Color.green, Color.green.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // 中央・右側の情報全体
            VStack(spacing: 0) {
                // 上部：名前と時間
                HStack(alignment: .top) {
                    Text(name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(time)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)  // グレー → 黒に変更
                }
                .padding(.bottom, 6)
                
                // 下部：消費カロリーと時間
                HStack(alignment: .bottom, spacing: 10) {
                    // 消費カロリー（大きく）
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.orange)
                            .offset(y: -6)
                        
                        Text("\(caloriesBurned)")
                            .font(.system(size: 36, weight: .bold))  // 24 → 32
                            .foregroundColor(.primary)
                            .offset(y: -6)
                        
                        Text("kcal")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                            .offset(y: -3)
                    }
                    
                    Spacer()
                    
                    // 運動時間
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                            .offset(y: -3)
                        
                        Text("\(duration)")
                            .font(.system(size: 24, weight: .bold))  // 20 → 24
                            .foregroundColor(.primary)
                            .offset(y: -3)
                        
                        Text("分")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .offset(y: -3)
                    }
                }
            }
            .padding(.leading, 12)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)  // 影を少し強化
    }
}

// 栄養素行（縦並び用）
struct NutrientRow: View {
    let icon: String
    let value: Int
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(icon)
                .font(.system(size: 14))
            Text("\(value)\(unit)")
                .font(.system(size: 14, weight: .semibold))  // 13 → 14
                .foregroundColor(color)
        }
    }
}

#Preview {
    S24_HomeView()
}
