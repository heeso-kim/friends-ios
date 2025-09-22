import Foundation

/// 채팅 채널
struct ChatChannel {
    let channelUrl: String
    let name: String
    let coverImageUrl: String?
    let memberCount: Int
    let lastMessage: String?
    let lastMessageTime: Date?
    let unreadMessageCount: Int
    let customType: String?
    let data: String?
    let members: [ChatMember]
}

/// 채팅 멤버
struct ChatMember {
    let userId: String
    let nickname: String
    let profileUrl: String?
    let connectionStatus: String
    let lastSeenAt: Date?
}

/// 채팅 메시지
struct ChatMessage: Identifiable {
    let id: String
    let messageId: Int
    let message: String
    let senderId: String
    let senderNickname: String
    let senderProfileUrl: String?
    let createdAt: Int64
    let customType: String?
    let data: String?
    let channelUrl: String
    let attachments: [ChatAttachment]

    init(
        messageId: Int,
        message: String,
        senderId: String,
        senderNickname: String,
        senderProfileUrl: String? = nil,
        createdAt: Int64,
        customType: String? = nil,
        data: String? = nil,
        channelUrl: String,
        attachments: [ChatAttachment] = []
    ) {
        self.id = "\(messageId)"
        self.messageId = messageId
        self.message = message
        self.senderId = senderId
        self.senderNickname = senderNickname
        self.senderProfileUrl = senderProfileUrl
        self.createdAt = createdAt
        self.customType = customType
        self.data = data
        self.channelUrl = channelUrl
        self.attachments = attachments
    }

    var isFromMe: Bool {
        return senderId == AppState.shared.currentUser?.id
    }

    var timestamp: Date {
        return Date(milliseconds: createdAt)
    }
}

/// 채팅 첨부파일
struct ChatAttachment {
    let url: String
    let type: AttachmentType
    let fileName: String?
    let fileSize: Int64?
    let thumbnailUrl: String?

    enum AttachmentType {
        case image
        case video
        case file
        case audio
    }
}