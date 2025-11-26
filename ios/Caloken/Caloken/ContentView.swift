import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    // @State private var showRecordMenu = false  // コメントアウト
    
    var body: some View {
        // ZStack {  // コメントアウト
            TabView(selection: $selectedTab) {
                S24_HomeView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("ホーム")
                    }
                    .tag(0)
                
                S38_ProgressView()
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text("進捗")
                    }
                    .tag(1)
                
                // 記録タブを追加
                S39_RecordMenuView()
                    .tabItem {
                        Image(systemName: "plus.circle.fill")
                        Text("記録")
                    }
                    .tag(2)
                
                S26_NewsView()
                    .tabItem {
                        Image(systemName: "newspaper.fill")
                        Text("ニュース")
                    }
                    .tag(3)
                
                S27_1_SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("設定")
                    }
                    .tag(4)
            }
            .tint(Color.appBrown)
            
            // 中央の浮いている+ボタン（コメントアウト - 後で復活させるかも）
            /*
            VStack {
                Spacer()
                Button(action: {
                    showRecordMenu = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.appBrown)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                .offset(y: -30)
            }
            */
        // }  // コメントアウト
        /*
        .sheet(isPresented: $showRecordMenu) {
            S39_RecordMenuView()
        }
        */
    }
}

#Preview {
    ContentView()
}
