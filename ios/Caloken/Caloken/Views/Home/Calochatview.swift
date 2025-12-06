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
        return [ChatMessage(isUser: false, text: "こんにちは！カロちゃんだにゃ🐱\n今日の食事や運動について何でも聞いてね！", image: nil)]
    }
    
    func addMessage(_ message: ChatMessage, for date: Date) {
        let key = dateKey(for: date)
        if messagesByDate[key] == nil {
            messagesByDate[key] = [ChatMessage(isUser: false, text: "こんにちは！カロちゃんだにゃ🐱\n今日の食事や運動について何でも聞いてね！", image: nil)]
        }
        messagesByDate[key]?.append(message)
        objectWillChange.send()
        saveMessages()
    }
    
    private func saveMessages() {
        var savableData: [String: [[String: Any]]] = [:]
        for (key, messages) in messagesByDate {
            savableData[key] = messages.map { msg in
                var dict: [String: Any] = [
                    "isUser": msg.isUser,
                    "text": msg.text ?? ""
                ]
                // 画像をBase64でエンコードして保存
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
                // Base64から画像を復元
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

// 文字数制限
private let maxCharacterCount = 1000

// MARK: - カロちゃんチャット画面
struct CaloChatView: View {
    let selectedDate: Date
    @Binding var isPresented: Bool
    
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var selectedItem: PhotosPickerItem?
    @State private var pendingImage: UIImage? = nil  // 送信待ち画像
    @State private var isTyping: Bool = false
    @State private var typingTask: Task<Void, Never>?
    
    private let chatManager = ChatMessagesManager.shared
    private let responseTimeout: TimeInterval = 10.0  // タイムアウト10秒
    
    // 送信可能かどうか
    private var canSend: Bool {
        !isTyping && (!messageText.isEmpty || pendingImage != nil)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 日付表示
            HStack {
                Spacer()
                Text(formatDate(selectedDate))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.vertical, 8)
            .background(Color(UIColor.systemGroupedBackground))
            
            // チャットメッセージ一覧
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                        
                        // タイピング中のインジケーター
                        if isTyping {
                            TypingIndicator()
                                .id("typing")
                        }
                    }
                    .padding(16)
                }
                .onChange(of: messages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: isTyping) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
            }
            
            // 入力エリア（角丸）
            VStack(spacing: 8) {
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
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                }
                
                // 文字数カウンター（入力中のみ表示）
                if !messageText.isEmpty {
                    HStack {
                        Spacer()
                        Text("\(messageText.count)/\(maxCharacterCount)")
                            .font(.system(size: 11))
                            .foregroundColor(messageText.count > maxCharacterCount ? .red : .secondary)
                    }
                    .padding(.horizontal, 16)
                }
                
                // 入力欄
                HStack(spacing: 12) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Image(systemName: pendingImage == nil ? "photo" : "photo.fill")
                            .font(.system(size: 22))
                            .foregroundColor(pendingImage == nil ? .secondary : .orange)
                    }
                    .disabled(isTyping || pendingImage != nil)  // 1枚のみ
                    .onChange(of: selectedItem) { _, newItem in
                        handleImageSelection(newItem)
                    }
                    
                    TextField("メッセージを入力...", text: $messageText)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                        .cornerRadius(20)
                        .disabled(isTyping)
                        .submitLabel(.send)
                        .onSubmit {
                            if canSend {
                                sendMessage()
                            }
                        }
                        .onChange(of: messageText) { _, newValue in
                            // 文字数制限
                            if newValue.count > maxCharacterCount {
                                messageText = String(newValue.prefix(maxCharacterCount))
                            }
                        }
                    
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(canSend ? Color.orange : Color.gray)
                            .clipShape(Circle())
                    }
                    .disabled(!canSend)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .background(
                RoundedCornerShape(corners: [.topLeft, .topRight], radius: 20)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
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
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                if isTyping {
                    proxy.scrollTo("typing", anchor: .bottom)
                } else if let lastMessage = messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
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
    
    private func handleImageSelection(_ newItem: PhotosPickerItem?) {
        guard let newItem = newItem else { return }
        
        Task {
            if let data = try? await newItem.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    // 画像を送信待ちにセット（すぐには送信しない）
                    withAnimation {
                        pendingImage = uiImage
                    }
                    selectedItem = nil
                }
            }
        }
    }
    
    private func sendMessage() {
        // テキストも画像もない場合は送信しない
        guard !messageText.isEmpty || pendingImage != nil else { return }
        
        // メッセージを作成（テキストと画像の両方を含む可能性あり）
        let textToSend = messageText.isEmpty ? nil : messageText
        let imageToSend = pendingImage
        
        let userMessage = ChatMessage(isUser: true, text: textToSend, image: imageToSend)
        messages.append(userMessage)
        chatManager.addMessage(userMessage, for: selectedDate)
        
        // 入力内容をクリア
        let userText = messageText.isEmpty ? "画像が送信されました" : messageText
        messageText = ""
        pendingImage = nil
        
        sendResponseWithTimeout(for: userText)
    }
    
    private func sendResponseWithTimeout(for userText: String) {
        isTyping = true
        
        typingTask = Task {
            do {
                // タイムアウト付きで応答を待つ
                try await withTimeout(seconds: responseTimeout) {
                    // 実際のAI応答をシミュレート（1〜2秒）
                    try await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...2_000_000_000))
                }
                
                if !Task.isCancelled {
                    await MainActor.run {
                        let response = generateResponse(for: userText)
                        let responseMessage = ChatMessage(isUser: false, text: response, image: nil)
                        messages.append(responseMessage)
                        chatManager.addMessage(responseMessage, for: selectedDate)
                        isTyping = false
                    }
                }
            } catch {
                // タイムアウトまたはキャンセル
                if !Task.isCancelled {
                    await MainActor.run {
                        let errorMessage = ChatMessage(isUser: false, text: "ごめんにゃ😿 応答に時間がかかりすぎたにゃ...もう一度試してね！", image: nil)
                        messages.append(errorMessage)
                        chatManager.addMessage(errorMessage, for: selectedDate)
                        isTyping = false
                    }
                }
            }
        }
    }
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    private func generateResponse(for message: String) -> String {
        if message.contains("画像") {
            return "画像を受け取ったにゃ🐱 美味しそうだね！これは約350kcalくらいかにゃ？"
        } else if message.contains("タンパク質") || message.contains("肉") {
            return "タンパク質を増やすなら、鶏むね肉や卵がおすすめだにゃ！🍗 今日あと100g摂ると目標達成できるよ！"
        } else if message.contains("運動") {
            return "今日は3,982歩歩いたね！あと6,000歩で目標達成だにゃ🏃‍♂️ 夕方に少し散歩するのはどう？"
        } else if message.contains("カロリー") {
            return "今日の摂取カロリーは順調だにゃ！このペースで頑張ろう！🔥"
        } else {
            return "なるほど！今日のカロリーは順調だにゃ😊 このペースで頑張ろう！"
        }
    }
}

// MARK: - タイムアウトエラー
struct TimeoutError: Error {}

// MARK: - タイピングインジケーター
struct TypingIndicator: View {
    @State private var dotCount = 0
    
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // カロちゃんのアイコン
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

// MARK: - チャット吹き出し
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
                            .frame(maxWidth: 220)
                            .cornerRadius(12)
                    }
                    if let text = message.text, !text.isEmpty {
                        Text(text)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.orange)
                            .cornerRadius(16)
                    }
                }
            } else {
                // カロちゃんのアイコン
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
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .padding(12)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(16)
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

// MARK: - 上だけ角丸のShape（チャット用）
private struct RoundedCornerShape: Shape {
    var corners: UIRectCorner
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
