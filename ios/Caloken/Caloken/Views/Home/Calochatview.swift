import SwiftUI
import PhotosUI
import Combine

// MARK: - チャットメッセージマネージャー（日毎管理・画像対応）
final class ChatMessagesManager: ObservableObject {
    static let shared = ChatMessagesManager()
    
    private var messagesByDate: [String: [ChatMessage]] = [:]
    
    private let userDefaults = UserDefaults.standard
    private let storageKey = "chatMessages_v2"
    
    private init() {
        loadMessages()
    }
    
    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    func messages(for date: Date) -> [ChatMessage] {
        let key = dateKey(for: date)
        if let messages = messagesByDate[key], !messages.isEmpty {
            return messages
        }
        return []
    }
    
    func addMessage(_ message: ChatMessage, for date: Date) {
        let key = dateKey(for: date)
        if messagesByDate[key] == nil {
            messagesByDate[key] = []
        }
        messagesByDate[key]?.append(message)
        objectWillChange.send()
        saveMessages()
    }
    
    // 会話履歴をAPI送信用の形式に変換
    func chatHistoryForAPI(for date: Date) -> [[String: Any]] {
        let msgs = messages(for: date)
        return msgs.suffix(10).map { msg in
            [
                "is_user": msg.isUser,
                "message": msg.text ?? ""
            ] as [String: Any]
        }
    }
    
    private func saveMessages() {
        var savableData: [String: [[String: Any]]] = [:]
        for (key, messages) in messagesByDate {
            savableData[key] = messages.map { msg in
                var dict: [String: Any] = [
                    "isUser": msg.isUser,
                    "text": msg.text ?? ""
                ]
                if let image = msg.image,
                   let imageData = image.jpegData(compressionQuality: 0.5) {
                    dict["imageBase64"] = imageData.base64EncodedString()
                }
                return dict
            }
        }
        userDefaults.set(savableData, forKey: storageKey)
    }
    
    private func loadMessages() {
        guard let data = userDefaults.dictionary(forKey: storageKey) as? [String: [[String: Any]]] else { return }
        for (key, messagesData) in data {
            messagesByDate[key] = messagesData.map { dict in
                var image: UIImage? = nil
                if let base64String = dict["imageBase64"] as? String,
                   let imageData = Data(base64Encoded: base64String) {
                    image = UIImage(data: imageData)
                }
                return ChatMessage(
                    isUser: dict["isUser"] as? Bool ?? false,
                    text: dict["text"] as? String,
                    image: image
                )
            }
        }
    }
}

private let maxCharacterCount = 1000

// MARK: - カロちゃんチャット画面
struct CaloChatView: View {
    let selectedDate: Date
    @Binding var isPresented: Bool
    
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var selectedItem: PhotosPickerItem?
    @State private var pendingImage: UIImage? = nil
    @State private var isTyping: Bool = false
    @State private var typingTask: Task<Void, Never>?
    @State private var errorMessage: String?
    @State private var hasScrolledToBottom: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    private let chatManager = ChatMessagesManager.shared
    private let network = NetworkManager.shared
    private let profileManager = UserProfileManager.shared
    
    private var canSend: Bool {
        !isTyping && (!messageText.isEmpty || pendingImage != nil)
    }
    
    private var hasMessages: Bool {
        !messages.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 日付表示
            HStack {
                Spacer()
                Text(formatDate(selectedDate))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.vertical, 8)
            .background(Color(UIColor.systemGroupedBackground))
            
            if hasMessages {
                chatHistoryView
            } else {
                initialView
            }
            
            // エラーメッセージ
            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .padding(.vertical, 4)
            }
            
