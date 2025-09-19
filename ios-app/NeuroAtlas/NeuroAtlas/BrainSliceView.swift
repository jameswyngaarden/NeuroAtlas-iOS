// BrainSliceView.swift - With offset for navigation widget spacing
import SwiftUI

struct BrainSliceView: View {
    let slice: BrainSlice
    @ObservedObject var viewModel: BrainAtlasViewModel
    let containerSize: CGSize
    
    // ADDED: Offset to create space for navigation widget
    private let imageOffset: CGFloat = 15
    
    var body: some View {
        // Debug: Print the image URL
        let _ = print("🖼️ Loading brain slice: \(slice.imageURL)")
        
        AsyncImage(url: slice.imageURL) { phase in
            switch phase {
            case .success(let image):
                let _ = print("✅ Successfully loaded image: \(slice.imageFilename)")
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .offset(x: -imageOffset, y: -imageOffset) // ADDED: Shift brain image up-left
                    .onTapGesture { location in
                        // ADDED: Compensate for the offset in coordinates
                        let compensatedLocation = CGPoint(
                            x: location.x + imageOffset,
                            y: location.y + imageOffset
                        )
                        let imageFrame = CGRect(origin: .zero, size: containerSize)
                        viewModel.handleTap(at: compensatedLocation, containerSize: imageFrame.size)
                    }
                
            case .failure(let error):
                let _ = print("❌ Failed to load image: \(slice.imageFilename) - Error: \(error)")
                Rectangle()
                    .fill(Color.red.opacity(0.3))
                    .aspectRatio(1.0, contentMode: .fit)
                    .overlay(
                        VStack {
                            Text("Image Failed")
                                .font(.caption)
                                .foregroundColor(.white)
                            Text("\(slice.imageFilename)")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    )
                    .offset(x: -imageOffset, y: -imageOffset) // ADDED: Apply offset to error state too
                
            case .empty:
                let _ = print("🔄 Loading image: \(slice.imageFilename)")
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1.0, contentMode: .fit)
                    .overlay(
                        ProgressView()
                            .tint(.white)
                    )
                    .offset(x: -imageOffset, y: -imageOffset) // ADDED: Apply offset to loading state too
                
            @unknown default:
                let _ = print("❓ Unknown AsyncImage state for: \(slice.imageFilename)")
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1.0, contentMode: .fit)
                    .offset(x: -imageOffset, y: -imageOffset) // ADDED: Apply offset to unknown state
            }
        }
    }
}
