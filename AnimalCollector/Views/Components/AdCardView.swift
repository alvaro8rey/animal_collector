import SwiftUI
import GoogleMobileAds

// MARK: - Ad Card shown inside the pack opening carousel

struct AdCardView: View {
    var body: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: [Color(white: 0.11), Color(white: 0.07)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))

            VStack(spacing: 0) {
                // Top: ad badge
                HStack {
                    Text("PUBLICIDAD")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.28))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.07)))
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)

                Spacer()

                // Banner ad scaled to fit the card width
                BannerAdView(adUnitID: adUnitID)
                    .frame(width: 300, height: 250)
                    .scaleEffect(190.0 / 300.0)
                    .frame(width: 190, height: 158)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Spacer()

                // Bottom: skip hint
                HStack(spacing: 4) {
                    Text("Desliza para continuar")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.22))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.22))
                }
                .padding(.bottom, 14)
            }

            // Border
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
        }
        .frame(width: 220, height: 308)
    }

    private var adUnitID: String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/6300978111" // Google test banner
        #else
        return "ca-app-pub-9606090335798660/1746255808"
        #endif
    }
}

// MARK: - GADBannerView wrapper

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeMediumRectangle)
        banner.adUnitID = adUnitID
        banner.rootViewController = UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}
