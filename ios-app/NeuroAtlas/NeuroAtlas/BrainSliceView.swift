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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .aspectRatio(1.0, contentMode: .fit)
                .overlay(
                    ProgressView()
                        .tint(.white)
                )
        }
        // Move the gesture to the entire view, not just the image
        .onTapGesture { location in
            print("🔍 DEBUG: Tap detected at \(location)")
            viewModel.handleTap(at: location, containerSize: containerSize)
        }
        .onDragGesture { location in
            print("🔍 DEBUG: Drag detected at \(location)")
            viewModel.handleDrag(at: location, containerSize: containerSize)
        }
    }
}

// Custom drag gesture modifier
extension View {
    func onDragGesture(perform action: @escaping (CGPoint) -> Void) -> some View {
        self.gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    action(value.location)
                }
        )
    }
}
