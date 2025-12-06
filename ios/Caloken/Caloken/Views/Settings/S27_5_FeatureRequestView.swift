import SwiftUI

struct S27_5_FeatureRequestView: View {
    @State private var requests: [FeatureRequest] = FeatureRequest.sampleData.sorted { $0.votes > $1.votes }
    @State private var showNewRequestSheet: Bool = false
    @State private var selectedRequest: FeatureRequest? = nil
    @State private var requestToDelete: FeatureRequest? = nil
    @State private var showDeleteAlert: Bool = false
    
    // 現在のユーザーID（仮）
    private let currentUserId = "current_user"
    
    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(requests) { request in
                        Button {
                            selectedRequest = request
                        } label: {
                            FeatureRequestRow(
                                request: request,
                                hasVoted: request.votedUserIds.contains(currentUserId),
                                isOwner: request.authorId == currentUserId,
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
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("機能ウィッシュリスト")
        .navigationBarTitleDisplayMode(.inline)
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
            NewFeatureRequestSheet(
                requests: $requests,
                currentUserId: currentUserId
            )
        }
        .sheet(item: $selectedRequest) { request in
            FeatureRequestDetailView(
                request: binding(for: request),
                currentUserId: currentUserId,
                onVote: {
                    toggleVote(for: request)
                },
                onDeleteRequest: {
                    deleteRequest(request)
                    selectedRequest = nil
                }
            )
        }
    }
    
    private func toggleVote(for request: FeatureRequest) {
        if let index = requests.firstIndex(where: { $0.id == request.id }) {
            if requests[index].votedUserIds.contains(currentUserId) {
                requests[index].votedUserIds.removeAll { $0 == currentUserId }
                requests[index].votes -= 1
            } else {
                requests[index].votedUserIds.append(currentUserId)
                requests[index].votes += 1
            }
            requests.sort { $0.votes > $1.votes }
        }
    }
    
    private func deleteRequest(_ request: FeatureRequest) {
        requests.removeAll { $0.id == request.id }
    }
    
    private func binding(for request: FeatureRequest) -> Binding<FeatureRequest> {
        guard let index = requests.firstIndex(where: { $0.id == request.id }) else {
            return .constant(request)
        }
        return $requests[index]
    }
}

// MARK: - リクエスト行
struct FeatureRequestRow: View {
    let request: FeatureRequest
    let hasVoted: Bool
    let isOwner: Bool
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
                        .foregroundColor(hasVoted ? .orange : .gray)
                    Text("\(request.votes)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(hasVoted ? .orange : .primary)
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
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if isOwner {
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
    @Binding var request: FeatureRequest
    let currentUserId: String
    let onVote: () -> Void
    let onDeleteRequest: () -> Void
    
    @State private var newComment: String = ""
    @State private var commentToDelete: FeatureComment? = nil
    @State private var showDeleteCommentAlert: Bool = false
    @State private var showDeleteRequestAlert: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var hasVoted: Bool {
        request.votedUserIds.contains(currentUserId)
    }
    
    var isOwner: Bool {
        request.authorId == currentUserId
    }
    
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
                            
                            if isOwner {
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
                                        .foregroundColor(hasVoted ? .orange : .gray)
                                    Text("\(request.votes)")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(hasVoted ? .orange : .primary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text(request.description)
                                .font(.system(size: 15))
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                        }
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
                    
                    VStack(spacing: 12) {
                        ForEach(request.comments) { comment in
                            CommentRow(
                                comment: comment,
                                isOwner: comment.userId == currentUserId,
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
    
    private func submitComment() {
        let comment = FeatureComment(
            userId: currentUserId,
            displayName: "あなた",
            content: newComment,
            date: Date()
        )
        request.comments.insert(comment, at: 0)
        newComment = ""
    }
    
    private func deleteComment(_ comment: FeatureComment) {
        request.comments.removeAll { $0.id == comment.id }
    }
}

// MARK: - コメント行
struct CommentRow: View {
    let comment: FeatureComment
    let isOwner: Bool
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(isOwner ? "あなた" : comment.displayName)
                    .font(.system(size: 13, weight: isOwner ? .semibold : .regular))
                    .foregroundColor(isOwner ? .orange : .gray)
                Spacer()
                
                if isOwner {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                }
                
                Text(formatDate(comment.date))
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
    @Binding var requests: [FeatureRequest]
    let currentUserId: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var description: String = ""
    
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
                        let newRequest = FeatureRequest(
                            authorId: currentUserId,
                            title: title,
                            description: description,
                            votes: 1,
                            votedUserIds: [currentUserId],
                            comments: []
                        )
                        requests.insert(newRequest, at: 0)
                        requests.sort { $0.votes > $1.votes }
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - データモデル
struct FeatureRequest: Identifiable {
    let id = UUID()
    var authorId: String
    var title: String
    var description: String
    var votes: Int
    var votedUserIds: [String]
    var comments: [FeatureComment]
}

struct FeatureComment: Identifiable {
    let id = UUID()
    let userId: String
    let displayName: String
    let content: String
    let date: Date
}

// MARK: - サンプルデータ（1つだけ）
extension FeatureRequest {
    static let sampleData: [FeatureRequest] = [
        FeatureRequest(
            authorId: "user1",
            title: "カロちゃんがもっと動いて欲しい",
            description: "カロちゃんがもっとアニメーションで動いたり、いろんな表情を見せてくれると嬉しいです！応援してくれたり、喜んでくれたりすると、もっとやる気が出そう✨",
            votes: 0,
            votedUserIds: ["user1", "user2", "user3"],
            comments: []
        )
    ]
}

#Preview {
    NavigationStack {
        S27_5_FeatureRequestView()
    }
}
