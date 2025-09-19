// SimpleRegionHighlightView.swift - Better anatomical region rendering
import SwiftUI

struct SimpleRegionHighlightView: View {
    let regionHighlight: RegionHighlight
    let containerSize: CGSize
    
    @State private var animationScale: CGFloat = 0.8
    @State private var animationOpacity: Double = 0.0
    
    var body: some View {
        regionShape
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
    
    @ViewBuilder
    private var regionShape: some View {
        let bounds = regionHighlight.bounds
        let category = regionHighlight.region.category.lowercased()
        
        ZStack {
            switch category {
            case "cortical":
                // Cortical regions: elongated, curved shapes
                CorticalRegionShape(bounds: bounds, plane: regionHighlight.plane)
                    .fill(regionHighlight.color.opacity(0.3))
                
                CorticalRegionShape(bounds: bounds, plane: regionHighlight.plane)
                    .stroke(regionHighlight.color, lineWidth: 2)
                
                CorticalRegionShape(bounds: bounds, plane: regionHighlight.plane)
                    .stroke(regionHighlight.color.opacity(0.6), lineWidth: 4)
                    .blur(radius: 2)
                    
            case "subcortical":
                // Subcortical regions: compact, rounded shapes
                SubcorticalRegionShape(bounds: bounds)
                    .fill(regionHighlight.color.opacity(0.3))
                
                SubcorticalRegionShape(bounds: bounds)
                    .stroke(regionHighlight.color, lineWidth: 2)
                
                SubcorticalRegionShape(bounds: bounds)
                    .stroke(regionHighlight.color.opacity(0.6), lineWidth: 4)
                    .blur(radius: 2)
                    
            default:
                // Generic regions: simple ellipse - apply fill/stroke before position
                Ellipse()
                    .fill(regionHighlight.color.opacity(0.3))
                    .frame(width: bounds.width, height: bounds.height)
                    .position(x: bounds.midX, y: bounds.midY)
                
                Ellipse()
                    .stroke(regionHighlight.color, lineWidth: 2)
                    .frame(width: bounds.width, height: bounds.height)
                    .position(x: bounds.midX, y: bounds.midY)
                
                Ellipse()
                    .stroke(regionHighlight.color.opacity(0.6), lineWidth: 4)
                    .blur(radius: 2)
                    .frame(width: bounds.width, height: bounds.height)
                    .position(x: bounds.midX, y: bounds.midY)
            }
        }
    }
}

// MARK: - Custom Region Shapes

struct CorticalRegionShape: Shape {
    let bounds: CGRect
    let plane: AnatomicalPlane
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Create a curved cortical region shape
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let width = bounds.width
        let height = bounds.height
        
        // Adjust curvature based on anatomical plane
        switch plane {
        case .sagittal:
            // Sagittal: follow cortical curvature
            createSagittalCorticalPath(&path, center: center, width: width, height: height)
            
        case .coronal:
            // Coronal: more vertical orientation
            createCoronalCorticalPath(&path, center: center, width: width, height: height)
            
        case .axial:
            // Axial: horizontal cortical ribbon
            createAxialCorticalPath(&path, center: center, width: width, height: height)
        }
        
        return path
    }
    
    private func createSagittalCorticalPath(_ path: inout Path, center: CGPoint, width: CGFloat, height: CGFloat) {
        // Create a curved cortical shape following brain surface
        let startPoint = CGPoint(x: center.x - width/2, y: center.y - height/4)
        path.move(to: startPoint)
        
        // Top curve
        path.addQuadCurve(
            to: CGPoint(x: center.x + width/2, y: center.y - height/4),
            control: CGPoint(x: center.x, y: center.y - height/2)
        )
        
        // Right side
        path.addLine(to: CGPoint(x: center.x + width/2, y: center.y + height/4))
        
        // Bottom curve
        path.addQuadCurve(
            to: CGPoint(x: center.x - width/2, y: center.y + height/4),
            control: CGPoint(x: center.x, y: center.y + height/2)
        )
        
        path.closeSubpath()
    }
    
    private func createCoronalCorticalPath(_ path: inout Path, center: CGPoint, width: CGFloat, height: CGFloat) {
        // Create a more vertically oriented cortical shape
        let startPoint = CGPoint(x: center.x - width/3, y: center.y - height/2)
        path.move(to: startPoint)
        
        // Create wavy cortical pattern
        let segments = 4
        let segmentHeight = height / CGFloat(segments)
        
        for i in 0..<segments {
            let y = center.y - height/2 + CGFloat(i) * segmentHeight
            let nextY = y + segmentHeight
            let waveOffset = sin(CGFloat(i) * .pi / 2) * width / 6
            
            path.addCurve(
                to: CGPoint(x: center.x + width/3 + waveOffset, y: nextY),
                control1: CGPoint(x: center.x - width/6, y: y + segmentHeight/3),
                control2: CGPoint(x: center.x + width/6, y: y + 2*segmentHeight/3)
            )
        }
        
        // Return path
        for i in (0..<segments).reversed() {
            let y = center.y - height/2 + CGFloat(i+1) * segmentHeight
            let prevY = y - segmentHeight
            let waveOffset = sin(CGFloat(i) * .pi / 2) * width / 6
            
            path.addCurve(
                to: CGPoint(x: center.x - width/3 - waveOffset, y: prevY),
                control1: CGPoint(x: center.x + width/6, y: y - segmentHeight/3),
                control2: CGPoint(x: center.x - width/6, y: y - 2*segmentHeight/3)
            )
        }
        
        path.closeSubpath()
    }
    
    private func createAxialCorticalPath(_ path: inout Path, center: CGPoint, width: CGFloat, height: CGFloat) {
        // Create a horizontally oriented cortical ribbon
        let rect = CGRect(
            x: center.x - width/2,
            y: center.y - height/2,
            width: width,
            height: height
        )
        
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: height/3, height: height/3))
    }
}

struct SubcorticalRegionShape: Shape {
    let bounds: CGRect
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let size = min(bounds.width, bounds.height)
        
        // Create a slightly irregular circular shape for subcortical structures
        let baseRadius = size / 2
        let segments = 12
        
        for i in 0...segments {
            let angle = CGFloat(i) * 2 * .pi / CGFloat(segments)
            
            // Add slight irregularity to make it more organic
            let radiusVariation = 1.0 + 0.1 * sin(angle * 3) // Small variation
            let radius = baseRadius * radiusVariation
            
            let x = center.x + cos(angle) * radius
            let y = center.y + sin(angle) * radius
            let point = CGPoint(x: x, y: y)
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        path.closeSubpath()
        return path
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
