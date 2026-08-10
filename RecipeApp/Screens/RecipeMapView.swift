import MapKit
import SwiftUI

struct RecipeMapView: View {
    let recipe: RecipeModel
    
    @State private var position: MapCameraPosition = .automatic
    
    var body: some View {
        if let coordinate = recipe.coordinate {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "map.fill")
                        .foregroundColor(.accentColor)
                    Text("Origin / Market Location")
                        .font(.headline)
                    Spacer()
                    if let locationName = recipe.locationName, !locationName.isEmpty {
                        Text(locationName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Map(position: $position) {
                    Marker(recipe.locationName ?? recipe.name, coordinate: coordinate)
                        .tint(.red)
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 2)
                .onAppear {
                    position = .region(MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    ))
                }
            }
            .padding(.vertical, 4)
        }
    }
}
