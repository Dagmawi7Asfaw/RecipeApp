import MapKit
import SwiftUI

struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var latitude: Double?
    @Binding var longitude: Double?
    @Binding var locationName: String
    
    @State private var position: MapCameraPosition
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var nameInput: String = ""
    
    @State private var searchQuery: String = ""
    @State private var searchResults: [MKMapItem] = []
    
    init(latitude: Binding<Double?>, longitude: Binding<Double?>, locationName: Binding<String>) {
        self._latitude = latitude
        self._longitude = longitude
        self._locationName = locationName
        
        let initialLat = latitude.wrappedValue ?? 48.8566
        let initialLon = longitude.wrappedValue ?? 2.3522
        let initialCoord = CLLocationCoordinate2D(latitude: initialLat, longitude: initialLon)
        
        self._position = State(initialValue: .region(MKCoordinateRegion(
            center: initialCoord,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )))
        self._selectedCoordinate = State(initialValue: latitude.wrappedValue != nil && longitude.wrappedValue != nil ? initialCoord : nil)
        self._nameInput = State(initialValue: locationName.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Worldwide Search Bar
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search any city, landmark, or market...", text: $searchQuery)
                            .onChange(of: searchQuery) { _, newValue in
                                performSearch(query: newValue)
                            }
                            .autocorrectionDisabled()
                        
                        if !searchQuery.isEmpty {
                            Button {
                                searchQuery = ""
                                searchResults = []
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    // Search Results List Dropdown
                    if !searchResults.isEmpty {
                        List(searchResults, id: \.self) { item in
                            Button {
                                selectSearchResult(item)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name ?? "Unknown Location")
                                        .font(.body.weight(.medium))
                                        .foregroundColor(.primary)
                                    if let subtitle = item.placemark.title {
                                        Text(subtitle)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .frame(maxHeight: 220)
                        .background(.thinMaterial)
                    }
                }
                .background(.regularMaterial)
                
                // Map Display
                MapReader { proxy in
                    Map(position: $position) {
                        if let coord = selectedCoordinate {
                            Marker(nameInput.isEmpty ? "Selected Location" : nameInput, coordinate: coord)
                                .tint(.red)
                        }
                    }
                    .onTapGesture { positionInView in
                        if let coord = proxy.convert(positionInView, from: .local) {
                            selectedCoordinate = coord
                        }
                    }
                }
                .overlay(alignment: .top) {
                    if searchResults.isEmpty {
                        Text("Tap on map or search a location above")
                            .font(.caption)
                            .padding(8)
                            .background(.thinMaterial)
                            .clipShape(Capsule())
                            .padding(.top, 10)
                    }
                }
                
                // Bottom Details & Save Panel
                VStack(spacing: 12) {
                    TextField("Location Name (e.g., Paris, France or Local Market)", text: $nameInput)
                        .textFieldStyle(.roundedBorder)
                    
                    if let coord = selectedCoordinate {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.red)
                            Text(String(format: "Lat: %.4f, Lon: %.4f", coord.latitude, coord.longitude))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    
                    Button {
                        if let coord = selectedCoordinate {
                            latitude = coord.latitude
                            longitude = coord.longitude
                            locationName = nameInput
                        }
                        dismiss()
                    } label: {
                        Text("Save Location")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedCoordinate != nil ? Color.accentColor : Color.gray)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(selectedCoordinate == nil)
                }
                .padding()
                .background(.regularMaterial)
            }
            .navigationTitle("Pick Origin Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func performSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            searchResults = []
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response, error == nil else {
                return
            }
            Task { @MainActor in
                self.searchResults = response.mapItems
            }
        }
    }
    
    private func selectSearchResult(_ item: MKMapItem) {
        let coord = item.placemark.coordinate
        selectedCoordinate = coord
        nameInput = item.name ?? item.placemark.title ?? ""
        
        withAnimation {
            position = .region(MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
        
        searchResults = []
        searchQuery = ""
    }
}
