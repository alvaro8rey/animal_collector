import SwiftUI

struct GachaView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var selectedPack: PackType = .basic
    @State private var isOpeningPack = false
    @State private var pulseStreak = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark gradient background
                LinearGradient(
                    colors: [Color(white: 0.06), Color(white: 0.03)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerBar
                        progressSection
                        packSelector
                        openButton
                        shopSection
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

            // Coins
            HStack(spacing: 5) {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundStyle(.yellow)
                Text("\(vm.coins)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color.yellow.opacity(0.12))
                    .overlay(Capsule().strokeBorder(Color.yellow.opacity(0.3), lineWidth: 0.8))
            )
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
                        count: packCount(for: pack),
                        isAvailable: vm.canOpen(pack)
                    )
                    .onTapGesture { selectedPack = pack }
                }
            }
        }
    }

    private func packCount(for pack: PackType) -> String {
        switch pack {
        case .basic: return "\(vm.basicPacks)"
        case .daily: return vm.isDailyAvailable ? "1" : "0"
        case .premium: return "\(vm.premiumPacks)"
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
                    Text(canOpen ? "Abrir \(selectedPack.rawValue)" : "No disponible")
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

    // MARK: - Shop

    private var shopSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tienda")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(1)

            HStack(spacing: 10) {
                ShopItemView(
                    emoji: "📦",
                    title: "Sobre Básico",
                    cost: PackType.basic.cost,
                    canAfford: vm.coins >= PackType.basic.cost
                ) {
                    vm.buyBasicPack()
                }

                ShopItemView(
                    emoji: "🎁",
                    title: "Diario",
                    cost: 0,
                    canAfford: vm.isDailyAvailable,
                    isFree: true
                ) {
                    if vm.isDailyAvailable {
                        vm.claimDailyPack()
                    }
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
    let count: String
    let isAvailable: Bool

    private var countLabel: String {
        pack == .daily && count == "0" ? "✓" : "×\(count)"
    }

    private var countColor: Color {
        isAvailable ? pack.gradientColors[0] : Color.white.opacity(0.3)
    }

    private var nameColor: Color {
        isSelected ? Color.white : Color.white.opacity(0.5)
    }

    private var borderGradient: LinearGradient {
        if isSelected {
            return pack.gradient
        }
        return LinearGradient(colors: [Color.white.opacity(0.08)], startPoint: .leading, endPoint: .trailing)
    }

    private var fillColor: Color {
        isSelected ? Color.white.opacity(0.0) : Color.white.opacity(0.04)
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(pack.emoji)
                .font(.title2)
            Text(pack.rawValue)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(nameColor)
            Text(countLabel)
                .font(.caption2)
                .foregroundStyle(countColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(fillColor)
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

// MARK: - Shop Item

private struct ShopItemView: View {
    let emoji: String
    let title: String
    let cost: Int
    let canAfford: Bool
    var isFree: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(emoji).font(.title2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.8))
                Group {
                    if isFree {
                        Text(canAfford ? "GRATIS" : "Reclamado")
                            .foregroundStyle(canAfford ? .green : .white.opacity(0.3))
                    } else {
                        HStack(spacing: 3) {
                            Image(systemName: "dollarsign.circle.fill").foregroundStyle(.yellow)
                            Text("\(cost)").foregroundStyle(canAfford ? .white : .red.opacity(0.7))
                        }
                    }
                }
                .font(.caption2)
                .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(canAfford ? 0.06 : 0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .disabled(!canAfford)
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
