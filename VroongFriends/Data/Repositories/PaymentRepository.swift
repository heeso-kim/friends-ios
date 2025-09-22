import Foundation
import Combine
import Moya

/// 결제 리포지토리 구현체
final class PaymentRepository: PaymentRepositoryProtocol {
    private let provider: MoyaProvider<FriendsAPI>
    
    init(provider: MoyaProvider<FriendsAPI>) {
        self.provider = provider
    }
    
    func getPayments(filter: PaymentFilter?) -> AnyPublisher<[PaymentInfo], AppError> {
        var parameters: [String: Any] = [:]
        
        if let filter = filter {
            if let status = filter.status {
                parameters["status"] = status.rawValue
            }
            if let method = filter.method {
                parameters["method"] = method.rawValue
            }
            if let startDate = filter.startDate {
                parameters["startDate"] = ISO8601DateFormatter().string(from: startDate)
            }
            if let endDate = filter.endDate {
                parameters["endDate"] = ISO8601DateFormatter().string(from: endDate)
            }
            if let minAmount = filter.minAmount {
                parameters["minAmount"] = "\(minAmount)"
            }
            if let maxAmount = filter.maxAmount {
                parameters["maxAmount"] = "\(maxAmount)"
            }
        }
        
        return provider.requestPublisher(.getPayments(parameters: parameters))
            .map([PaymentInfoDTO].self)
            .map { $0.map { $0.toEntity() } }
            .mapError(mapMoyaError)
            .eraseToAnyPublisher()
    }
    
    func getPayment(id: String) -> AnyPublisher<PaymentInfo, AppError> {
        // TODO: API 엔드포인트 추가 필요
        return Fail(error: AppError.dataNotFound)
            .eraseToAnyPublisher()
    }
    
    func getMCashBalance() -> AnyPublisher<MCash, AppError> {
        return provider.requestPublisher(.getMCashBalance)
            .map(MCashDTO.self)
            .map { $0.toEntity() }
            .mapError(mapMoyaError)
            .eraseToAnyPublisher()
    }
    
    func requestWithdrawal(amount: Decimal, account: BankAccount) -> AnyPublisher<Withdrawal, AppError> {
        return provider.requestPublisher(.requestWithdrawal(amount: amount, account: account))
            .map(WithdrawalDTO.self)
            .map { $0.toEntity() }
            .mapError { error in
                if let moyaError = error as? MoyaError,
                   case .statusCode(let response) = moyaError,
                   response.statusCode == 400 {
                    return AppError.insufficientBalance
                }
                return self.mapMoyaError(error)
            }
            .eraseToAnyPublisher()
    }
    
    func getWithdrawalHistory() -> AnyPublisher<[Withdrawal], AppError> {
        return provider.requestPublisher(.getWithdrawalHistory)
            .map([WithdrawalDTO].self)
            .map { $0.map { $0.toEntity() } }
            .mapError(mapMoyaError)
            .eraseToAnyPublisher()
    }
    
    func cancelWithdrawal(id: String) -> AnyPublisher<Void, AppError> {
        return provider.requestPublisher(.cancelWithdrawal(id: id))
            .map { _ in () }
            .mapError(mapMoyaError)
            .eraseToAnyPublisher()
    }
    
    func getEarnings(startDate: Date, endDate: Date) -> AnyPublisher<EarningsSummary, AppError> {
        return provider.requestPublisher(.getEarnings(startDate: startDate, endDate: endDate))
            .map(EarningsSummaryDTO.self)
            .map { $0.toEntity() }
            .mapError(mapMoyaError)
            .eraseToAnyPublisher()
    }
    
    private func mapMoyaError(_ error: Error) -> AppError {
        if let moyaError = error as? MoyaError {
            switch moyaError {
            case .statusCode(let response):
                if response.statusCode == 401 {
                    return AppError.unauthorized
                }
                return AppError.serverError(code: response.statusCode, message: nil)
            case .underlying(let underlyingError, _):
                if (underlyingError as NSError).code == NSURLErrorNotConnectedToInternet {
                    return AppError.noInternetConnection
                }
                return AppError.networkError(underlyingError.localizedDescription)
            default:
                return AppError.networkError(moyaError.localizedDescription)
            }
        }
        return AppError.unknown(error.localizedDescription)
    }
}

