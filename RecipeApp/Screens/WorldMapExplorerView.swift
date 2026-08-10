import MapKit
import SwiftData
import SwiftUI

struct WorldMapExplorerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var recipes: [RecipeModel]
    
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20.0, longitude: 10.0),
            span: MKCoordinateSpan(latitudeDelta: 100.0, longitudeDelta: 100.0)
        )
    )
    
    @State private var selectedRecipe: RecipeModel?
    @State private var selectedRegionFilter: String = "All"
    
    struct ContinentInfo: Identifiable {
        let id: String
        let title: String
        let icon: String
        let center: CLLocationCoordinate2D
        let span: Double
    }
    
    let continents: [ContinentInfo] = [
        ContinentInfo(id: "All", title: "All Continents", icon: "globe.americas.fill", center: CLLocationCoordinate2D(latitude: 20.0, longitude: 10.0), span: 110.0),
        ContinentInfo(id: "Africa", title: "Africa", icon: "flame.fill", center: CLLocationCoordinate2D(latitude: 7.0, longitude: 28.0), span: 45.0),
        ContinentInfo(id: "Asia", title: "Asia", icon: "sparkles", center: CLLocationCoordinate2D(latitude: 28.0, longitude: 95.0), span: 55.0),
        ContinentInfo(id: "Europe", title: "Europe", icon: "building.columns.fill", center: CLLocationCoordinate2D(latitude: 48.0, longitude: 10.0), span: 25.0),
        ContinentInfo(id: "North America", title: "North America", icon: "flag.fill", center: CLLocationCoordinate2D(latitude: 38.0, longitude: -97.0), span: 45.0),
        ContinentInfo(id: "South America", title: "South America", icon: "leaf.fill", center: CLLocationCoordinate2D(latitude: -18.0, longitude: -60.0), span: 45.0),
        ContinentInfo(id: "Oceania", title: "Oceania", icon: "sun.max.fill", center: CLLocationCoordinate2D(latitude: -25.0, longitude: 135.0), span: 40.0),
        ContinentInfo(id: "Antarctica", title: "Antarctica", icon: "snowflake", center: CLLocationCoordinate2D(latitude: -82.0, longitude: 0.0), span: 30.0)
    ]
    
    var geoRecipes: [RecipeModel] {
        recipes.filter { $0.coordinate != nil }
    }
    
    var filteredGeoRecipes: [RecipeModel] {
        if selectedRegionFilter == "All" {
            return geoRecipes
        }
        return geoRecipes.filter { recipe in
            guard let lat = recipe.latitude, let lon = recipe.longitude else { return false }
            let cat = recipe.category?.name ?? ""
            let tags = recipe.tags
            
            switch selectedRegionFilter {
            case "Africa":
                return cat.contains("African") || cat.contains("Ethiopian") || tags.contains("African") || tags.contains("Ethiopian") || tags.contains("Nigerian") || (lat >= -35 && lat <= 37 && lon >= -20 && lon <= 55)
            case "Asia":
                return cat.contains("Asian") || tags.contains("Asian") || tags.contains("Japanese") || tags.contains("Indian") || tags.contains("Thai") || (lat >= -10 && lat <= 70 && lon >= 60 && lon <= 150)
            case "Europe":
                return cat.contains("European") || tags.contains("European") || tags.contains("Italian") || tags.contains("French") || tags.contains("Spanish") || (lat >= 35 && lat <= 70 && lon >= -15 && lon <= 45)
            case "North America":
                return cat.contains("North American") || tags.contains("North American") || tags.contains("Mexican") || tags.contains("Canadian") || tags.contains("American") || (lat >= 15 && lat <= 70 && lon >= -170 && lon <= -50)
            case "South America":
                return cat.contains("South American") || tags.contains("South American") || tags.contains("Peruvian") || tags.contains("Brazilian") || (lat >= -56 && lat <= 13 && lon >= -85 && lon <= -34)
            case "Oceania":
                return cat.contains("Oceanian") || tags.contains("Oceanian") || tags.contains("Australian") || (lat >= -50 && lat <= 0 && lon >= 110 && lon <= 180)
            case "Antarctica":
                return cat.contains("Antarctic") || tags.contains("Antarctica") || lat <= -60
            default:
                return true
            }
        }
    }
    
    private func markerColor(for recipe: RecipeModel) -> Color {
        let cat = recipe.category?.name ?? ""
        let tags = recipe.tags
        if cat.contains("African") || cat.contains("Ethiopian") || tags.contains("African") {
            return .orange
        } else if cat.contains("Asian") || tags.contains("Asian") {
            return .red
        } else if cat.contains("European") || tags.contains("European") || tags.contains("Italian") || tags.contains("French") {
            return .purple
        } else if cat.contains("North American") || tags.contains("North American") || tags.contains("Mexican") {
            return .blue
        } else if cat.contains("South American") || tags.contains("South American") {
            return .green
        } else if cat.contains("Oceanian") || tags.contains("Oceanian") || tags.contains("Australian") {
            return .teal
        } else if cat.contains("Antarctic") || tags.contains("Antarctica") {
            return .cyan
        }
        return .accentColor
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Main Interactive World Map
                Map(position: $position, selection: $selectedRecipe) {
                    ForEach(filteredGeoRecipes) { recipe in
                        if let coord = recipe.coordinate {
                            Marker(recipe.name, coordinate: coord)
                                .tint(markerColor(for: recipe))
                                .tag(recipe)
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .ignoresSafeArea(edges: .bottom)
                
                // Top Floating Region Selector
                VStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(continents) { continent in
                                regionChip(continent)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .shadow(radius: 4)
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                    
                    // Bottom Card Carousel for Selected / Visible Recipes
                    if let selected = selectedRecipe {
                        recipeCard(selected)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                    } else if !filteredGeoRecipes.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(filteredGeoRecipes) { recipe in
                                    Button {
                                        withAnimation {
                                            selectedRecipe = recipe
                                            if let coord = recipe.coordinate {
                                                position = .region(MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)))
                                            }
                                        }
                                    } label: {
                                        compactRecipeCard(recipe)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("7 Continents Culinary Atlas")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func regionChip(_ continent: ContinentInfo) -> some View {
        let isSelected = selectedRegionFilter == continent.id
        return Button {
            withAnimation(.easeInOut(duration: 0.9)) {
                selectedRegionFilter = continent.id
                position = .region(MKCoordinateRegion(center: continent.center, span: MKCoordinateSpan(latitudeDelta: continent.span, longitudeDelta: continent.span)))
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: continent.icon)
                    .font(.caption2)
                Text(continent.title)
                    .font(.caption.weight(isSelected ? .bold : .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
    
    private func recipeCard(_ recipe: RecipeModel) -> some View {
        NavigationLink {
            RecipeDetailView(recipe: recipe)
        } label: {
            HStack(spacing: 14) {
                if let image = recipe.viewImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 80, height: 80)
                        .overlay {
                            Image(systemName: "fork.knife")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                        }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let location = recipe.locationName {
                        Label(location, systemImage: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 8) {
                        Label("\(recipe.totalTimeMinutes) mins", systemImage: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if let category = recipe.category?.name {
                            Text(category)
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
            .padding(12)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
    }
    
    private func compactRecipeCard(_ recipe: RecipeModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let image = recipe.viewImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 140, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 140, height: 90)
                    .overlay {
                        Image(systemName: "map")
                            .foregroundColor(.secondary)
                    }
            }
            
            Text(recipe.name)
                .font(.caption.weight(.bold))
                .lineLimit(1)
            
            if let location = recipe.locationName {
                Text(location)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 140)
        .padding(8)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 3)
    }
}
