import SwiftUI

struct S49_WeightRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var weightWhole: Int = 71
    @State private var weightDecimal: Int = 5
    
    init(currentWeight: Double = 71.5) {
        let whole = Int(currentWeight)
        let decimal = Int((currentWeight - Double(whole)) * 10)
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
                .padding(.bottom, 8)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(String(format: "%.1f", currentWeight))
                    .font(.system(size: 48, weight: .bold))
                Text("kg")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.gray)
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
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
            }
            .frame(height: 150)
            
            Spacer()
            
            Button(action: {
                dismiss()
            }) {
                Text("記録する")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.black)
                    .cornerRadius(30)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(Color.white)
        .navigationTitle("体重を記録")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        S49_WeightRecordView()
    }
}