// MARK: - DTOs

struct PaymentInfoDTO: Codable {
    let id: String
    let orderId: String
    let method: String
    let status: String
    let amount: PaymentAmountDTO
    let transactionId: String?
    let paidAt: Date?
    let refundedAt: Date?
    let metadata: [String: String]?
    let createdAt: Date
    let updatedAt: Date
    
    func toEntity() -> PaymentInfo {
        PaymentInfo(
            id: id,
            orderId: orderId,
            method: PaymentMethod(rawValue: method) ?? .cash,
            status: PaymentStatus(rawValue: status) ?? .pending,
            amount: amount.toEntity(),
            transactionId: transactionId,
            paidAt: paidAt,
            refundedAt: refundedAt,
            metadata: metadata,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct PaymentAmountDTO: Codable {
    let baseAmount: Double
    let deliveryFee: Double
    let serviceFee: Double
    let tip: Double
    let discount: Double
    let couponDiscount: Double
    let pointsUsed: Double
    let tax: Double
    let totalAmount: Double
    let currency: String
    
    func toEntity() -> PaymentAmount {
        PaymentAmount(
            baseAmount: Decimal(baseAmount),
            deliveryFee: Decimal(deliveryFee),
            serviceFee: Decimal(serviceFee),
            tip: Decimal(tip),
            discount: Decimal(discount),
            couponDiscount: Decimal(couponDiscount),
            pointsUsed: Decimal(pointsUsed),
            tax: Decimal(tax),
            totalAmount: Decimal(totalAmount),
            currency: currency
        )
    }
}

struct MCashDTO: Codable {
    let balance: Double
    let pendingBalance: Double
    let withdrawableBalance: Double
    let currency: String
    let lastUpdated: Date
    
    func toEntity() -> MCash {
        MCash(
            balance: Decimal(balance),
            pendingBalance: Decimal(pendingBalance),
            withdrawableBalance: Decimal(withdrawableBalance),
            currency: currency,
            lastUpdated: lastUpdated
        )
    }
}

struct WithdrawalDTO: Codable {
    let id: String
    let amount: Double
    let status: String
    let bankAccount: BankAccountDTO?
    let requestedAt: Date
    let processedAt: Date?
    let rejectionReason: String?
    
    func toEntity() -> Withdrawal {
        Withdrawal(
            id: id,
            amount: Decimal(amount),
            status: Withdrawal.WithdrawalStatus(rawValue: status) ?? .pending,
            bankAccount: bankAccount?.toEntity(),
            requestedAt: requestedAt,
            processedAt: processedAt,
            rejectionReason: rejectionReason
        )
    }
}

struct BankAccountDTO: Codable {
    let bankCode: String
    let bankName: String
    let accountNumber: String
    let accountHolder: String
    let isVerified: Bool
    
    func toEntity() -> BankAccount {
        BankAccount(
            bankCode: bankCode,
            bankName: bankName,
            accountNumber: accountNumber,
            accountHolder: accountHolder,
            isVerified: isVerified
        )
    }
}

struct EarningsSummaryDTO: Codable {
    let totalEarnings: Double
    let completedOrders: Int
    let averageEarningPerOrder: Double
    let deliveryFees: Double
    let tips: Double
    let bonuses: Double
    let deductions: Double
    let netEarnings: Double
    let periodStart: Date
    let periodEnd: Date
    
    func toEntity() -> EarningsSummary {
        EarningsSummary(
            totalEarnings: Decimal(totalEarnings),
            completedOrders: completedOrders,
            averageEarningPerOrder: Decimal(averageEarningPerOrder),
            deliveryFees: Decimal(deliveryFees),
            tips: Decimal(tips),
            bonuses: Decimal(bonuses),
            deductions: Decimal(deductions),
            netEarnings: Decimal(netEarnings),
            periodStart: periodStart,
            periodEnd: periodEnd
        )
    }
}