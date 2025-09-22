import Foundation
import Combine

/// 결제 리포지토리 프로토콜
protocol PaymentRepositoryProtocol {
    func getPayments(filter: PaymentFilter?) -> AnyPublisher<[PaymentInfo], AppError>
    func getPayment(id: String) -> AnyPublisher<PaymentInfo, AppError>
    func getMCashBalance() -> AnyPublisher<MCash, AppError>
    func requestWithdrawal(amount: Decimal, account: BankAccount) -> AnyPublisher<Withdrawal, AppError>
    func getWithdrawalHistory() -> AnyPublisher<[Withdrawal], AppError>
    func cancelWithdrawal(id: String) -> AnyPublisher<Void, AppError>
    func getEarnings(startDate: Date, endDate: Date) -> AnyPublisher<EarningsSummary, AppError>
}

/// 결제 필터
struct PaymentFilter: Equatable {
    let status: PaymentStatus?
    let method: PaymentMethod?
    let startDate: Date?
    let endDate: Date?
    let minAmount: Decimal?
    let maxAmount: Decimal?
}

/// 수익 요약
struct EarningsSummary: Codable, Equatable {
    let totalEarnings: Decimal
    let completedOrders: Int
    let averageEarningPerOrder: Decimal
    let deliveryFees: Decimal
    let tips: Decimal
    let bonuses: Decimal
    let deductions: Decimal
    let netEarnings: Decimal
    let periodStart: Date
    let periodEnd: Date
}