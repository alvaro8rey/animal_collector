import SwiftUI

struct GachaView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var isOpeningPack = false
    @State private var pulseStreak = false
    @State private var showAdSimulator = false
    @State private var showPremiumView = false
    @State private var packPulse = false
    @State private var dailyBanner = false
    @State private var shakeAngle: Double = 0
    @State private var isShaking = false
    @State private var pendingCards: [Animal] = []
    @State private var frozenProgress: Double? = nil
    @State private var frozenObtainedCount: Int? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(white: 0.06), Color(white: 0.03)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerBar
                        progressSection
                        packSection
                        if !vm.isPremium {
                            refillSection
                        }
                        dailyMissions
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                let wasDailyAvailable = vm.isDailyAvailable
                vm.claimDailyIfAvailable()
                if wasDailyAvailable {
                    withAnimation(.spring(response: 0.4)) { dailyBanner = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation { dailyBanner = false }
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                        packPulse = true
                    }
                }
            }
            .fullScreenCover(isPresented: $isOpeningPack) {
                PackOpeningView(packType: .basic, isPresented: $isOpeningPack, preDrawnCards: pendingCards)
                    .environmentObject(vm)
            }
            .onChange(of: isOpeningPack) { newValue in
                if !newValue {
                    shakeAngle = 0
                    isShaking = false
                    pendingCards = []
                    // Descongelar el progreso ahora que la animación ha terminado
                    frozenProgress = nil
                    frozenObtainedCount = nil
                }
            }
            .fullScreenCover(isPresented: $showAdSimulator) {
                AdSimulatorView(isPresented: $showAdSimulator)
                    .environmentObject(vm)
            }
            .sheet(isPresented: $showPremiumView) {
                PremiumView(isPresented: $showPremiumView)
                    .environmentObject(vm)
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("AnimalCards")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text("Colecciona el mundo animal")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()

            packCounterBadge
        }
        .padding(.top, 16)
    }

    private var streakBadge: some View {
        HStack(spacing: 4) {
            Text("🔥")
                .font(.subheadline)
                .shadow(color: .orange.opacity(pulseStreak ? 0.85 : 0.0), radius: pulseStreak ? 7 : 1)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulseStreak)
            Text("\(vm.streak)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.orange)
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(Color.orange.opacity(0.12))
                .overlay(Capsule().strokeBorder(Color.orange.opacity(0.3), lineWidth: 0.8))
        )
        .padding(.trailing, 8)
        .onAppear { pulseStreak = vm.streak > 0 }
    }

    @ViewBuilder
    private var packCounterBadge: some View {
        if vm.isPremium {
            Button(action: { showPremiumView = true }) {
                HStack(spacing: 5) {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundStyle(
                            LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                        )
                    Text("Premium")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(Color.yellow.opacity(0.12))
                        .overlay(Capsule().strokeBorder(Color.yellow.opacity(0.3), lineWidth: 0.8))
                )
            }
        } else {
            HStack(spacing: 5) {
                Text("📦")
                    .font(.subheadline)
                Text("\(vm.availablePacks)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(vm.availablePacks == 0 ? .red.opacity(0.8) : .white)
                    .monospacedDigit()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color.white.opacity(0.07))
                    .overlay(Capsule().strokeBorder(
                        vm.availablePacks == 0 ? Color.red.opacity(0.3) : Color.white.opacity(0.12),
                        lineWidth: 0.8
                    ))
            )
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Colección")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(1)
                Spacer()
                Text("\(frozenObtainedCount ?? vm.obtainedCount) / \(vm.allAnimals.count)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * (frozenProgress ?? vm.collectionProgress))
                        .animation(.spring(response: 0.8), value: vm.collectionProgress)
                }
            }
            .frame(height: 6)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.06), lineWidth: 1))
        )
    }

    // MARK: - Pack Section (main interactive area)

    private var packSection: some View {
        let canOpen = vm.isPremium || vm.availablePacks > 0

        return VStack(spacing: 16) {

            // Daily reward banner
            if dailyBanner {
                HStack(spacing: 8) {
                    Text("🎁")
                    Text("+1 sobre diario añadido")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.18))
                        .overlay(Capsule().strokeBorder(Color.green.opacity(0.4), lineWidth: 1))
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Pack count label
            if vm.isPremium {
                Text("Sobres ilimitados")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.yellow.opacity(0.85))
            } else {
                Text(vm.availablePacks == 0
                     ? "Sin sobres disponibles"
                     : "\(vm.availablePacks) sobre\(vm.availablePacks != 1 ? "s" : "") disponible\(vm.availablePacks != 1 ? "s" : "")")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(vm.availablePacks == 0 ? .red.opacity(0.8) : .white)
                    .animation(.spring(response: 0.3), value: vm.availablePacks)
            }

            // Pack image — tappable
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(
                            Color(red: 0.25, green: 0.5, blue: 1.0).opacity(canOpen ? (0.18 - Double(i) * 0.05) : 0.05),
                            lineWidth: 1
                        )
                        .frame(width: CGFloat(150 + i * 40))
                }

                PackImageView()
                    .rotationEffect(.degrees(shakeAngle))
                    .scaleEffect(packPulse && canOpen && !isShaking ? 1.03 : 1.0)
                    .opacity(canOpen ? 1.0 : 0.4)
                    .shadow(
                        color: canOpen ? Color(red: 0.25, green: 0.5, blue: 1.0).opacity(0.5) : .clear,
                        radius: 24
                    )
            }
            .contentShape(Rectangle())
            .onTapGesture {
                guard canOpen, !isShaking else { return }
                openPackWithShake()
            }

            // Tap label
            if canOpen && !isShaking {
                Text("▲  TOCA PARA ABRIR  ▲")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.yellow)
                    .tracking(2)
                    .onTapGesture {
                        guard !isShaking else { return }
                        openPackWithShake()
                    }
            } else if !canOpen {
                Text("Consigue más sobres viendo un anuncio")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
    }

    // MARK: - Refill Section

    private var refillSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Conseguir más sobres")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(1)

            HStack(spacing: 10) {
                RefillButton(
                    icon: "play.rectangle.fill",
                    title: "Ver anuncio",
                    subtitle: "+2 sobres · Gratis",
                    gradientColors: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.4, green: 0.2, blue: 0.9)]
                ) {
                    showAdSimulator = true
                }

                RefillButton(
                    icon: "crown.fill",
                    title: "Premium",
                    subtitle: "Sobres ilimitados",
                    gradientColors: [.yellow, .orange]
                ) {
                    showPremiumView = true
                }
            }
        }
    }

    // MARK: - Shake & Open

    private func openPackWithShake() {
        // Congelar el progreso actual antes de que openPack actualice la colección
        frozenProgress = vm.collectionProgress
        frozenObtainedCount = vm.obtainedCount
        isShaking = true
        pendingCards = vm.openPack(.basic).sorted { $0.rarity < $1.rarity }

        let gen = UIImpactFeedbackGenerator(style: .heavy)
        gen.prepare()

        let angles: [Double] = [
            // Fase fuerte (~1.5s)
            0, -11, 10, -10, 9, -9, 8, -8, 7, -7,
            6, -6, 5, -5, 5, -5, 4, -4, 4, -4,
            3, -3, 2, -2, 1, -1, 0, -1, 1, -1, 0,
            // Fase extendida (+1s)
            -3, 3, -3, 3, -2, 2, -2, 2, -2, 2,
            -1, 1, -1, 1, -1, 1, -1, 0, -1, 0
        ]
        for (i, angle) in angles.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                withAnimation(.easeInOut(duration: 0.04)) { shakeAngle = angle }
                if i > 0 && i % 2 == 1 {
                    let intensity: CGFloat = i < 14 ? 1.0 : max(0.4, 1.0 - Double(i - 14) * 0.05)
                    gen.impactOccurred(intensity: intensity)
                    gen.prepare()
                }
            }
        }

        // Al terminar el shake, abrir el carrusel (+1s respecto al original)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.65) {
            isOpeningPack = true
        }
    }

    // MARK: - Daily Missions

    private var dailyMissions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Misiones")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(1)

            VStack(spacing: 8) {
                MissionRowView(
                    icon: "gift.fill",
                    title: "Reclamar recompensa diaria",
                    isDone: !vm.isDailyAvailable
                )
                MissionRowView(
                    icon: "square.grid.3x3.fill",
                    title: "Revisar tu colección",
                    isDone: vm.obtainedCount > 0
                )
                MissionRowView(
                    icon: "star.fill",
                    title: "Conseguir una carta Rare+",
                    isDone: vm.collection.contains { $0.isObtained && $0.rarity >= .rare }
                )
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.04))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.06), lineWidth: 1))
            )
        }
    }
}

// MARK: - Refill Button

private struct RefillButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradientColors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                                .opacity(0.2)
                        )
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 17))
                        .foregroundStyle(
                            LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottom)
                        )
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                LinearGradient(colors: gradientColors.map { $0.opacity(0.4) },
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1
                            )
                    )
            )
        }
    }
}

// MARK: - Mission Row

private struct MissionRowView: View {
    let icon: String
    let title: String
    let isDone: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isDone ? "checkmark.circle.fill" : icon)
                .foregroundStyle(isDone ? .green : .white.opacity(0.4))
                .font(.subheadline)
                .frame(width: 20)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(isDone ? .white.opacity(0.4) : .white.opacity(0.8))
                .strikethrough(isDone, color: .white.opacity(0.3))

            Spacer()

            if isDone {
                Text("✓")
                    .font(.caption)
                    .foregroundStyle(.green.opacity(0.7))
            }
        }
    }
}
