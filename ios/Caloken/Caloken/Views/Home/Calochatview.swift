import SwiftUI
import PhotosUI
import Combine
import Speech
import AVFoundation
import SafariServices  // ✅ 追加

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

// MARK: - カロちゃんチャット画面（Geminiスタイル）
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
    
    // 音声入力用
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var isRecording: Bool = false
    
    // ✅ モード切り替え用（fast: 高速モード, thinking: 思考モード）
    @State private var chatMode: String = "fast"
    
    private let chatManager = ChatMessagesManager.shared
    private let network = NetworkManager.shared
    private let profileManager = UserProfileManager.shared
    
    private var canSend: Bool {
        !isTyping && (!messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || pendingImage != nil)
    }
    
    private var hasMessages: Bool {
        !messages.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 日付表示
            dateHeader
            
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
            
            // 入力エリア（Geminiスタイル）
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
                    speechRecognizer.stopRecording()
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
            speechRecognizer.requestAuthorization()
        }
        .onDisappear {
            speechRecognizer.stopRecording()
        }
    }
    
    // MARK: - 日付ヘッダー
    private var dateHeader: some View {
        Text(formatDate(selectedDate))
            .font(.system(size: 13))
            .foregroundColor(.secondary)
            .padding(.vertical, 8)
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
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        ChatBubble(message: message)
                            .id(message.id)
                    }
                    
                    if isTyping {
                        TypingIndicator()
                            .id("typing")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .onAppear {
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
    
    // MARK: - 入力エリア（Geminiスタイル）
    private var inputArea: some View {
        VStack(spacing: 0) {
            // 選択画像プレビュー
            if let pendingImage = pendingImage {
                HStack {
                    Image(uiImage: pendingImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        .clipped()
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            self.pendingImage = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            
            // Geminiスタイル入力ボックス
            VStack(spacing: 0) {
                // テキスト入力エリア（上部）
                ZStack(alignment: .topLeading) {
                    if messageText.isEmpty && !isRecording {
                        Text("カロちゃんに相談...")
                            .font(.system(size: 16))
                            .foregroundColor(Color(UIColor.placeholderText))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 12)
                    }
                    
                    if isRecording {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text(speechRecognizer.transcript.isEmpty ? "聞いています..." : speechRecognizer.transcript)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 12)
                    } else {
                        TextEditor(text: $messageText)
                            .font(.system(size: 16))
                            .frame(minHeight: 36, maxHeight: 100)
                            .fixedSize(horizontal: false, vertical: true)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .focused($isTextFieldFocused)
                            .disabled(isTyping)
                            .onChange(of: messageText) { _, newValue in
                                if newValue.count > maxCharacterCount {
                                    messageText = String(newValue.prefix(maxCharacterCount))
                                }
                            }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 6)
                
                // ボタンエリア（下部）
                HStack(spacing: 12) {
                    // 画像添付ボタン
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Image(systemName: "photo")
                            .font(.system(size: 20))
                            .foregroundColor(pendingImage == nil ? .secondary : .orange)
                    }
                    .disabled(isTyping || pendingImage != nil)
                    .onChange(of: selectedItem) { _, newItem in
                        handleImageSelection(newItem)
                    }
                    
                    Spacer()
                    
                    // ✅ モード切り替えボタン
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            chatMode = chatMode == "fast" ? "thinking" : "fast"
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: chatMode == "fast" ? "hare.fill" : "brain.head.profile")
                                .font(.system(size: 12))
                            Text(chatMode == "fast" ? "高速" : "思考")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(chatMode == "fast" ? .secondary : .orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(UIColor.systemGray5))
                        .cornerRadius(14)
                    }
                    .disabled(isTyping)
                    
                    // 音声入力ボタン
                    Button {
                        toggleRecording()
                    } label: {
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 18))
                            .foregroundColor(isRecording ? .white : .secondary)
                            .frame(width: 36, height: 36)
                            .background(isRecording ? Color.red : Color.clear)
                            .clipShape(Circle())
                    }
                    .disabled(isTyping)
                    
                    // 送信ボタン
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(canSend ? Color.orange : Color(UIColor.systemGray4))
                            .clipShape(Circle())
                    }
                    .disabled(!canSend)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(24)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - 音声入力トグル
    private func toggleRecording() {
        if isRecording {
            speechRecognizer.stopRecording()
            if !speechRecognizer.transcript.isEmpty {
                messageText = speechRecognizer.transcript
            }
            isRecording = false
        } else {
            speechRecognizer.transcript = ""
            speechRecognizer.startRecording()
            isRecording = true
        }
    }
    
    // MARK: - 画像選択処理
    private func handleImageSelection(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    pendingImage = uiImage
                }
            }
        }
    }
    
    // MARK: - メッセージ送信
    private func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty || pendingImage != nil else { return }
        
        let userMessage = ChatMessage(
            isUser: true,
            text: trimmedText.isEmpty ? nil : trimmedText,
            image: pendingImage
        )
        messages.append(userMessage)
        chatManager.addMessage(userMessage, for: selectedDate)
        
        let imageBase64 = pendingImage?.jpegData(compressionQuality: 0.7)?.base64EncodedString()
        
        messageText = ""
        pendingImage = nil
        selectedItem = nil
        isTextFieldFocused = false
        isTyping = true
        errorMessage = nil
        
        typingTask = Task {
            do {
                let chatHistory = chatManager.chatHistoryForAPI(for: selectedDate)
                let userContext = buildUserContext()
                
                let response = try await network.sendChatWithUserContext(
                    message: trimmedText,
                    imageBase64: imageBase64,
                    chatHistory: chatHistory,
                    userContext: userContext,
                    mode: chatMode
                )
                
                if !Task.isCancelled {
                    await MainActor.run {
                        let aiMessage = ChatMessage(isUser: false, text: response, image: nil)
                        messages.append(aiMessage)
                        chatManager.addMessage(aiMessage, for: selectedDate)
                        isTyping = false
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        let fallback = generateFallbackResponse(for: trimmedText)
                        let aiMessage = ChatMessage(isUser: false, text: fallback, image: nil)
                        messages.append(aiMessage)
                        chatManager.addMessage(aiMessage, for: selectedDate)
                        isTyping = false
                    }
                }
            }
        }
    }
    
    // MARK: - ユーザーコンテキスト構築
    private func buildUserContext() -> [String: Any] {
        let logsManager = MealLogsManager.shared
        let exerciseLogsManager = ExerciseLogsManager.shared
        let nutrients = logsManager.totalNutrients(for: selectedDate)
        let todayCalories = logsManager.totalCalories(for: selectedDate)
        let todayExercise = exerciseLogsManager.totalCaloriesBurned(for: selectedDate)
        let todayMeals = logsManager.logs(for: selectedDate).map { $0.name }.joined(separator: "、")
        
        return [
            "gender": profileManager.gender,
            "age": profileManager.age,
            "height": profileManager.height,
            "current_weight": profileManager.currentWeight,
            "target_weight": profileManager.targetWeight,
            "goal": profileManager.goal,
            "exercise_frequency": profileManager.exerciseFrequency,
            "today_calories": todayCalories,
            "calorie_goal": profileManager.calorieGoal,
            "today_protein": nutrients.protein,
            "protein_goal": profileManager.proteinGoal,
            "today_fat": nutrients.fat,
            "fat_goal": profileManager.fatGoal,
            "today_carbs": nutrients.carbs,
            "carb_goal": profileManager.carbGoal,
            "today_exercise": todayExercise,
            "today_meals": todayMeals,
            "remaining_calories": profileManager.calorieGoal - todayCalories + todayExercise
        ]
    }
    
    // MARK: - フォールバック応答
    private func generateFallbackResponse(for message: String) -> String {
        let responses = [
            "なるほどにゃ〜！もっと詳しく教えてほしいにゃ🐱",
            "いい質問だにゃ！一緒に考えようにゃ😊",
            "ふむふむ、それは大事なことだにゃ🐱💪",
            "カロちゃんも応援してるにゃ！頑張ってにゃ✨"
        ]
        return responses.randomElement() ?? "にゃ〜🐱"
    }
    
    // MARK: - スクロール
    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.3)) {
            if isTyping {
                proxy.scrollTo("typing", anchor: .bottom)
            } else if let lastMessage = messages.last {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
    
    private func scrollToBottomImmediate(proxy: ScrollViewProxy) {
        if let lastMessage = messages.last {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
}

// MARK: - 音声認識マネージャー
class SpeechRecognizer: ObservableObject {
    @Published var transcript: String = ""
    @Published var isAuthorized: Bool = false
    
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.isAuthorized = (status == .authorized)
            }
        }
    }
    
    func startRecording() {
        guard isAuthorized else { return }
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self?.transcript = result.bestTranscription.formattedString
                }
            }
            
            if error != nil || result?.isFinal == true {
                self?.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine failed to start: \(error)")
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
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
                    .offset(y: 12)
                
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 8, height: 8)
                            .scaleEffect(dotCount == index ? 1.3 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: dotCount)
                    }
                }
                .padding(14)
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
                            .frame(maxWidth: 240)
                            .cornerRadius(12)
                    }
                    if let text = message.text, !text.isEmpty {
                        Text(text)
                            .font(.system(size: 16))
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
                        .offset(y: 12)
                    
                    if let text = message.text {
                        LinkedTextView(text: text)
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
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - SafariViewController（アプリ内ブラウザ）
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let safariVC = SFSafariViewController(url: url, configuration: config)
        safariVC.preferredControlTintColor = UIColor.systemOrange
        return safariVC
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - URLラッパー（Identifiable対応）
struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

// MARK: - URLをタップ可能なテキストビュー（アプリ内ブラウザ対応）
struct LinkedTextView: View {
    let text: String
    @State private var selectedURL: IdentifiableURL?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(parseTextWithLinks(text).enumerated()), id: \.offset) { _, element in
                if element.isLink, let url = URL(string: element.text) {
                    Button {
                        selectedURL = IdentifiableURL(url: url)
                    } label: {
                        Text(element.text)
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                            .underline()
                            .lineLimit(2)
                            .truncationMode(.middle)
                    }
                } else {
                    Text(element.text)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
            }
        }
        .sheet(item: $selectedURL) { item in
            SafariView(url: item.url)
        }
    }
    
    private func parseTextWithLinks(_ text: String) -> [TextElement] {
        var elements: [TextElement] = []
        let urlPattern = #"https?://[^\s\u3000\n]+"#
        
        guard let regex = try? NSRegularExpression(pattern: urlPattern, options: []) else {
            return [TextElement(text: text, isLink: false)]
        }
        
        let nsString = text as NSString
        let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        var lastEnd = 0
        
        for result in results {
            if result.range.location > lastEnd {
                let beforeText = nsString.substring(with: NSRange(location: lastEnd, length: result.range.location - lastEnd))
                let trimmed = beforeText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    elements.append(TextElement(text: trimmed, isLink: false))
                }
            }
            
            let urlText = nsString.substring(with: result.range)
            elements.append(TextElement(text: urlText, isLink: true))
            
            lastEnd = result.range.location + result.range.length
        }
        
        if lastEnd < nsString.length {
            let afterText = nsString.substring(from: lastEnd)
            let trimmed = afterText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                elements.append(TextElement(text: trimmed, isLink: false))
            }
        }
        
        if elements.isEmpty {
            elements.append(TextElement(text: text, isLink: false))
        }
        
        return elements
    }
}

// MARK: - テキスト要素
struct TextElement {
    let text: String
    let isLink: Bool
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
