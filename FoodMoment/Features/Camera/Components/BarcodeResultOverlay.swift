import SwiftUI

// MARK: - BarcodeResultOverlay

/// Overlay view displaying detected barcode information.
/// Shows the barcode value, type, and provides actions to look up or dismiss.
struct BarcodeResultOverlay: View {

    // MARK: - Properties

    let result: BarcodeResult
    let onLookup: () -> Void
    let onDismiss: () -> Void

    // MARK: - State

    @State private var isAnimating = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            resultCard
        }
        .onAppear {
            startPulseAnimation()
        }
    }

    // MARK: - Result Card

    private var resultCard: some View {
        VStack(spacing: 16) {
            headerSection

            barcodeValueSection

            actionButtonsSection
        }
        .padding(20)
        .background(cardBackground)
        .padding(.horizontal, 16)
        .padding(.bottom, 100)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 12) {
            pulsingIcon

            VStack(alignment: .leading, spacing: 2) {
                Text("已识别条码")
                    .font(.Jakarta.semiBold(16))
                    .foregroundColor(.white)

                Text(result.displayType)
                    .font(.Jakarta.regular(13))
                    .foregroundColor(.gray)
            }

            Spacer()

            closeButton
        }
    }

    // MARK: - Pulsing Icon

    private var pulsingIcon: some View {
        ZStack {
            Circle()
                .fill(AppTheme.Colors.primary.opacity(0.2))
                .frame(width: 48, height: 48)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .opacity(isAnimating ? 0 : 0.5)

            Circle()
                .fill(AppTheme.Colors.primary.opacity(0.3))
                .frame(width: 48, height: 48)

            Image(systemName: "barcode.viewfinder")
                .font(.Jakarta.regular(22))
                .foregroundColor(AppTheme.Colors.primary)
        }
    }

    // MARK: - Close Button

    private var closeButton: some View {
        Button {
            onDismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.Jakarta.medium(14))
                .foregroundColor(.gray)
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
    }

    // MARK: - Barcode Value Section

    private var barcodeValueSection: some View {
        HStack {
            Text(result.payload)
                .font(.system(size: 20, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer()

            copyButton
        }
        .padding(12)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Copy Button

    private var copyButton: some View {
        Button {
            UIPasteboard.general.string = result.payload
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } label: {
            Image(systemName: "doc.on.doc")
                .font(.Jakarta.regular(14))
                .foregroundColor(.gray)
        }
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            scanAgainButton
            lookUpButton
        }
    }

    // MARK: - Scan Again Button

    private var scanAgainButton: some View {
        Button {
            onDismiss()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.counterclockwise")
                Text("重新扫描")
            }
            .font(.Jakarta.medium(15))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Look Up Button

    private var lookUpButton: some View {
        Button {
            onLookup()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                Text("查询")
            }
            .font(.Jakarta.semiBold(15))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(AppTheme.Colors.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }

    // MARK: - Private Methods

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            isAnimating = true
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        BarcodeResultOverlay(
            result: BarcodeResult(
                payload: "5901234123457",
                symbology: .ean13,
                boundingBox: .zero
            ),
            onLookup: {},
            onDismiss: {}
        )
    }
}
