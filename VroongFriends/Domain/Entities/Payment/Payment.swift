import Foundation

/// 결제 도메인 모델
struct PaymentInfo: Codable, Equatable, Identifiable {
    let id: String
    let orderId: String
    let method: PaymentMethod
    let status: PaymentStatus
    let amount: PaymentAmount
    let transactionId: String?
    let paidAt: Date?
    let refundedAt: Date?
    let metadata: [String: String]?
    let createdAt: Date
    let updatedAt: Date
    
    // 계산 프로퍼티
    var isCompleted: Bool {
        status == .completed
    }
    
    var isPending: Bool {
        status == .pending || status == .processing
    }
    
    var canRefund: Bool {
        status == .completed && refundedAt == nil
    }
}

// MARK: - Payment Method

enum PaymentMethod: String, Codable, CaseIterable {
    case cash = "CASH"
    case card = "CARD"
    case bankTransfer = "BANK_TRANSFER"
    case mcash = "MCASH"
    case prepaid = "PREPAID"
    case postpaid = "POSTPAID"
    case kakaoPayment = "KAKAO_PAY"
    case naverPayment = "NAVER_PAY"
    case tossPayment = "TOSS"
    
    var displayName: String {
        switch self {
        case .cash: return "현금"
        case .card: return "카드"
        case .bankTransfer: return "계좌이체"
        case .mcash: return "M캐시"
        case .prepaid: return "선결제"
        case .postpaid: return "후결제"
        case .kakaoPayment: return "카카오페이"
        case .naverPayment: return "네이버페이"
        case .tossPayment: return "토스"
        }
    }
    
    var icon: String {
        switch self {
        case .cash: return "💵"
        case .card: return "💳"
        case .bankTransfer: return "🏦"
        case .mcash: return "🪙"
        case .prepaid: return "✅"
        case .postpaid: return "📋"
        case .kakaoPayment: return "💬"
        case .naverPayment: return "🔍"
        case .tossPayment: return "💸"
        }
    }
    
    var requiresPreAuth: Bool {
        switch self {
        case .prepaid, .kakaoPayment, .naverPayment, .tossPayment:
            return true
        default:
            return false
        }
    }
}

// MARK: - Payment Status

enum PaymentStatus: String, Codable, CaseIterable {
    case pending = "PENDING"
    case processing = "PROCESSING"
    case completed = "COMPLETED"
    case failed = "FAILED"
    case cancelled = "CANCELLED"
    case refunded = "REFUNDED"
    case partialRefunded = "PARTIAL_REFUNDED"
    
    var displayName: String {
        switch self {
        case .pending: return "대기중"
        case .processing: return "처리중"
        case .completed: return "완료"
        case .failed: return "실패"
        case .cancelled: return "취소"
        case .refunded: return "환불"
        case .partialRefunded: return "부분 환불"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "#FFA500"
        case .processing: return "#2196F3"
        case .completed: return "#4CAF50"
        case .failed: return "#F44336"
        case .cancelled: return "#9E9E9E"
        case .refunded: return "#FF9800"
        case .partialRefunded: return "#FFC107"
        }
    }
}

// MARK: - Payment Amount

struct PaymentAmount: Codable, Equatable {
    let baseAmount: Decimal
    let deliveryFee: Decimal
    let serviceFee: Decimal
    let tip: Decimal
    let discount: Decimal
    let couponDiscount: Decimal
    let pointsUsed: Decimal
    let tax: Decimal
    let totalAmount: Decimal
    let currency: String
    
    // 계산 프로퍼티
    var subtotal: Decimal {
        baseAmount + deliveryFee + serviceFee + tip + tax
    }
    
    var totalDiscount: Decimal {
        discount + couponDiscount + pointsUsed
    }
    
    var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: totalAmount as NSDecimalNumber) ?? ""
    }
}

// MARK: - MCash

struct MCash: Codable, Equatable {
    let balance: Decimal
    let pendingBalance: Decimal
    let withdrawableBalance: Decimal
    let currency: String
    let lastUpdated: Date
    
    var totalBalance: Decimal {
        balance + pendingBalance
    }
    
    var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: balance as NSDecimalNumber) ?? ""
    }
    
    var canWithdraw: Bool {
        withdrawableBalance > 0
    }
}

// MARK: - Withdrawal

struct Withdrawal: Codable, Equatable, Identifiable {
    let id: String
    let amount: Decimal
    let status: WithdrawalStatus
    let bankAccount: BankAccount?
    let requestedAt: Date
    let processedAt: Date?
    let rejectionReason: String?
    
    enum WithdrawalStatus: String, Codable {
        case pending = "PENDING"
        case processing = "PROCESSING"
        case completed = "COMPLETED"
        case rejected = "REJECTED"
        case cancelled = "CANCELLED"
        
        var displayName: String {
            switch self {
            case .pending: return "대기중"
            case .processing: return "처리중"
            case .completed: return "완료"
            case .rejected: return "거절"
            case .cancelled: return "취소"
            }
        }
    }
}

// MARK: - Bank Account

struct BankAccount: Codable, Equatable {
    let bankCode: String
    let bankName: String
    let accountNumber: String
    let accountHolder: String
    let isVerified: Bool
    
    var maskedAccountNumber: String {
        guard accountNumber.count > 4 else { return accountNumber }
        let lastFour = String(accountNumber.suffix(4))
        let maskedCount = accountNumber.count - 4
        let masked = String(repeating: "*", count: maskedCount)
        return masked + lastFour
    }
}

// MARK: - Mock Data

#if DEBUG
extension PaymentInfo {
    static let mock = PaymentInfo(
        id: "payment123",
        orderId: "order123",
        method: .card,
        status: .completed,
        amount: PaymentAmount(
            baseAmount: 20000,
            deliveryFee: 3000,
            serviceFee: 500,
            tip: 1000,
            discount: 1000,
            couponDiscount: 0,
            pointsUsed: 500,
            tax: 2450,
            totalAmount: 25450,
            currency: "KRW"
        ),
        transactionId: "txn_123456",
        paidAt: Date(),
        refundedAt: nil,
        metadata: ["card_type": "VISA"],
        createdAt: Date(),
        updatedAt: Date()
    )
}

extension MCash {
    static let mock = MCash(
        balance: 150000,
        pendingBalance: 25000,
        withdrawableBalance: 120000,
        currency: "KRW",
        lastUpdated: Date()
    )
}
#endif