// ControlPanelView.swift - Fixed layout with proper crosshair toggle
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
            
            // FIXED: Crosshair toggle (moved inside main VStack)
            HStack {
                Text("Show Crosshair")
                    .font(.headline)
                
                Spacer()
                
                Toggle("Show Crosshair", isOn: $viewModel.showCrosshair)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
            }
            .padding(.horizontal)
            .padding(.top, 8)
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
