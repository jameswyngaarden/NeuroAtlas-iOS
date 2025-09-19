// NavigationBrainView.swift - Small reference brain showing current slice position
import SwiftUI

struct NavigationBrainView: View {
    @ObservedObject var viewModel: BrainAtlasViewModel
    let size: CGFloat = 120 // Small fixed size
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black)
                .frame(width: size, height: size)
            
            // Reference brain image
            AsyncImage(url: referenceImageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size - 4, height: size - 4)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size - 4, height: size - 4)
            }
            
            // Slice position indicator line
            if let slice = viewModel.currentSlice {
                SliceIndicatorLine(
                    currentPlane: viewModel.currentPlane,
                    slicePosition: slice.mniPosition,
                    size: size - 4
                )
            }
            
            // Border
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                .frame(width: size, height: size)
        }
    }
    
    // Choose reference image based on current viewing plane
    private var referenceImageURL: URL {
        let baseURL = "https://jameswyngaarden.github.io/NeuroAtlas-iOS"
        
        switch viewModel.currentPlane {
        case .sagittal, .axial:
            // For sagittal and axial views, show coronal reference
            return URL(string: "\(baseURL)/reference_coronal.png")!
        case .coronal:
            // For coronal view, show sagittal reference  
            return URL(string: "\(baseURL)/reference_sagittal.png")!
        }
    }
}

struct SliceIndicatorLine: View {
    let currentPlane: AnatomicalPlane
    let slicePosition: Int
    let size: CGFloat
    
    var body: some View {
        // Calculate line position based on MNI coordinate and brain bounds
        let linePosition = calculateLinePosition()
        
        Path { path in
            switch currentPlane {
            case .sagittal:
                // Vertical line for sagittal slices on coronal reference
                let x = linePosition * size
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size))
                
            case .axial:
                // Horizontal line for axial slices on coronal reference
                let y = (1.0 - linePosition) * size // Flip Y for display
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size, y: y))
                
            case .coronal:
                // Horizontal line for coronal slices on sagittal reference
                let y = (1.0 - linePosition) * size // Flip Y for display
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size, y: y))
            }
        }
        .stroke(Color.red, lineWidth: 2)
        .shadow(color: .black, radius: 1)
    }
    
    private func calculateLinePosition() -> Double {
        // Convert MNI position to normalized position (0-1) within brain bounds
        // These bounds should match your actual brain data
        let brainBounds = BrainBounds()
        
        switch currentPlane {
        case .sagittal:
            // Sagittal slice position mapped to X axis on coronal view
            return Double(slicePosition - brainBounds.xMin) / Double(brainBounds.xMax - brainBounds.xMin)
            
        case .axial:
            // Axial slice position mapped to Z axis on coronal view
            return Double(slicePosition - brainBounds.zMin) / Double(brainBounds.zMax - brainBounds.zMin)
            
        case .coronal:
            // Coronal slice position mapped to Y axis on sagittal view
            return Double(slicePosition - brainBounds.yMin) / Double(brainBounds.yMax - brainBounds.yMin)
        }
    }
}

// Brain coordinate bounds - should match your coordinate_mappings.json
struct BrainBounds {
    let xMin = -90
    let xMax = 90
    let yMin = -126
    let yMax = 90
    let zMin = -72
    let zMax = 108
}