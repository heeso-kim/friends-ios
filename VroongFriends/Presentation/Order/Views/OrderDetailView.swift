import SwiftUI
import MapKit

/// 주문 상세 화면
struct OrderDetailView: View {
    let orderId: String
    @StateObject private var viewModel: OrderDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingRejectReason = false
    @State private var showingCancelReason = false
    @State private var rejectReason = ""
    @State private var cancelReason = ""

    init(orderId: String) {
        self.orderId = orderId
        self._viewModel = StateObject(wrappedValue: OrderDetailViewModel(orderId: orderId))
    }

    var body: some View {
        ZStack {
            if let order = viewModel.order {
                ScrollView {
                    VStack(spacing: 20) {
                        // Status Progress
                        statusProgressView

                        // Order Info
                        orderInfoSection(order)

                        // Customer Info
                        customerInfoSection(order)

                        // Location Info
                        locationSection(order)

                        // Items
                        if !order.items.isEmpty {
                            itemsSection(order)
                        }

                        // Payment Info
                        paymentSection(order)

                        // Action Buttons
                        actionButtonsSection(order)
                    }
                    .padding()
                }
            } else if viewModel.isLoading {
                ProgressView("주문 정보를 불러오는 중...")
            } else {
                ContentUnavailableView(
                    "주문을 찾을 수 없습니다",
                    systemImage: "doc.text.magnifyingglass"
                )
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
        .navigationTitle("주문 상세")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("닫기") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $viewModel.showingMap) {
            if let order = viewModel.order {
                NavigationStack {
                    OrderMapView(order: order)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingChat) {
            if let order = viewModel.order {
                NavigationStack {
                    ChatView(orderId: order.id, customerId: order.customer.id)
                }
            }
        }
        .sheet(isPresented: $showingRejectReason) {
            rejectReasonSheet
        }
        .sheet(isPresented: $showingCancelReason) {
            cancelReasonSheet
        }
    }

    // MARK: - Status Progress View

    private var statusProgressView: some View {
        VStack(spacing: 12) {
            HStack {
                Text(viewModel.statusText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(statusColor)

                Spacer()

                if let order = viewModel.order {
                    Text("#\(order.orderNumber)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
            }

            ProgressView(value: viewModel.statusProgressValue)
                .progressViewStyle(LinearProgressViewStyle(tint: statusColor))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }

    private var statusColor: Color {
        switch viewModel.currentStatus {
        case .pending: return .gray
        case .accepted, .pickingUp, .delivering: return AppColors.brandPrimary
        case .completed: return .green
        case .cancelled, .rejected: return .red
        }
    }

    // MARK: - Order Info Section

    private func orderInfoSection(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("주문 정보")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                orderTypeBadge(order.type)
            }

            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "주문 시간", value: order.createdAt.formatted(date: .abbreviated, time: .shortened))

                if let acceptedAt = order.acceptedAt {
                    InfoRow(label: "수락 시간", value: acceptedAt.formatted(date: .abbreviated, time: .shortened))
                }

                if let estimatedDistance = order.estimatedDistance {
                    InfoRow(label: "예상 거리", value: String(format: "%.1f km", estimatedDistance / 1000))
                }

                if let estimatedDuration = order.estimatedDuration {
                    InfoRow(label: "예상 시간", value: "\(estimatedDuration)분")
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }

    // MARK: - Customer Info Section

    private func customerInfoSection(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("고객 정보")
                    .font(.system(size: 16, weight: .semibold))

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

                HStack(spacing: 16) {
                    Button(action: viewModel.callCustomer) {
                        Image(systemName: "phone.fill")
                            .foregroundColor(AppColors.brandPrimary)
                    }

                    Button(action: viewModel.openChat) {
                        Image(systemName: "message.fill")
                            .foregroundColor(AppColors.brandPrimary)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "고객명", value: order.customer.name)
                InfoRow(label: "연락처", value: order.customer.phoneNumber)
                if let email = order.customer.email {
                    InfoRow(label: "이메일", value: email)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }

    // MARK: - Location Section

    private func locationSection(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("배달 정보")
                    .font(.system(size: 16, weight: .semibold))

                Spacer()

                Button(action: viewModel.openMap) {
                    Label("지도", systemImage: "map")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.brandPrimary)
                }
            }

            // Pickup Location
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(AppColors.brandPrimary)
                    Text("픽업")
                        .font(.system(size: 14, weight: .medium))
                }

                Text(order.pickupLocation.address)
                    .font(.system(size: 14))
                    .foregroundColor(.black.opacity(0.8))

                if let detailAddress = order.pickupLocation.detailAddress {
                    Text(detailAddress)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                if let note = order.pickupNote {
                    Text("메모: \(note)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .italic()
                }
            }
            .padding(.vertical, 8)

            Divider()

            // Delivery Location
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "flag.circle.fill")
                        .foregroundColor(.red)
                    Text("배달")
                        .font(.system(size: 14, weight: .medium))
                }

                Text(order.deliveryLocation.address)
                    .font(.system(size: 14))
                    .foregroundColor(.black.opacity(0.8))

                if let detailAddress = order.deliveryLocation.detailAddress {
                    Text(detailAddress)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                if let note = order.deliveryNote {
                    Text("메모: \(note)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .italic()
                }
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }

    // MARK: - Items Section

    private func itemsSection(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("주문 항목")
                .font(.system(size: 16, weight: .semibold))

            VStack(spacing: 8) {
                ForEach(order.items, id: \.id) { item in
                    HStack {
                        Text(item.name)
                            .font(.system(size: 14))

                        Text("x\(item.quantity)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)

                        Spacer()

                        Text(item.price.formatted(.currency(code: "KRW")))
                            .font(.system(size: 14, weight: .medium))
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }

    // MARK: - Payment Section

    private func paymentSection(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("결제 정보")
                .font(.system(size: 16, weight: .semibold))

            VStack(spacing: 8) {
                InfoRow(label: "결제 방법", value: order.payment.method.displayName)
                InfoRow(label: "상품 금액", value: order.payment.baseAmount.formatted(.currency(code: "KRW")))
                InfoRow(label: "배달료", value: order.payment.deliveryFee.formatted(.currency(code: "KRW")))

                if order.payment.tip > 0 {
                    InfoRow(label: "팁", value: order.payment.tip.formatted(.currency(code: "KRW")))
                }

                if order.payment.discount > 0 {
                    InfoRow(label: "할인", value: "-\(order.payment.discount.formatted(.currency(code: "KRW")))")
                        .foregroundColor(.red)
                }

                Divider()

                HStack {
                    Text("총 금액")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Text(order.payment.totalAmount.formatted(.currency(code: "KRW")))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.brandPrimary)
                }

                if order.payment.isPaid {
                    Label("결제 완료", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }

    // MARK: - Action Buttons Section

    @ViewBuilder
    private func actionButtonsSection(_ order: Order) -> some View {
        VStack(spacing: 12) {
            if viewModel.canAccept {
                HStack(spacing: 12) {
                    Button(action: { showingRejectReason = true }) {
                        Text("거절")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                    }

                    Button(action: viewModel.acceptOrder) {
                        Text("수락")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColors.brandPrimary)
                            .cornerRadius(8)
                    }
                }
            }

            if viewModel.canStartPickup {
                Button(action: viewModel.startPickup) {
                    Text("픽업 시작")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.brandPrimary)
                        .cornerRadius(8)
                }
            }

            if viewModel.canCompletePickup {
                Button(action: viewModel.completePickup) {
                    Text("픽업 완료")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.brandPrimary)
                        .cornerRadius(8)
                }
            }

            if viewModel.canStartDelivery {
                Button(action: viewModel.startDelivery) {
                    Text("배달 시작")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.brandPrimary)
                        .cornerRadius(8)
                }
            }

            if viewModel.canCompleteOrder {
                VStack(spacing: 12) {
                    Button(action: viewModel.takeDeliveryPhoto) {
                        Label("배달 사진", systemImage: "camera")
                            .font(.system(size: 14, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                    }

                    Button(action: viewModel.requestSignature) {
                        Label("고객 서명", systemImage: "signature")
                            .font(.system(size: 14, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                    }

                    Button(action: viewModel.completeOrder) {
                        Text("배달 완료")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColors.brandPrimary)
                            .cornerRadius(8)
                    }
                }
            }

            // Cancel button for ongoing orders
            if order.status == .accepted || order.status == .pickingUp || order.status == .delivering {
                Button(action: { showingCancelReason = true }) {
                    Text("주문 취소")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red.opacity(0.5), lineWidth: 1)
                        )
                }
            }
        }
        .disabled(viewModel.isLoading)
    }

    // MARK: - Helper Views

    private func orderTypeBadge(_ type: OrderType) -> some View {
        Text(type.displayName)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(type.color)
            .cornerRadius(4)
    }

    // MARK: - Reject Reason Sheet

    private var rejectReasonSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("거절 사유를 선택해주세요")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.top)

                VStack(spacing: 12) {
                    ForEach(RejectReason.allCases, id: \.self) { reason in
                        Button(action: {
                            rejectReason = reason.rawValue
                            viewModel.rejectOrder(reason: rejectReason)
                            showingRejectReason = false
                            dismiss()
                        }) {
                            HStack {
                                Text(reason.displayName)
                                    .font(.system(size: 14))
                                    .foregroundColor(.black)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal)
            .navigationTitle("거절 사유")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        showingRejectReason = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Cancel Reason Sheet

    private var cancelReasonSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("취소 사유를 선택해주세요")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.top)

                VStack(spacing: 12) {
                    ForEach(CancelReason.allCases, id: \.self) { reason in
                        Button(action: {
                            cancelReason = reason.rawValue
                            viewModel.cancelOrder(reason: cancelReason)
                            showingCancelReason = false
                            dismiss()
                        }) {
                            HStack {
                                Text(reason.displayName)
                                    .font(.system(size: 14))
                                    .foregroundColor(.black)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal)
            .navigationTitle("취소 사유")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        showingCancelReason = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.black)
        }
    }
}

// MARK: - Enums

enum RejectReason: String, CaseIterable {
    case tooFar = "DISTANCE"
    case noTime = "NO_TIME"
    case vehicleIssue = "VEHICLE_ISSUE"
    case other = "OTHER"

    var displayName: String {
        switch self {
        case .tooFar: return "거리가 너무 멀어요"
        case .noTime: return "시간이 없어요"
        case .vehicleIssue: return "차량 문제가 있어요"
        case .other: return "기타"
        }
    }
}

enum CancelReason: String, CaseIterable {
    case customerRequest = "CUSTOMER_REQUEST"
    case storeIssue = "STORE_ISSUE"
    case vehicleIssue = "VEHICLE_ISSUE"
    case emergency = "EMERGENCY"
    case other = "OTHER"

    var displayName: String {
        switch self {
        case .customerRequest: return "고객 요청"
        case .storeIssue: return "가게 문제"
        case .vehicleIssue: return "차량 문제"
        case .emergency: return "긴급 상황"
        case .other: return "기타"
        }
    }
}

// MARK: - Extensions

extension Payment.PaymentMethod {
    var displayName: String {
        switch self {
        case .cash: return "현금"
        case .card: return "카드"
        case .prepaid: return "선결제"
        case .postpaid: return "후결제"
        }
    }
}