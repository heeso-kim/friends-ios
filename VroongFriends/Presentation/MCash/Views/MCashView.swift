import SwiftUI

/// M캐시 화면
struct MCashView: View {
    @StateObject private var viewModel = MCashViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Balance Card
                balanceCard

                // Action Buttons
                actionButtons

                // Transaction History
                transactionHistory
            }
            .padding()
        }
        .navigationTitle("M캐시")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            viewModel.refreshBalance()
        }
    }

    // MARK: - Balance Card

    private var balanceCard: some View {
        VStack(spacing: 16) {
            Text("사용 가능 잔액")
                .font(.system(size: 14))
                .foregroundColor(.gray)

            Text(viewModel.balance.formatted(.currency(code: "KRW")))
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(AppColors.brandPrimary)

            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text("대기중")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(viewModel.pendingBalance.formatted(.currency(code: "KRW")))
                        .font(.system(size: 14, weight: .medium))
                }

                VStack(spacing: 4) {
                    Text("출금 가능")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(viewModel.withdrawableBalance.formatted(.currency(code: "KRW")))
                        .font(.system(size: 14, weight: .medium))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: viewModel.requestWithdrawal) {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 24))
                    Text("출금 신청")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(AppColors.brandPrimary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4)
            }

            Button(action: viewModel.showTransactionDetails) {
                VStack(spacing: 8) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 24))
                    Text("거래 내역")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(AppColors.brandPrimary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4)
            }
        }
    }

    // MARK: - Transaction History

    private var transactionHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("최근 거래")
                .font(.system(size: 16, weight: .semibold))

            if viewModel.recentTransactions.isEmpty {
                Text("최근 거래가 없습니다")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentTransactions) { transaction in
                        TransactionRow(transaction: transaction)
                        Divider()
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4)
            }
        }
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let transaction: MCashTransaction

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.system(size: 14, weight: .medium))
                Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }

            Spacer()

            Text((transaction.type == .credit ? "+" : "-") + transaction.amount.formatted(.currency(code: "KRW")))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(transaction.type == .credit ? .green : .red)
        }
        .padding()
    }
}

// MARK: - MCash ViewModel

@MainActor
class MCashViewModel: ObservableObject {
    @Published var balance: Decimal = 0
    @Published var pendingBalance: Decimal = 0
    @Published var withdrawableBalance: Decimal = 0
    @Published var recentTransactions: [MCashTransaction] = []

    init() {
        loadBalance()
        loadRecentTransactions()
    }

    func refreshBalance() {
        loadBalance()
        loadRecentTransactions()
    }

    func requestWithdrawal() {
        // TODO: 출금 신청 로직
        Logger.debug("출금 신청", category: .payment)
    }

    func showTransactionDetails() {
        // TODO: 거래 내역 상세 화면 이동
        Logger.debug("거래 내역 조회", category: .payment)
    }

    private func loadBalance() {
        // TODO: 실제 API 호출
        balance = 125000
        pendingBalance = 35000
        withdrawableBalance = 90000
    }

    private func loadRecentTransactions() {
        // TODO: 실제 API 호출
        recentTransactions = [
            MCashTransaction(
                id: "1",
                description: "배달 완료 수익",
                amount: 4500,
                type: .credit,
                date: Date().addingTimeInterval(-3600)
            ),
            MCashTransaction(
                id: "2",
                description: "배달 완료 수익",
                amount: 3800,
                type: .credit,
                date: Date().addingTimeInterval(-7200)
            ),
            MCashTransaction(
                id: "3",
                description: "출금",
                amount: 50000,
                type: .debit,
                date: Date().addingTimeInterval(-86400)
            )
        ]
    }
}

// MARK: - MCash Transaction Model

struct MCashTransaction: Identifiable {
    let id: String
    let description: String
    let amount: Decimal
    let type: TransactionType
    let date: Date

    enum TransactionType {
        case credit
        case debit
    }
}