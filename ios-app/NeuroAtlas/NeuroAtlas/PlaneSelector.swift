// PlaneSelector.swift - Anatomical plane selection
import SwiftUI

struct PlaneSelector: View {
    @ObservedObject var viewModel: BrainAtlasViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Anatomical Plane")
                .font(.headline)
            
            Picker("Plane", selection: $viewModel.currentPlane) {
                ForEach(AnatomicalPlane.allCases, id: \.self) { plane in
                    Text(plane.displayName).tag(plane)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}
