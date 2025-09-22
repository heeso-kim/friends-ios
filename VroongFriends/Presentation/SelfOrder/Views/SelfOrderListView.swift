import SwiftUI

/// 셀프 주문 목록 화면
struct SelfOrderListView: View {
    @State private var selfOrders: [SelfOrder] = []

    var body: some View {
        VStack {
            if selfOrders.isEmpty {
                ContentUnavailableView(
                    "셀프 주문이 없습니다",
                    systemImage: "person.badge.plus",
                    description: Text("직접 등록한 주문이 여기에 표시됩니다")
                )
            } else {
                List(selfOrders) { order in
                    SelfOrderRow(order: order)
                }
            }
        }
        .navigationTitle("셀프 주문")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: createNewSelfOrder) {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private func createNewSelfOrder() {
        // TODO: 셀프 주문 생성 로직
        Logger.debug("셀프 주문 생성", category: .order)
    }
}

// MARK: - Self Order Row

struct SelfOrderRow: View {
    let order: SelfOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(order.title)
                .font(.system(size: 14, weight: .medium))

            Text(order.address)
                .font(.system(size: 12))
                .foregroundColor(.gray)

            HStack {
                Text(order.amount.formatted(.currency(code: "KRW")))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.brandPrimary)

                Spacer()

                Text(order.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Self Order Model (Temporary)

struct SelfOrder: Identifiable {
    let id = UUID().uuidString
    let title: String
    let address: String
    let amount: Decimal
    let createdAt: Date
}