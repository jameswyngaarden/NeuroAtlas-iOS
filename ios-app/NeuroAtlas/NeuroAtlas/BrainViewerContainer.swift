// BrainViewerContainer.swift - Main brain image viewer
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
                        containerSize: geometry.size
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
            }
        }
        .clipped()
        .onAppear {
            viewModel.loadInitialData()
        }
    }
}