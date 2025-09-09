// SliceNavigationView.swift - Navigate through slices in current plane
import SwiftUI

struct SliceNavigationView: View {
    @ObservedObject var viewModel: BrainAtlasViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Slice Position")
                    .font(.headline)
                
                Spacer()
                
                Text("\(viewModel.currentSliceIndex + 1) of \(viewModel.totalSlicesInCurrentPlane)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Button(action: viewModel.previousSlice) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                }
                .disabled(!viewModel.canGoPrevious)
                
                Slider(
                    value: Binding(
                        get: { Double(viewModel.currentSliceIndex) },
                        set: { viewModel.setSliceIndex(Int($0)) }
                    ),
                    in: 0...Double(max(0, viewModel.totalSlicesInCurrentPlane - 1)),
                    step: 1
                )
                
                Button(action: viewModel.nextSlice) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                }
                .disabled(!viewModel.canGoNext)
            }
        }
    }
}