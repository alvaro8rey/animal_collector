# AnimalCards — Gacha Collector App

App de coleccionismo tipo gacha para iPhone centrada en animales, construida con SwiftUI.

## Cómo abrir en Xcode

### Opción 1: XcodeGen (recomendado)

```bash
brew install xcodegen
cd animal_collector
xcodegen generate
open AnimalCollector.xcodeproj
```

### Opción 2: Swift Package (para preview)

Abre la carpeta `AnimalCollector/` directamente en Xcode 15+ como un proyecto SwiftUI.

## Estructura del proyecto

```
AnimalCollector/
├── AnimalCollectorApp.swift       # Entry point
├── Models/
│   ├── Animal.swift               # Modelo de carta
│   ├── Rarity.swift               # Enum de rareza (Common → Legendary)
│   ├── Category.swift             # Categorías (Océano, Insectos…)
│   └── PackType.swift             # Tipos de sobre
├── Data/
│   └── AnimalData.swift           # 50 animales con datos reales
├── Services/
│   ├── GachaEngine.swift          # Lógica de sorteo con pity system
│   └── PersistenceService.swift   # Guardado local con UserDefaults
├── ViewModels/
│   └── GameViewModel.swift        # Estado global de la app
└── Views/
    ├── ContentView.swift           # TabBar principal
    ├── GachaView.swift             # Pantalla principal de sobres
    ├── PackOpeningView.swift       # Flujo de apertura + animación flip
    ├── CollectionView.swift        # Biblioteca con filtros
    ├── CardDetailView.swift        # Vista de detalle de carta
    └── Components/
        ├── AnimalCardView.swift    # Componente de carta reutilizable
        └── RarityBadgeView.swift   # Badge de rareza
```

## Contenido — 50 animales en 7 categorías

| Categoría   | Cartas | Ejemplo destacado       |
|-------------|--------|-------------------------|
| Océano      | 10     | Medusa Inmortal (Leg.)  |
| Insectos    | 8      | Mantis Orquídea (Rare)  |
| Mamíferos   | 10     | Pangolín (Epic)          |
| Aves        | 8      | Águila Harpía (Epic)     |
| Reptiles    | 6      | Komodo (Rare)            |
| Anfibios    | 4      | Ajolote (Epic)           |
| Extintos    | 4      | Tigre Tasmania (Leg.)   |

## Rarezas y probabilidades

| Rareza    | Peso base | Color     |
|-----------|-----------|-----------|
| Common    | 40%       | Gris      |
| Uncommon  | 30%       | Verde     |
| Rare      | 20%       | Azul      |
| Epic      | 7%        | Morado    |
| Legendary | 3%        | Dorado    |

- **Última carta garantizada Rare+** en todos los sobres
- **Pity system**: tras 10 sobres sin Epic+, se garantiza uno
- **Duplicados**: dan 25 monedas cada uno

## Requisitos

- iOS 17.0+
- Xcode 15+
- Swift 5.9+
