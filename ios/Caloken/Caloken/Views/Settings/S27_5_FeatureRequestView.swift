import SwiftUI

struct S27_5_FeatureRequestView: View {
    @State private var requests: [FeatureRequestLocal] = []
    @State private var isLoading: Bool = true
    @State private var showNewRequestSheet: Bool = false
    @State private var selectedRequest: FeatureRequestLocal? = nil
    @State private var requestToDelete: FeatureRequestLocal? = nil
    @State private var showDeleteAlert: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("読み込み中...")
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("再読み込み") {
                        loadRequests()
                    }
                    .foregroundColor(.orange)
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if requests.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "lightbulb")
                                    .font(.system(size: 40))
                                    .foregroundColor(.orange)
                                Text("まだ提案がありません")
                                    .font(.system(size: 16, weight: .medium))
                                Text("新しい機能のアイデアを提案してみましょう！")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 60)
                        } else {
                            ForEach(requests) { request in
                                Button {
                                    selectedRequest = request
                                } label: {
                                    FeatureRequestRow(
                                        request: request,
                                        onVote: {
                                            toggleVote(for: request)
                                        },
                                        onDelete: {
                                            requestToDelete = request
                                            showDeleteAlert = true
                                        }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Divider()
                                    .padding(.leading, 16)
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
                
                // 新規提案ボタン
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showNewRequestSheet = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                Text("新規提案")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(Color.orange)
                            .cornerRadius(25)
                            .shadow(color: Color.orange.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("機能ウィッシュリスト")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadRequests()
        }
        .refreshable {
            await refreshRequests()
        }
        .alert("提案を削除", isPresented: $showDeleteAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                if let request = requestToDelete {
                    deleteRequest(request)
                }
            }
        } message: {
            Text("この提案を削除しますか？")
        }
        .sheet(isPresented: $showNewRequestSheet) {
            NewFeatureRequestSheet(onSubmit: { title, description in
                createRequest(title: title, description: description)
            })
        }
        .sheet(item: $selectedRequest) { request in
            FeatureRequestDetailView(
                request: request,
                onVote: {
                    toggleVote(for: request)
                },
                onDeleteRequest: {
                    deleteRequest(request)
                    selectedRequest = nil
                },
                onRefresh: {
                    loadRequests()
                }
            )
        }
    }
    
    // MARK: - API連携
    
    private func loadRequests() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let apiRequests = try await NetworkManager.shared.getFeatureRequests()
                await MainActor.run {
                    requests = apiRequests.map { FeatureRequestLocal(from: $0) }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "データの読み込みに失敗しました"
                    isLoading = false
                }
            }
        }
    }
    
    private func refreshRequests() async {
        do {
            let apiRequests = try await NetworkManager.shared.getFeatureRequests()
            await MainActor.run {
                requests = apiRequests.map { FeatureRequestLocal(from: $0) }
            }
        } catch {
            print("Refresh error: \(error)")
        }
    }
    
    private func toggleVote(for request: FeatureRequestLocal) {
        Task {
            do {
                let response = try await NetworkManager.shared.toggleFeatureRequestVote(requestId: request.id)
                await MainActor.run {
                    if let index = requests.firstIndex(where: { $0.id == request.id }) {
                        requests[index].hasVoted = response.voted
                        requests[index].votes += response.voted ? 1 : -1
                        requests.sort { $0.votes > $1.votes }
                    }
                }
            } catch {
                print("Vote error: \(error)")
            }
        }
    }
    
    private func deleteRequest(_ request: FeatureRequestLocal) {
        Task {
            do {
                try await NetworkManager.shared.deleteFeatureRequest(id: request.id)
                await MainActor.run {
                    requests.removeAll { $0.id == request.id }
                }
            } catch {
                print("Delete error: \(error)")
            }
        }
    }
    
    private func createRequest(title: String, description: String) {
        Task {
            do {
                let newRequest = try await NetworkManager.shared.createFeatureRequest(
                    title: title,
                    description: description
                )
                await MainActor.run {
                    requests.insert(FeatureRequestLocal(from: newRequest), at: 0)
                    requests.sort { $0.votes > $1.votes }
                }
            } catch {
                print("Create error: \(error)")
            }
        }
    }
}

// MARK: - ローカルデータモデル

struct FeatureRequestLocal: Identifiable {
    let id: String
    let authorId: String
    let authorName: String
    var title: String
    var description: String
    var votes: Int
    let status: String
    var hasVoted: Bool
    let isOwner: Bool
    var comments: [FeatureCommentLocal]
    let createdAt: Date
    
    init(from api: FeatureRequestAPI) {
        self.id = api.id
        self.authorId = api.authorId
        self.authorName = api.authorName
        self.title = api.title
        self.description = api.description
        self.votes = api.votes
        self.status = api.status
        self.hasVoted = api.hasVoted
        self.isOwner = api.isOwner
        self.comments = api.comments.map { FeatureCommentLocal(from: $0) }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.createdAt = formatter.date(from: api.createdAt) ?? Date()
    }
}

struct FeatureCommentLocal: Identifiable {
    let id: String
    let userId: String
    let displayName: String
    let content: String
    let createdAt: Date
    let isOwner: Bool
    
