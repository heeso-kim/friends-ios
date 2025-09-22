import SwiftUI
import PhotosUI

/// 채팅 화면
struct ChatView: View {
    let orderId: String
    let customerId: String
    @StateObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool

    init(orderId: String, customerId: String) {
        self.orderId = orderId
        self.customerId = customerId
        self._viewModel = StateObject(wrappedValue: ChatViewModel(orderId: orderId, customerId: customerId))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Typing Indicator
            if viewModel.otherUserTyping {
                typingIndicator
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.isLoading {
                            ProgressView()
                                .padding()
                        }

                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    if let lastMessage = viewModel.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            .refreshable {
                viewModel.refreshMessages()
            }

            // Input Bar
            inputBar

            // Error Banner
            if let errorMessage = viewModel.errorMessage {
                ErrorBanner(message: errorMessage) {
                    viewModel.errorMessage = nil
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("고객과의 채팅")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("닫기") {
                    dismiss()
                }
            }
        }
        .background(Color(UIColor.systemGray6))
        .onTapGesture {
            isTextFieldFocused = false
        }
        .photosPicker(
            isPresented: $viewModel.showImagePicker,
            selection: .constant(nil),
            matching: .images
        )
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(alignment: .bottom, spacing: 8) {
                // Attachment Button
                Button(action: { viewModel.showImagePicker = true }) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                }

                // Text Field
                HStack(alignment: .bottom) {
                    TextField("메시지 입력...", text: $viewModel.messageText, axis: .vertical)
                        .focused($isTextFieldFocused)
                        .lineLimit(1...5)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .background(Color(UIColor.systemGray5))
                .cornerRadius(20)

                // Send Button
                Button(action: viewModel.sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(viewModel.messageText.isEmpty ? .gray : AppColors.brandPrimary)
                }
                .disabled(viewModel.messageText.isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.white)
        }
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack {
            Image(systemName: "ellipsis.bubble")
                .font(.system(size: 14))
                .foregroundColor(.gray)

            Text("상대방이 입력 중...")
                .font(.system(size: 12))
                .foregroundColor(.gray)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color(UIColor.systemGray6))
    }
}

// MARK: - Message Bubble View

struct MessageBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromMe {
                Spacer(minLength: 60)
            }

            // Profile Image (for received messages)
            if !message.isFromMe {
                if let profileUrl = message.senderProfileUrl {
                    AsyncImage(url: URL(string: profileUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                }
            }

            VStack(alignment: message.isFromMe ? .trailing : .leading, spacing: 4) {
                // Sender Name (for received messages)
                if !message.isFromMe {
                    Text(message.senderNickname)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }

                // Message Bubble
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.message)
                        .font(.system(size: 14))
                        .foregroundColor(message.isFromMe ? .white : .black)

                    // Attachments
                    ForEach(message.attachments, id: \.url) { attachment in
                        AttachmentView(attachment: attachment)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(message.isFromMe ? AppColors.brandPrimary : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(message.isFromMe ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                )

                // Timestamp
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }

            if !message.isFromMe {
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - Attachment View

struct AttachmentView: View {
    let attachment: ChatAttachment

    var body: some View {
        switch attachment.type {
        case .image:
            AsyncImage(url: URL(string: attachment.url)) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                ProgressView()
                    .frame(width: 200, height: 200)
            }
            .frame(maxWidth: 200, maxHeight: 200)
            .cornerRadius(8)

        case .file:
            HStack {
                Image(systemName: "doc.fill")
                    .foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text(attachment.fileName ?? "파일")
                        .font(.system(size: 12))
                        .lineLimit(1)
                    if let fileSize = attachment.fileSize {
                        Text(formatFileSize(fileSize))
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)

        default:
            EmptyView()
        }
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
}