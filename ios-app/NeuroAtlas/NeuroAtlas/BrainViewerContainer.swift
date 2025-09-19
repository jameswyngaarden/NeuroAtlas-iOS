// BrainViewerContainer.swift - Main brain image viewer with navigation widget
import SwiftUI

struct BrainViewerContainer: View {
    @ObservedObject var viewModel: BrainAtlasViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                
                // Brain slice image
                if let currentSlice = viewModel.currentSlice {
                    BrainSliceView(
                        slice: currentSlice,
                        viewModel: viewModel,
                        containerSize: CGSize(width: geometry.size.width, height: geometry.size.width)
                    )
                } else {
                    // Loading state
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        
                        Text("Loading brain data...")
                            .foregroundColor(.white)
                            .padding(.top)
                    }
                }
                
                // Crosshair overlay (shows current coordinate)
                if viewModel.showCrosshair {
                    CrosshairView(position: viewModel.crosshairPosition)
                }
                
                // NEW: Navigation brain widget in bottom right corner
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        NavigationBrainView(viewModel: viewModel)
                            .padding(.trailing, 16)
                            .padding(.bottom, 16)
                    }
                }
                .allowsHitTesting(false) // Prevent navigation widget from blocking main brain interactions
            }
        }
        .aspectRatio(1.0, contentMode: .fit)
        .clipped()
        .onAppear {
            viewModel.loadInitialData()
        }
    }
}
