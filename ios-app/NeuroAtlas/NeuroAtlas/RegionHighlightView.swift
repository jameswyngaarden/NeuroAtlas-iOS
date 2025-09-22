// RegionHighlightView.swift - Simple display of actual region mask images
import SwiftUI

struct RegionHighlightView: View {
    let regionHighlight: RegionHighlight
    
    @State private var animationScale: CGFloat = 0.8
    @State private var animationOpacity: Double = 0.0
    
    var body: some View {
        Image(uiImage: regionHighlight.maskImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scaleEffect(animationScale)
            .opacity(animationOpacity)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    animationScale = 1.0
                    animationOpacity = 1.0
                }
            }
            .onChange(of: regionHighlight.region.id) { _ in
                // Animate when region changes
                animationScale = 0.9
                animationOpacity = 0.7
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    animationScale = 1.0
                    animationOpacity = 1.0
                }
            }
    }
}

// MARK: - Region Info Tooltip
struct RegionInfoTooltip: View {
    let region: BrainRegion
    let coordinate: MNICoordinate
    @Binding var isVisible: Bool
    
    var body: some View {
        if isVisible {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(region.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button("×") {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isVisible = false
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Text(region.category.capitalized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(region.highlightColor.opacity(0.3))
                    .cornerRadius(4)
                
                Text("(\(coordinate.x), \(coordinate.y), \(coordinate.z))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if let probability = region.probability {
                    Text("\(String(format: "%.1f%%", probability * 100))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if let description = region.description {
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.regularMaterial)
                    .shadow(radius: 4)
            )
            .frame(maxWidth: 200)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.8).combined(with: .opacity),
                removal: .scale(scale: 1.1).combined(with: .opacity)
            ))
        }
    }
}
