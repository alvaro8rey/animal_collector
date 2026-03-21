import SwiftUI

struct CollectionView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var selectedCategory: Category? = nil
    @State private var selectedRarity: Rarity? = nil
    @State private var showOnlyObtained = false
    @State private var showOnlyFavorites = false
    @State private var selectedAnimal: Animal? = nil
    @State private var searchText = ""

    private var filteredAnimals: [Animal] {
        vm.collection.filter { animal in
            if let cat = selectedCategory, animal.category != cat { return false }
            if let rar = selectedRarity, animal.rarity != rar { return false }
            if showOnlyObtained && !animal.isObtained { return false }
            if showOnlyFavorites && !animal.isFavorite { return false }
            if !searchText.isEmpty {
                return animal.name.localizedCaseInsensitiveContains(searchText)
            }
            return true
        }
        .sorted {
            if $0.isObtained != $1.isObtained { return $0.isObtained }
            if $0.rarity != $1.rarity { return $0.rarity > $1.rarity }
            return $0.collectionNumber < $1.collectionNumber
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(white: 0.04).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    // Category progress strip
                    categoryStrip
                        .padding(.top, 12)

                    // Filter row
                    filterRow
                        .padding(.horizontal, 16)
                        .padding(.top, 10)

                    // Stats bar
                    statsBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    // Grid
                    if filteredAnimals.isEmpty {
                        emptyState
                    } else {
                        animalGrid
                    }
                }
            }
            .navigationTitle("Colección")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(white: 0.04), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $selectedAnimal) { animal in
                CardDetailView(animal: animal)
                    .environmentObject(vm)
            }
        }
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.35))
                .font(.subheadline)

            TextField("Buscar animal...", text: $searchText)
                .font(.subheadline)
                .foregroundStyle(.white)
                .tint(.white)

            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.07))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.white.opacity(0.08), lineWidth: 1))
        )
    }

    // MARK: - Category Strip

    private var categoryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All
                CategoryChip(
                    label: "Todas",
                    icon: "🌍",
                    color: .white,
                    isSelected: selectedCategory == nil
                ) { selectedCategory = nil }

                ForEach(Category.allCases, id: \.self) { cat in
                    let prog = vm.progress(for: cat)
                    CategoryChip(
                        label: cat.rawValue,
                        icon: cat.icon,
                        color: cat.color,
                        isSelected: selectedCategory == cat,
                        progress: prog
                    ) { selectedCategory = selectedCategory == cat ? nil : cat }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Filter Row

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    label: "Obtenidas",
                    icon: "checkmark.circle",
                    isActive: showOnlyObtained
                ) { showOnlyObtained.toggle() }

                FilterChip(
                    label: "Favoritas",
                    icon: "heart.fill",
                    isActive: showOnlyFavorites
                ) { showOnlyFavorites.toggle() }

                Divider()
                    .frame(height: 20)
                    .overlay(Color.white.opacity(0.12))

                ForEach(Rarity.allCases, id: \.self) { rarity in
                    RarityFilterChip(
                        rarity: rarity,
                        isSelected: selectedRarity == rarity
                    ) {
                        selectedRarity = selectedRarity == rarity ? nil : rarity
                    }
                }
            }
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: 16) {
            Label("\(filteredAnimals.filter(\.isObtained).count) obtenidas", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green.opacity(0.8))

            Spacer()

            Text("\(filteredAnimals.count) cartas")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.35))
        }
    }

    // MARK: - Grid

    private var animalGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 12) {
                ForEach(filteredAnimals) { animal in
                    CollectionCardCell(animal: animal)
                        .onTapGesture {
                            guard animal.isObtained else { return }
                            selectedAnimal = animal
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("🔍")
                .font(.system(size: 48))
            Text("Sin resultados")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.5))
            Text("Prueba otros filtros")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.3))
            Spacer()
        }
    }
}

// MARK: - Collection Card Cell

private struct CollectionCardCell: View {
    let animal: Animal

    var body: some View {
        if animal.isObtained {
            ZStack(alignment: .topTrailing) {
                AnimalCardView(animal: animal, isRevealed: true, size: .small)

                if animal.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                        .padding(5)
                }
            }
        } else {
            // Completamente oculta — sin datos, sin interacción
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.09))

                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)

                VStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.18))
                    Text("???")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.15))
                }
            }
            .frame(width: 100, height: 140)
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Category Chip

private struct CategoryChip: View {
    let label: String
    let icon: String
    let color: Color
    let isSelected: Bool
    var progress: (obtained: Int, total: Int)? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 5) {
                    Text(icon).font(.caption)
                    Text(label)
                        .font(.caption)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? color : .white.opacity(0.55))
                }

                if let prog = progress {
                    HStack(spacing: 4) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.1))
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(color.opacity(0.7))
                                    .frame(width: prog.total > 0
                                           ? geo.size.width * CGFloat(prog.obtained) / CGFloat(prog.total)
                                           : 0)
                            }
                        }
                        .frame(height: 3)
                        Text("\(prog.obtained)/\(prog.total)")
                            .font(.system(size: 8))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    .frame(width: 70)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? color.opacity(0.15) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isSelected ? color.opacity(0.5) : .white.opacity(0.07), lineWidth: 1)
                    )
            )
        }
        .animation(.spring(response: 0.25), value: isSelected)
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let label: String
    let icon: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.caption)
                .fontWeight(isActive ? .semibold : .regular)
                .foregroundStyle(isActive ? .white : .white.opacity(0.45))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isActive ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
                        .overlay(Capsule().strokeBorder(isActive ? .white.opacity(0.3) : .white.opacity(0.07), lineWidth: 1))
                )
        }
        .animation(.spring(response: 0.25), value: isActive)
    }
}

// MARK: - Rarity Filter Chip

private struct RarityFilterChip: View {
    let rarity: Rarity
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(rarity.displayName)
                .font(.caption2)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundStyle(isSelected ? rarity.glowColor : .white.opacity(0.4))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(isSelected ? rarity.glowColor.opacity(0.15) : Color.white.opacity(0.04))
                        .overlay(Capsule().strokeBorder(isSelected ? rarity.glowColor.opacity(0.5) : .white.opacity(0.07), lineWidth: 1))
                )
        }
        .animation(.spring(response: 0.2), value: isSelected)
    }
}
