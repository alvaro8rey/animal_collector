import SwiftUI

struct GachaView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var selectedPack: PackType = .basic
    @State private var isOpeningPack = false
    @State private var pulseStreak = false
    @State private var showAdSimulator = false
    @State private var showPremiumView = false

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
                        packSelector
                        openButton
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
            .fullScreenCover(isPresented: $isOpeningPack) {
                PackOpeningView(packType: selectedPack, isPresented: $isOpeningPack)
                    .environmentObject(vm)
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

            // Streak badge
            streakBadge

            // Pack counter / Premium badge
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
            // Premium badge
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
            // Pack counter
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
                Text("\(vm.obtainedCount) / \(vm.allAnimals.count)")
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
                        .frame(width: geo.size.width * vm.collectionProgress)
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

    // MARK: - Pack Selector

    private var packSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Elige tu sobre")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(1)

            HStack(spacing: 10) {
                ForEach(PackType.allCases) { pack in
                    PackSelectorCard(
                        pack: pack,
                        isSelected: selectedPack == pack,
                        countLabel: countLabel(for: pack),
                        isAvailable: vm.canOpen(pack)
                    )
                    .onTapGesture { selectedPack = pack }
                }
            }
        }
    }

    private func countLabel(for pack: PackType) -> String {
        switch pack {
        case .basic:
            return vm.isPremium ? "∞" : "\(vm.availablePacks)"
        case .daily:
            return vm.isDailyAvailable ? "1" : "0"
        }
    }

    // MARK: - Open Button

    private var openButton: some View {
        let canOpen = vm.canOpen(selectedPack)

        return Button(action: {
            guard canOpen else { return }
            isOpeningPack = true
        }) {
            HStack(spacing: 12) {
                Text(selectedPack.emoji)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(canOpen ? "Abrir \(selectedPack.rawValue)" : "Sin sobres disponibles")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text(selectedPack.description)
                        .font(.caption)
                        .opacity(0.8)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .fontWeight(.semibold)
            }
            .foregroundStyle(canOpen ? .black : .white.opacity(0.4))
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        canOpen
                        ? LinearGradient(colors: selectedPack.gradientColors, startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color(white: 0.12)], startPoint: .leading, endPoint: .trailing)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        canOpen ? .clear : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            )
        }
        .disabled(!canOpen)
        .animation(.spring(response: 0.3), value: canOpen)
    }

    // MARK: - Refill Section (shown when not premium)

    private var refillSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Conseguir más sobres")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(1)

            HStack(spacing: 10) {
                // Watch Ad
                RefillButton(
                    icon: "play.rectangle.fill",
                    title: "Ver anuncio",
                    subtitle: "+2 sobres · Gratis",
                    gradientColors: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.4, green: 0.2, blue: 0.9)]
                ) {
                    showAdSimulator = true
                }

                // Premium
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
                    title: "Abrir el sobre diario",
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

// MARK: - Pack Selector Card

private struct PackSelectorCard: View {
    let pack: PackType
    let isSelected: Bool
    let countLabel: String
    let isAvailable: Bool

    private var countColor: Color {
        isAvailable ? pack.gradientColors[0] : Color.white.opacity(0.3)
    }

    private var borderGradient: LinearGradient {
        isSelected
            ? pack.gradient
            : LinearGradient(colors: [Color.white.opacity(0.08)], startPoint: .leading, endPoint: .trailing)
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(pack.emoji)
                .font(.title2)
            Text(pack.rawValue)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
            Text(countLabel)
                .font(.caption2)
                .foregroundStyle(countColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.white.opacity(0.0) : Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? AnyShapeStyle(pack.gradient.opacity(0.2)) : AnyShapeStyle(Color.clear))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(borderGradient, lineWidth: isSelected ? 1.5 : 1)
                )
        )
        .animation(.spring(response: 0.25), value: isSelected)
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
