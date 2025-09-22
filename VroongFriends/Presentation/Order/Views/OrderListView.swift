import SwiftUI

/// 주문 목록 화면
struct OrderListView: View {
    @StateObject private var viewModel = OrderListViewModel()
    @State private var selectedTab: OrderListTab = .available

    var body: some View {
        VStack(spacing: 0) {
            // Tab Selection
            tabSelector

            // Order List
            ZStack {
                if viewModel.isLoading && viewModel.orders.isEmpty {
                    loadingView
                } else if viewModel.filteredOrders.isEmpty {
                    emptyView
                } else {
                    orderList
                }

                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    VStack {
                        ErrorBanner(message: errorMessage) {
                            viewModel.errorMessage = nil
                        }
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("주문 목록")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            viewModel.refreshOrders()
        }
        .sheet(isPresented: $viewModel.showOrderDetail) {
            if let order = viewModel.selectedOrder {
                NavigationStack {
                    OrderDetailView(orderId: order.id)
                }
            }
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(OrderListTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                        viewModel.selectedFilter = tab.status
                    }
                }) {
                    VStack(spacing: 4) {
                        Text(tab.title)
                            .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? AppColors.brandPrimary : .gray)

                        Rectangle()
                            .fill(selectedTab == tab ? AppColors.brandPrimary : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color(UIColor.systemGray6))
    }

    // MARK: - Order List

    private var orderList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredOrders, id: \.id) { order in
                    OrderListCard(order: order) {
                        viewModel.selectOrder(order)
                    } onAccept: {
                        viewModel.acceptOrder(order)
                    } onReject: {
                        viewModel.rejectOrder(order, reason: "일정 불가")
                    }
                    .onAppear {
                        viewModel.loadMoreIfNeeded(currentItem: order)
                    }
                }

                if viewModel.isLoading && !viewModel.orders.isEmpty {
                    ProgressView()
                        .padding()
                }
            }
            .padding()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("주문을 불러오는 중...")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("주문이 없습니다")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)

            if selectedTab != .available {
                Text("다른 탭을 확인해보세요")
                    .font(.system(size: 14))
                    .foregroundColor(.gray.opacity(0.8))
            }
        }
        .padding()
    }
}

// MARK: - Order List Tab

enum OrderListTab: CaseIterable {
    case available
    case inProgress
    case completed

    var title: String {
        switch self {
        case .available: return "대기중"
        case .inProgress: return "진행중"
        case .completed: return "완료됨"
        }
    }

    var status: OrderStatus? {
        switch self {
        case .available: return .pending
        case .inProgress: return .accepted
        case .completed: return .completed
        }
    }
}

// MARK: - Order List Card

struct OrderListCard: View {
    let order: Order
    let onTap: () -> Void
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                orderTypeBadge
                Spacer()
                Text("#\(order.orderNumber)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }

            // Customer Info
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.gray.opacity(0.5))

                Text(order.customer.name)
                    .font(.system(size: 14, weight: .medium))

                if order.customer.isVip {
                    Text("VIP")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .cornerRadius(4)
                }

                Spacer()
            }

            // Locations
            VStack(alignment: .leading, spacing: 8) {
                locationRow(
                    icon: "mappin.circle.fill",
                    color: AppColors.brandPrimary,
                    address: order.pickupLocation.address
                )

                locationRow(
                    icon: "flag.circle.fill",
                    color: .red,
                    address: order.deliveryLocation.address
                )
            }

            // Payment & Distance
            HStack {
                // Payment Amount
                Label(
                    order.payment.totalAmount.formatted(.currency(code: "KRW")),
                    systemImage: "wonsign.circle"
                )
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.brandPrimary)

                Spacer()

                // Distance
                if let distance = order.estimatedDistance {
                    Label(
                        String(format: "%.1f km", distance / 1000),
                        systemImage: "location.circle"
                    )
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                }

                // Duration
                if let duration = order.estimatedDuration {
                    Label(
                        "\(duration)분",
                        systemImage: "clock"
                    )
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                }
            }

            // Action Buttons (for pending orders)
            if order.status == .pending {
                HStack(spacing: 12) {
                    Button(action: onReject) {
                        Text("거절")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                    }

                    Button(action: onAccept) {
                        Text("수락")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(AppColors.brandPrimary)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .onTapGesture(perform: onTap)
    }

    private var orderTypeBadge: some View {
        Text(order.type.displayName)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(order.type.color)
            .cornerRadius(4)
    }

    private func locationRow(icon: String, color: Color, address: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 20)

            Text(address)
                .font(.system(size: 13))
                .foregroundColor(.black.opacity(0.8))
                .lineLimit(1)
        }
    }
}

// MARK: - Error Banner

struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.white)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.red)
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Extensions

extension OrderType {
    var displayName: String {
        switch self {
        case .normal: return "일반"
        case .express: return "특급"
        case .reserved: return "예약"
        case .bulk: return "대량"
        }
    }

    var color: Color {
        switch self {
        case .normal: return .blue
        case .express: return .red
        case .reserved: return .purple
        case .bulk: return .orange
        }
    }
}