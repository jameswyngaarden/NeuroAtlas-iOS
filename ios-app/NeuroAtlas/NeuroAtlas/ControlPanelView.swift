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
            
            // Crosshair toggle - MOVED INSIDE THE VSTACK
            HStack {
                Text("Show Crosshair")
                    .font(.headline)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.showCrosshair)
                    .labelsHidden()
            }
            .padding(.horizontal)
        }
        .padding()
        .background(.background)
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 0.5),
            alignment: .top
        )
    }
}
