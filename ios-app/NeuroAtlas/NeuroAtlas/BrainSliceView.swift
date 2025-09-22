// BrainSliceView.swift - Updated with actual region mask overlay
import SwiftUI

struct BrainSliceView: View {
    let slice: BrainSlice
    @ObservedObject var viewModel: BrainAtlasViewModel
    let containerSize: CGSize
    
    // ADDED: Offset to create space for navigation widget
    private let imageOffset: CGFloat = 15
    
    @State private var showRegionTooltip = false
    
    var body: some View {
        // Debug: Print the image URL
        let _ = print("Loading brain slice: \(slice.imageURL)")
        
        ZStack {
            AsyncImage(url: slice.imageURL) { phase in
                switch phase {
                case .success(let image):
                    let _ = print("Successfully loaded image: \(slice.imageFilename)")
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .offset(x: -imageOffset, y: -imageOffset) // ADDED: Shift brain image up-left
                        .onTapGesture { location in
                            handleTap(at: location)
                        }
                        .gesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .onEnded { _ in
                                    showRegionTooltip = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        showRegionTooltip = false
                                    }
                                }
                        )
                    
                case .failure(let error):
                    let _ = print("Failed to load image: \(slice.imageFilename) - Error: \(error)")
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
                    let _ = print("Loading image: \(slice.imageFilename)")
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            ProgressView()
                                .tint(.white)
                        )
                        .offset(x: -imageOffset, y: -imageOffset) // ADDED: Apply offset to loading state too
                    
                @unknown default:
                    let _ = print("Unknown AsyncImage state for: \(slice.imageFilename)")
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(1.0, contentMode: .fit)
                        .offset(x: -imageOffset, y: -imageOffset) // ADDED: Apply offset to unknown state
                }
            }
            
            // NEW: Region highlight overlay using actual mask image
            if viewModel.showRegionHighlight,
               let regionHighlight = viewModel.currentRegionHighlight {
                RegionHighlightView(regionHighlight: regionHighlight)
                    .offset(x: -imageOffset, y: -imageOffset) // Apply same offset as brain image
                    .allowsHitTesting(false) // Allow taps to pass through to the brain image
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 1.1).combined(with: .opacity)
                    ))
            }
            
            // Crosshair overlay (using your existing CrosshairView)
            if viewModel.showCrosshair {
                CrosshairView(position: viewModel.crosshairPosition)
                    .allowsHitTesting(false)
            }
            
            // NEW: Region info tooltip
            if showRegionTooltip,
               let selectedRegion = viewModel.selectedRegion {
                VStack {
                    HStack {
                        Spacer()
                        RegionInfoTooltip(
                            region: selectedRegion,
                            coordinate: viewModel.currentCoordinate,
                            isVisible: $showRegionTooltip
                        )
                        .padding(.trailing, 20)
                    }
                    Spacer()
                }
                .allowsHitTesting(true)
                .padding(.top, 60)
            }
        }
    }
    
    private func handleTap(at location: CGPoint) {
        // ADDED: Compensate for the offset in coordinates
        let compensatedLocation = CGPoint(
            x: location.x + imageOffset,
            y: location.y + imageOffset
        )
        let imageFrame = CGRect(origin: .zero, size: containerSize)
        viewModel.handleTap(at: compensatedLocation, containerSize: imageFrame.size)
        
        // Add haptic feedback
        if #available(iOS 13.0, *) {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }
}
