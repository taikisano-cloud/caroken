import SwiftUI

struct S49_WeightRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var weightLogsManager = WeightLogsManager.shared
    
    @State private var weightWhole: Int = 71
    @State private var weightDecimal: Int = 5
    
    init(currentWeight: Double? = nil) {
        let weight = currentWeight ?? WeightLogsManager.shared.currentWeight
        let whole = Int(weight)
        let decimal = Int((weight - Double(whole)) * 10)
        _weightWhole = State(initialValue: whole)
        _weightDecimal = State(initialValue: decimal)
    }
    
    private var currentWeight: Double {
        Double(weightWhole) + Double(weightDecimal) / 10.0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Text("現在の体重")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(String(format: "%.1f", currentWeight))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.primary)
                Text("kg")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.secondary)
                    .offset(y: -6)
            }
            .padding(.bottom, 40)
            
            HStack(spacing: 0) {
                Picker("", selection: $weightWhole) {
                    ForEach(30..<201) { value in
                        Text("\(value)")
                            .font(.system(size: 24, weight: .medium))
                            .tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 100)
                .clipped()
                
                Text(".")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Picker("", selection: $weightDecimal) {
                    ForEach(0..<10) { value in
                        Text("\(value)")
                            .font(.system(size: 24, weight: .medium))
                            .tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 60)
                .clipped()
                
                Text("kg")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.leading, 8)
            }
            .frame(height: 150)
            
            Spacer()
            
            Button(action: { saveWeight() }) {
                Text("記録する")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(colorScheme == .dark ? Color.white : Color.black)
                    .cornerRadius(30)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(Color(UIColor.systemBackground))
        .navigationTitle("体重を記録")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
        }
        .enableSwipeBack()
    }
    
    private func saveWeight() {
        weightLogsManager.addLog(currentWeight)
        
        // ホーム画面でトースト表示
        NotificationCenter.default.post(
            name: .showHomeToast,
            object: nil,
            userInfo: ["message": "体重 \(String(format: "%.1f", currentWeight))kg を記録しました", "color": Color.green]
        )
        
        // 即座にホームに戻る（通知だけでdismissは呼ばない）
        NotificationCenter.default.post(name: .dismissAllWeightScreens, object: nil)
    }
}
