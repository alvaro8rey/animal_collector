import SwiftUI

struct ExchangeView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var obtainedAnimal: Animal? = nil
    @State private var showResult = false
    @State private var animateResult = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        headerSection
                        exchangeRows
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Intercambio")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showResult) {
            if let animal = obtainedAnimal {
                ExchangeResultSheet(animal: animal, isPresented: $showResult)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Convierte duplicados en nuevas cartas")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 24)
        }
    }

    // MARK: - Exchange rows

    private var exchangeRows: some View {
        VStack(spacing: 16) {
            ForEach(GameViewModel.exchangeRates, id: \.from) { rate in
                ExchangeRow(
                    fromRarity: rate.from,
                    toRarity: rate.to,
                    cost: rate.cost,
                    currentDupes: vm.totalDuplicates(for: rate.from),
                    missingTargets: vm.unownedAnimals(of: rate.to).isEmpty,
                    canExchange: vm.canExchange(from: rate.from)
                ) {
                    if let animal = vm.exchangeDuplicates(from: rate.from) {
                        obtainedAnimal = animal
                        showResult = true
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Exchange Row

private struct ExchangeRow: View {
    let fromRarity: Rarity
    let toRarity: Rarity
    let cost: Int
    let currentDupes: Int
    let missingTargets: Bool
    let canExchange: Bool
    let onExchange: () -> Void

    @State private var pressing = false

    private var progress: Double { min(Double(currentDupes) / Double(cost), 1.0) }

    var body: some View {
        VStack(spacing: 14) {
            // Rarity arrows
            HStack(spacing: 12) {
                rarityChip(fromRarity)
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray)
                rarityChip(toRarity)
                Spacer()
                costBadge
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(currentDupes) / \(cost) duplicados")
                        .font(.caption)
                        .foregroundColor(currentDupes >= cost ? fromRarity.color : .gray)
                    Spacer()
                    if missingTargets {
                        Text("Colección \(toRarity.displayName) completa")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: fromRarity.gradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress, height: 6)
                            .animation(.easeOut(duration: 0.4), value: progress)
                    }
                }
                .frame(height: 6)
            }

            // Exchange button
            Button(action: onExchange) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.2.circlepath")
                        .font(.system(size: 13, weight: .semibold))
                    Text(buttonLabel)
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(buttonBackground)
                .cornerRadius(12)
                .scaleEffect(pressing ? 0.97 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: pressing)
            }
            .disabled(!canExchange)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pressing = true }
                    .onEnded { _ in pressing = false }
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            canExchange
                                ? fromRarity.borderGradient
                                : LinearGradient(colors: [Color.white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: canExchange ? 1.5 : 1
                        )
                )
        )
    }

    private var buttonLabel: String {
        if missingTargets { return "Ya tienes todas las \(toRarity.displayName)" }
        if currentDupes >= cost { return "Canjear por 1 \(toRarity.displayName)" }
        return "Faltan \(cost - currentDupes) duplicados"
    }

    @ViewBuilder
    private var buttonBackground: some View {
        if canExchange {
            LinearGradient(
                colors: fromRarity.gradientColors,
                startPoint: .leading,
                endPoint: .trailing
            )
            .opacity(0.85)
        } else {
            Color.white.opacity(0.07)
        }
    }

    private var costBadge: some View {
        Text("\(cost) dupes")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .foregroundColor(.gray)
    }

    private func rarityChip(_ rarity: Rarity) -> some View {
        Text(rarity.displayName)
            .font(.caption.weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                LinearGradient(
                    colors: rarity.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ).opacity(0.25)
            )
            .overlay(
                Capsule()
                    .strokeBorder(rarity.color.opacity(0.5), lineWidth: 1)
            )
            .clipShape(Capsule())
            .foregroundColor(rarity.color)
    }
}

// MARK: - Result Sheet

private struct ExchangeResultSheet: View {
    let animal: Animal
    @Binding var isPresented: Bool
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // Title
                VStack(spacing: 6) {
                    Text("¡Nuevo animal!")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                    Text("Has canjeado tus duplicados")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : -12)

                // Card
                AnimalCardView(animal: animal, isRevealed: true, size: .large)
                    .shadow(color: animal.rarity.glowColor.opacity(0.6), radius: 30)
                    .scaleEffect(appeared ? 1 : 0.7)
                    .opacity(appeared ? 1 : 0)

                // Animal info
                VStack(spacing: 4) {
                    Text(animal.name)
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                    Text(animal.scientificName)
                        .font(.caption)
                        .italic()
                        .foregroundColor(.gray)
                    RarityBadgeView(rarity: animal.rarity)
                        .padding(.top, 4)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)

                Spacer()

                Button(action: { isPresented = false }) {
                    Text("Continuar")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: animal.rarity.gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
        }
    }
}
