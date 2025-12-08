import SwiftUI

struct S43_ChatView: View {
    @Environment(\.dismiss) var dismiss
    @State private var messageText: String = ""
    @State private var messages: [ChatMessage] = []
    @State private var isLoading: Bool = false
    @FocusState private var isInputFocused: Bool
    
    // スクロール用
    @State private var scrollProxy: ScrollViewProxy?
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            headerView
            
            // チャットエリア
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                        
                        // ローディング表示
                        if isLoading {
                            HStack {
                                TypingIndicator()
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .id("loading")
                        }
                    }
                    .padding(.vertical, 16)
                }
                .onAppear {
                    scrollProxy = proxy
                    loadTodayMessages()
                    // 少し遅延してスクロール
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        scrollToBottom(proxy: proxy, animated: false)
                    }
                }
                .onChange(of: messages.count) { _, _ in
                    scrollToBottom(proxy: proxy, animated: true)
                }
            }
            
            // 入力エリア
            inputArea
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarHidden(true)
        .onTapGesture {
            isInputFocused = false
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                // カロちゃんアイコン
                if UIImage(named: "calo_icon") != nil {
                    Image("calo_icon")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay(Text("🐱").font(.system(size: 18)))
                }
                
                Text("カロちゃん")
                    .font(.system(size: 17, weight: .semibold))
            }
            
            Spacer()
            
            // 履歴クリアボタン
            Button(action: { clearTodayMessages() }) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
    }
    
    // MARK: - Input Area
    private var inputArea: some View {
        HStack(spacing: 12) {
            // テキスト入力
            HStack {
                TextField("メッセージを入力...", text: $messageText, axis: .vertical)
                    .lineLimit(1...4)
                    .focused($isInputFocused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(20)
            
            // 送信ボタン
            Button(action: { sendMessage() }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(messageText.isEmpty ? .gray : .orange)
            }
            .disabled(messageText.isEmpty || isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
    }
    
    // MARK: - Functions
    
    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        if let lastMessage = messages.last {
            if animated {
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            } else {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        } else if isLoading {
            if animated {
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo("loading", anchor: .bottom)
                }
            } else {
                proxy.scrollTo("loading", anchor: .bottom)
            }
        }
    }
    
    private func loadTodayMessages() {
        // UserDefaultsから今日のメッセージを読み込み
        let key = chatHistoryKey(for: Date())
        if let data = UserDefaults.standard.data(forKey: key),
           let savedMessages = try? JSONDecoder().decode([ChatMessage].self, from: data) {
            messages = savedMessages
        } else {
            // 初回は挨拶メッセージ
            let greeting = ChatMessage(
                text: "こんにちは！カロちゃんだにゃ🐱 今日の食事や健康について何でも聞いてにゃ！",
                isUser: false
            )
            messages = [greeting]
            saveTodayMessages()
        }
    }
    
    private func saveTodayMessages() {
        let key = chatHistoryKey(for: Date())
        if let data = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    private func clearTodayMessages() {
        messages = []
        let key = chatHistoryKey(for: Date())
        UserDefaults.standard.removeObject(forKey: key)
        
        // 挨拶メッセージを追加
        let greeting = ChatMessage(
            text: "履歴をクリアしたにゃ！また何でも聞いてにゃ🐱",
            isUser: false
        )
        messages = [greeting]
        saveTodayMessages()
    }
    
    private func chatHistoryKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "chat_history_\(formatter.string(from: date))"
    }
    
    private func sendMessage() {
        let userText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userText.isEmpty else { return }
        
        // ユーザーメッセージを追加
        let userMessage = ChatMessage(text: userText, isUser: true)
        messages.append(userMessage)
        messageText = ""
        isInputFocused = false
        isLoading = true
        
        // 保存
        saveTodayMessages()
        
        // APIリクエスト
        Task {
            await sendToAPI(userText: userText)
        }
    }
    
    private func sendToAPI(userText: String) async {
        // 今日の食事情報を取得
        let todayMeals = getTodayMealsDescription()
        let todayCalories = getTodayCalories()
        
        // 会話履歴を準備（APIに送る形式）
        let chatHistory = messages.dropLast().suffix(10).map { msg in
            ["is_user": msg.isUser, "message": msg.text] as [String: Any]
        }
        
        do {
            let response = try await NetworkManager.shared.sendChatWithHistory(
                message: userText,
                chatHistory: chatHistory,
                todayMeals: todayMeals,
                todayCalories: todayCalories
            )
            
            await MainActor.run {
                let aiMessage = ChatMessage(text: response, isUser: false)
                messages.append(aiMessage)
                isLoading = false
                saveTodayMessages()
            }
        } catch {
            await MainActor.run {
                let errorMessage = ChatMessage(
                    text: "ごめんにゃ、うまく返事できなかったにゃ...😿 もう一度試してにゃ！",
                    isUser: false
                )
                messages.append(errorMessage)
                isLoading = false
                saveTodayMessages()
            }
        }
    }
    
    private func getTodayMealsDescription() -> String {
        let todayLogs = MealLogsManager.shared.logs.filter { log in
            Calendar.current.isDateInToday(log.date)
        }
        
        if todayLogs.isEmpty {
            return ""
        }
        
        return todayLogs.map { "\($0.name)(\($0.calories)kcal)" }.joined(separator: ", ")
    }
    
    private func getTodayCalories() -> Int {
        return MealLogsManager.shared.logs
            .filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.calories }
    }
}

// MARK: - ChatMessage Model
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date
    
    init(id: UUID = UUID(), text: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

// MARK: - Chat Bubble
struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 60)
                userBubble
            } else {
                aiBubble
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var userBubble: some View {
        Text(message.text)
            .font(.system(size: 15))
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.orange)
            .cornerRadius(18)
            .cornerRadius(4, corners: .bottomRight)
    }
    
    private var aiBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // カロちゃんアイコン
            if UIImage(named: "calo_icon") != nil {
                Image("calo_icon")
                    .resizable()
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 28, height: 28)
                    .overlay(Text("🐱").font(.system(size: 14)))
            }
            
            Text(message.text)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(18)
                .cornerRadius(4, corners: .bottomLeft)
        }
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // カロちゃんアイコン
            Circle()
                .fill(Color.orange.opacity(0.2))
                .frame(width: 28, height: 28)
                .overlay(Text("🐱").font(.system(size: 14)))
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .offset(y: animationOffset)
                        .animation(
                            Animation.easeInOut(duration: 0.4)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.15),
                            value: animationOffset
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(18)
        }
        .onAppear {
            animationOffset = -5
        }
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    NavigationStack {
        S43_ChatView()
    }
}
