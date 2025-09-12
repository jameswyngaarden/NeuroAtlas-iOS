// BrainSliceView.swift - Interactive brain slice display
import SwiftUI

struct BrainSliceView: View {
    let slice: BrainSlice
    @ObservedObject var viewModel: BrainAtlasViewModel
    let containerSize: CGSize
    
    var body: some View {
        AsyncImage(url: slice.imageURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                // .rotationEffect(.degrees(180))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .onTapGesture { location in
                    // Use the image's actual frame size for coordinate calculation
                    let imageFrame = CGRect(origin: .zero, size: containerSize)
                    viewModel.handleTap(at: location, containerSize: imageFrame.size)
                }
                // ... rest of gesture handling
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .aspectRatio(1.0, contentMode: .fit) // Force consistent aspect ratio
                .overlay(
                    ProgressView()
                        .tint(.white)
                )
        }
    }
}
