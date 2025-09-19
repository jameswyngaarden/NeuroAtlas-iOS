// ControlPanelView.swift - Enhanced with side-by-side toggles
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
            
            // ENHANCED: Side-by-side toggle controls
            HStack {
                Spacer()
                
                // Crosshair toggle
                VStack(spacing: 4) {
                    Text("Crosshair")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Toggle("Show Crosshair", isOn: $viewModel.showCrosshair)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
                
                Spacer()
                
                // Region highlighting toggle
                VStack(spacing: 4) {
                    Text("Regions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Toggle("Highlight Regions", isOn: $viewModel.showRegionHighlight)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
                
                Spacer()
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
