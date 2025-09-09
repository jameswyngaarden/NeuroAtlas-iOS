// ControlPanelView.swift - Bottom controls for plane selection and navigation
import SwiftUI

struct ControlPanelView: View {
    @ObservedObject var viewModel: BrainAtlasViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Plane selector
            PlaneSelector(viewModel: viewModel)
            
            // Slice navigation
            SliceNavigationView(viewModel: viewModel)
            
            // Coordinate input
            CoordinateInputView(viewModel: viewModel)
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5),
            alignment: .top
        )
    }
}