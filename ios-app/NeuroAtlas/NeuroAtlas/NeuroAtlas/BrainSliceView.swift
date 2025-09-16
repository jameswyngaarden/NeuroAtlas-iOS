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
                .onTapGesture { location in
                    viewModel.handleTap(at: location, containerSize: containerSize)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            viewModel.handleDrag(at: value.location, containerSize: containerSize)
                        }
                )
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    ProgressView()
                        .tint(.white)
                )
        }
    }
}