            // 入力エリア（チャット欄と一体化）
            inputArea
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("カロちゃんに相談")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    typingTask?.cancel()
                    isPresented = false
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
        }
        .enableSwipeBack()
        .onAppear {
            messages = chatManager.messages(for: selectedDate)
        }
        .onDisappear {
            typingTask?.cancel()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今日"
        } else if calendar.isDateInYesterday(date) {
            return "昨日"
        } else {
            formatter.dateFormat = "M月d日(E)"
            return formatter.string(from: date)
        }
    }
    
    private var initialView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            if UIImage(named: "caloken_character") != nil {
                Image("caloken_character")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
            } else {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(Text("🐱").font(.system(size: 40)))
            }
            
            VStack(spacing: 8) {
                Text("カロちゃんに相談")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("食事や運動について\n何でも聞いてね！")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    private var chatHistoryView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        ChatBubble(message: message)
                            .id(message.id)
                    }
                    
                    if isTyping {
                        TypingIndicator()
                            .id("typing")
                    }
                }
                .padding(16)
            }
            .onAppear {
                // 画面表示時に最新メッセージにスクロール
                if !hasScrolledToBottom {
                    scrollToBottomImmediate(proxy: proxy)
                    hasScrolledToBottom = true
                }
            }
            .onChange(of: messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: isTyping) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: isTextFieldFocused) { _, focused in
                if focused {
                    scrollToBottom(proxy: proxy)
                }
            }
        }
    }
    
    // MARK: - 入力エリア
    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider()
            
            // 選択画像プレビュー
            if let pendingImage = pendingImage {
                HStack {
                    Image(uiImage: pendingImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .cornerRadius(12)
                        .clipped()
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            self.pendingImage = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            
            // 文字数カウンター
            if !messageText.isEmpty {
                HStack {
                    Spacer()
                    Text("\(messageText.count)/\(maxCharacterCount)")
                        .font(.system(size: 12))
                        .foregroundColor(messageText.count > maxCharacterCount ? .red : .secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            
            // 入力欄
            HStack(spacing: 12) {
                // 画像添付ボタン
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Image(systemName: pendingImage == nil ? "plus" : "photo.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(pendingImage == nil ? .secondary : .orange)
                        .frame(width: 36, height: 36)
                }
                .disabled(isTyping || pendingImage != nil)
                .onChange(of: selectedItem) { _, newItem in
                    handleImageSelection(newItem)
                }
                
                // テキスト入力フィールド
                TextField("カロちゃんに相談", text: $messageText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 17))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.tertiarySystemFill))
                    .cornerRadius(22)
                    .focused($isTextFieldFocused)
                    .disabled(isTyping)
                    .submitLabel(.send)
                    .onSubmit {
                        if canSend {
                            sendMessage()
                        }
                    }
                    .onChange(of: messageText) { _, newValue in
                        if newValue.count > maxCharacterCount {
                            messageText = String(newValue.prefix(maxCharacterCount))
                        }
                    }
                
                // 送信ボタン
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(canSend ? Color.orange : Color.gray.opacity(0.5))
                        .clipShape(Circle())
                }
                .disabled(!canSend)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // 即時スクロール
    private func scrollToBottomImmediate(proxy: ScrollViewProxy) {
        if isTyping {
            proxy.scrollTo("typing", anchor: .bottom)
        } else if let lastMessage = messages.last {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
    
    // アニメーション付きスクロール
    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.2)) {
                if isTyping {
                    proxy.scrollTo("typing", anchor: .bottom)
                } else if let lastMessage = messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }
    
    private func handleImageSelection(_ newItem: PhotosPickerItem?) {
        guard let newItem = newItem else { return }
        
        Task {
            if let data = try? await newItem.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    withAnimation {
                        pendingImage = uiImage
                    }
                    selectedItem = nil
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty || pendingImage != nil else { return }
        
        let textToSend = messageText.isEmpty ? nil : messageText
        let imageToSend = pendingImage
        
        let userMessage = ChatMessage(isUser: true, text: textToSend, image: imageToSend)
        messages.append(userMessage)
        chatManager.addMessage(userMessage, for: selectedDate)
        
        let userText = messageText.isEmpty ? "画像を送信しました" : messageText
        messageText = ""
        pendingImage = nil
        errorMessage = nil
        
        // APIを呼び出し（ユーザー情報付き）
        sendToAPIWithUserContext(message: userText, image: imageToSend)
    }
    
    // MARK: - ユーザーコンテキストを取得
    private func getUserContext() -> [String: Any] {
        let pm = profileManager
        let wm = WeightLogsManager.shared
        let mm = MealLogsManager.shared
        let em = ExerciseLogsManager.shared
        
        // 今日の栄養素
        let nutrients = mm.totalNutrients(for: Date())
        let todayCalories = mm.totalCalories(for: Date())
        let todayExercise = em.totalCaloriesBurned(for: Date())
        
        return [
            // ユーザー基本情報
            "gender": pm.gender == "Male" ? "男性" : "女性",
            "age": pm.age,
            "height": pm.height,
            "current_weight": wm.currentWeight,
            "target_weight": wm.targetWeight,
            "bmi": String(format: "%.1f", pm.bmi),
            "bmi_status": pm.bmiStatus,
            
            // 目標
            "goal": pm.goal,  // 減量/維持/増量
            "exercise_frequency": pm.exerciseFrequency,
            
            // 栄養目標
            "calorie_goal": pm.calorieGoal,
            "protein_goal": pm.proteinGoal,
            "fat_goal": pm.fatGoal,
            "carb_goal": pm.carbGoal,
            
            // 今日の実績
            "today_calories": todayCalories,
            "today_protein": nutrients.protein,
            "today_fat": nutrients.fat,
            "today_carbs": nutrients.carbs,
            "today_exercise": todayExercise,
            
            // 残りカロリー
            "remaining_calories": pm.calorieGoal - todayCalories + todayExercise
        ]
    }
    
    // MARK: - API呼び出し（ユーザーコンテキスト付き）
    private func sendToAPIWithUserContext(message: String, image: UIImage?) {
        isTyping = true
        
        typingTask = Task {
            do {
                // 画像をBase64に変換
                var imageBase64: String? = nil
                if let image = image,
                   let imageData = image.jpegData(compressionQuality: 0.7) {
                    imageBase64 = imageData.base64EncodedString()
                }
                
                // ユーザーコンテキストを取得
                let userContext = getUserContext()
                
                // 会話履歴を取得
                let chatHistory = chatManager.chatHistoryForAPI(for: selectedDate)
                
                // API呼び出し
                let response = try await network.sendChatWithUserContext(
                    message: message,
                    imageBase64: imageBase64,
                    chatHistory: chatHistory,
                    userContext: userContext
                )
                
                if !Task.isCancelled {
                    await MainActor.run {
                        let responseMessage = ChatMessage(isUser: false, text: response, image: nil)
                        messages.append(responseMessage)
                        chatManager.addMessage(responseMessage, for: selectedDate)
                        isTyping = false
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        let fallbackMessage = generateFallbackResponse(for: message)
                        let errorMsg = ChatMessage(isUser: false, text: fallbackMessage, image: nil)
                        messages.append(errorMsg)
                        chatManager.addMessage(errorMsg, for: selectedDate)
                        isTyping = false
                        
                        print("❌ Chat API Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - フォールバック応答
    private func generateFallbackResponse(for message: String) -> String {
        if network.isDebugMode {
            return "ごめんにゃ😿 サーバーに接続できなかったみたい...もう一度試してほしいにゃ！"
        }
        
        if !network.isLoggedIn {
            return "ごめんにゃ😿 まだログインしてないみたい...ログインしてからもう一度話しかけてにゃ！"
        }
        
        return "ごめんにゃ😿 ちょっと調子が悪いみたい...もう一度試してほしいにゃ！"
    }
}

// MARK: - タイピングインジケーター
struct TypingIndicator: View {
    @State private var dotCount = 0
    
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if UIImage(named: "caloken_character") != nil {
                Image("caloken_character")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
            } else {
                Circle()
                    .fill(Color.orange.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(Text("🐱").font(.system(size: 24)))
            }
            
            HStack(alignment: .top, spacing: 0) {
                ChatBubbleArrowLeft()
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .frame(width: 10, height: 14)
                    .offset(y: 14)
                
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 8, height: 8)
                            .scaleEffect(dotCount == index ? 1.3 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: dotCount)
                    }
                }
                .padding(16)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
            }
            
            Spacer()
        }
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 3
        }
    }
}

// MARK: - チャットメッセージモデル
struct ChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String?
    let image: UIImage?
}

// MARK: - チャット吹き出し（ChatGPT風の大きめフォント）
struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    if let image = message.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 240)
                            .cornerRadius(12)
                    }
                    if let text = message.text, !text.isEmpty {
                        Text(text)
                            .font(.system(size: 16))  // ChatGPT風の大きさ
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.orange)
                            .cornerRadius(18)
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = text
                                } label: {
                                    Label("コピー", systemImage: "doc.on.doc")
                                }
                            }
                            .textSelection(.enabled)
                    }
                }
            } else {
                if UIImage(named: "caloken_character") != nil {
                    Image("caloken_character")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                } else {
                    Circle()
                        .fill(Color.orange.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(Text("🐱").font(.system(size: 24)))
                }
                
                HStack(alignment: .top, spacing: 0) {
                    ChatBubbleArrowLeft()
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                        .frame(width: 10, height: 14)
                        .offset(y: 14)
                    
                    if let text = message.text {
                        Text(text)
                            .font(.system(size: 16))  // ChatGPT風の大きさ
                            .foregroundColor(.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(18)
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = text
                                } label: {
                                    Label("コピー", systemImage: "doc.on.doc")
                                }
                            }
                            .textSelection(.enabled)
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - 吹き出し三角マーク（左向き）
struct ChatBubbleArrowLeft: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