    init(from api: FeatureCommentAPI) {
        self.id = api.id
        self.userId = api.userId
        self.displayName = api.displayName
        self.content = api.content
        self.isOwner = api.isOwner
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.createdAt = formatter.date(from: api.createdAt) ?? Date()
    }
}

// MARK: - リクエスト行
struct FeatureRequestRow: View {
    let request: FeatureRequestLocal
    let onVote: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                onVote()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "arrowtriangle.up.fill")
                        .font(.system(size: 14))
                        .foregroundColor(request.hasVoted ? .orange : .gray)
                    Text("\(request.votes)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(request.hasVoted ? .orange : .primary)
                }
                .frame(width: 44)
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text(request.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(request.description)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(request.authorName)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if request.isOwner {
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.top, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.top, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - リクエスト詳細画面
struct FeatureRequestDetailView: View {
    let request: FeatureRequestLocal
    let onVote: () -> Void
    let onDeleteRequest: () -> Void
    let onRefresh: () -> Void
    
    @State private var comments: [FeatureCommentLocal] = []
    @State private var newComment: String = ""
    @State private var commentToDelete: FeatureCommentLocal? = nil
    @State private var showDeleteCommentAlert: Bool = false
    @State private var showDeleteRequestAlert: Bool = false
    @State private var isLoadingComments: Bool = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(request.title)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if request.isOwner {
                                Button {
                                    showDeleteRequestAlert = true
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 16))
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        HStack(alignment: .top, spacing: 12) {
                            Button {
                                onVote()
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: "arrowtriangle.up.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(request.hasVoted ? .orange : .gray)
                                    Text("\(request.votes)")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(request.hasVoted ? .orange : .primary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text(request.description)
                                .font(.system(size: 15))
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                        }
                        
                        Text("提案者: \(request.authorName)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        Text("コメント")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 12)
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                    
                    HStack(spacing: 12) {
                        TextField("コメントを書く", text: $newComment)
                            .font(.system(size: 15))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(12)
                        
                        Button {
                            submitComment()
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 20))
                                .foregroundColor(newComment.isEmpty ? .gray : .orange)
                        }
                        .disabled(newComment.isEmpty)
                    }
                    .padding(.horizontal, 16)
                    
                    if isLoadingComments {
                        ProgressView()
                            .padding(.top, 20)
                            .frame(maxWidth: .infinity)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(comments) { comment in
                                CommentRow(
                                    comment: comment,
                                    onDelete: {
                                        commentToDelete = comment
                                        showDeleteCommentAlert = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("機能ウィッシュリスト")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                loadDetail()
            }
            .alert("コメントを削除", isPresented: $showDeleteCommentAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    if let comment = commentToDelete {
                        deleteComment(comment)
                    }
                }
            } message: {
                Text("このコメントを削除しますか？")
            }
            .alert("提案を削除", isPresented: $showDeleteRequestAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    onDeleteRequest()
                }
            } message: {
                Text("この提案を削除しますか？\nすべてのコメントも削除されます。")
            }
        }
    }
    
    private func loadDetail() {
        Task {
            do {
                let detail = try await NetworkManager.shared.getFeatureRequest(id: request.id)
                await MainActor.run {
                    comments = detail.comments.map { FeatureCommentLocal(from: $0) }
                    isLoadingComments = false
                }
            } catch {
                await MainActor.run {
                    isLoadingComments = false
                }
            }
        }
    }
    
    private func submitComment() {
        let content = newComment
        newComment = ""
        
        Task {
            do {
                let newCommentAPI = try await NetworkManager.shared.addFeatureRequestComment(
                    requestId: request.id,
                    content: content
                )
                await MainActor.run {
                    comments.insert(FeatureCommentLocal(from: newCommentAPI), at: 0)
                }
            } catch {
                await MainActor.run {
                    newComment = content  // 失敗したら戻す
                }
            }
        }
    }
    
    private func deleteComment(_ comment: FeatureCommentLocal) {
        Task {
            do {
                try await NetworkManager.shared.deleteFeatureRequestComment(
                    requestId: request.id,
                    commentId: comment.id
                )
                await MainActor.run {
                    comments.removeAll { $0.id == comment.id }
                }
            } catch {
                print("Delete comment error: \(error)")
            }
        }
    }
}

// MARK: - コメント行
struct CommentRow: View {
    let comment: FeatureCommentLocal
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(comment.isOwner ? "あなた" : comment.displayName)
                    .font(.system(size: 13, weight: comment.isOwner ? .semibold : .regular))
                    .foregroundColor(comment.isOwner ? .orange : .gray)
                Spacer()
                
                if comment.isOwner {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                }
                
                Text(formatDate(comment.createdAt))
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            
            Text(comment.content)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter.string(from: date)
    }
}

// MARK: - 新規リクエストシート
struct NewFeatureRequestSheet: View {
    let onSubmit: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var isSubmitting: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("タイトル") {
                    TextField("機能のタイトル", text: $title)
                }
                
                Section("詳細") {
                    TextEditor(text: $description)
                        .frame(minHeight: 150)
                }
            }
            .navigationTitle("新規提案")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("送信") {
                        isSubmitting = true
                        onSubmit(title, description)
                        dismiss()
                    }
                    .disabled(title.isEmpty || isSubmitting)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        S27_5_FeatureRequestView()
    }
}
