import SwiftUI
import PhotosUI
import Combine

// MARK: - チャットメッセージマネージャー（日毎管理）
final class ChatMessagesManager: ObservableObject {
    static let shared = ChatMessagesManager()
    
    private var messagesByDate: [String: [ChatMessage]] = [:]
    
    private let userDefaults = UserDefaults.standard
    private let storageKey = "chatMessages"
    
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
                ["isUser": msg.isUser, "text": msg.text ?? ""]
            }
        }
        userDefaults.set(savableData, forKey: storageKey)
    }
    
    private func loadMessages() {
        guard let data = userDefaults.dictionary(forKey: storageKey) as? [String: [[String: Any]]] else { return }
        for (key, messagesData) in data {
            messagesByDate[key] = messagesData.map { dict in
                ChatMessage(
                    isUser: dict["isUser"] as? Bool ?? false,
                    text: dict["text"] as? String,
                    image: nil
                )
            }
        }
    }
}

// MARK: - カロちゃんチャット画面
struct CaloChatView: View {
    @Environment(\.dismiss) private var dismiss
    let selectedDate: Date
    
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var selectedItem: PhotosPickerItem?
    
    private let chatManager = ChatMessagesManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // チャットメッセージ一覧
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(16)
                }
                .onChange(of: messages.count) { _ in
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // 入力欄
            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Image(systemName: "photo")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                }
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            let imageMessage = ChatMessage(isUser: true, text: nil, image: uiImage)
                            messages.append(imageMessage)
                            chatManager.addMessage(imageMessage, for: selectedDate)
                            selectedItem = nil
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                let response = "画像を受け取ったにゃ🐱 美味しそうだね！カロリーを計算するから待っててね！"
                                let responseMessage = ChatMessage(isUser: false, text: response, image: nil)
                                messages.append(responseMessage)
                                chatManager.addMessage(responseMessage, for: selectedDate)
                            }
                        }
                    }
                }
                
                TextField("メッセージを入力...", text: $messageText)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .cornerRadius(20)
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.dynamicAccent)
                        .clipShape(Circle())
                }
                .disabled(messageText.isEmpty)
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("カロちゃんに相談")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
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
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let userMessage = ChatMessage(isUser: true, text: messageText, image: nil)
        messages.append(userMessage)
        chatManager.addMessage(userMessage, for: selectedDate)
        
        let userText = messageText
        messageText = ""
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let response = generateResponse(for: userText)
            let responseMessage = ChatMessage(isUser: false, text: response, image: nil)
            messages.append(responseMessage)
            chatManager.addMessage(responseMessage, for: selectedDate)
        }
    }
    
    private func generateResponse(for message: String) -> String {
        if message.contains("タンパク質") || message.contains("肉") {
            return "タンパク質を増やすなら、鶏むね肉や卵がおすすめだにゃ！🍗 今日あと100g摂ると目標達成できるよ！"
        } else if message.contains("運動") {
            return "今日は3,982歩歩いたね！あと6,000歩で目標達成だにゃ🏃‍♂️ 夕方に少し散歩するのはどう？"
        } else {
            return "なるほど！今日のカロリーは順調だにゃ😊 このペースで頑張ろう！"
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
                    if let text = message.text {
                        Text(text)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.dynamicAccent)
                            .cornerRadius(16)
                    }
                }
            } else {
                Image("caloken_character")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                
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
