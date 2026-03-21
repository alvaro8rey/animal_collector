import SwiftUI

/// Premium paywall stub. Replace the purchase action with a real StoreKit call when ready.
struct PremiumView: View {
    @EnvironmentObject var vm: GameViewModel
    @Binding var isPresented: Bool

    @State private var isPurchasing = false

    private let benefits: [(icon: String, title: String, detail: String)] = [
        ("infinity",            "Sobres ilimitados",    "Abre todos los sobres que quieras, sin límite"),
        ("play.slash.fill",     "Sin anuncios",         "Disfruta sin interrupciones de ningún tipo"),
        ("crown.fill",          "Icono de corona",      "Distintivo exclusivo de miembro Premium"),
        ("arrow.clockwise",     "Restablecimiento",     "Recupera 5 sobres diarios como regalo de bienvenida"),
    ]

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(white: 0.06), Color(white: 0.03)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.top, 24)

                // Benefits list
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(benefits, id: \.title) { b in
                            BenefitRow(icon: b.icon, title: b.title, detail: b.detail)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .padding(.bottom, 16)
                }

                Divider()
                    .background(Color.white.opacity(0.08))

                // Purchase section
                purchaseSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    .padding(.top, 20)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(20)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.2)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "crown.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
            }

            Text("AnimalCards Premium")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("La experiencia completa, sin límites")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    // MARK: - Purchase

    private var purchaseSection: some View {
        VStack(spacing: 14) {
            // Price tag
            VStack(spacing: 4) {
                Text("1,99 € / mes")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text("Cancela cuando quieras · Sin compromiso")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }

            // Subscribe button
            Button(action: purchase) {
                HStack(spacing: 10) {
                    if isPurchasing {
                        ProgressView()
                            .tint(.black)
                            .scaleEffect(0.85)
                    } else {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.black)
                    }
                    Text(isPurchasing ? "Procesando..." : "Activar Premium")
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                )
            }
            .disabled(isPurchasing)

            // Restore purchases (stub)
            Button(action: {}) {
                Text("Restaurar compras")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
    }

    // MARK: - Action

    private func purchase() {
        isPurchasing = true
        // Stub: simulate a 1.5s network/StoreKit delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            vm.activatePremium()
            isPurchasing = false
            isPresented = false
        }
    }
}

// MARK: - Benefit Row

private struct BenefitRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.2), Color.orange.opacity(0.15)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(
                        LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                    )
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.06), lineWidth: 1))
        )
    }
}
