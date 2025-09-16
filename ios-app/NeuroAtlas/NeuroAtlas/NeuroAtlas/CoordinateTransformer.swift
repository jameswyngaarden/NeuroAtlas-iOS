// CoordinateTransformer.swift - Handles coordinate conversions
import Foundation
import SwiftUI

struct CoordinateTransformer {
    static func screenToMNI(screenPoint: CGPoint, containerSize: CGSize, slice: BrainSlice) -> MNICoordinate {
        // Account for 180-degree rotation - invert both X and Y
        let flippedX = containerSize.width - screenPoint.x
        let flippedY = containerSize.height - screenPoint.y
        
        // Convert to normalized coordinates (0-1)
        let normalizedX = flippedX / containerSize.width
        let normalizedY = flippedY / containerSize.height
        
        // Rest of the function stays the same...
        let sliceWidth = Double(slice.sliceShape[0])
        let sliceHeight = Double(slice.sliceShape[1])
        
        let pixelX = normalizedX * sliceWidth
        let pixelY = (1.0 - normalizedY) * sliceHeight
        
        let bounds = slice.bounds
        let mniX: Int
        let mniY: Int
        let mniZ: Int
        
        switch slice.plane {
        case .sagittal:
            mniX = slice.mniPosition
            mniY = Int(Double(bounds.yMin) + (pixelX / sliceWidth) * Double(bounds.yMax - bounds.yMin))
            mniZ = Int(Double(bounds.zMin) + (pixelY / sliceHeight) * Double(bounds.zMax - bounds.zMin))
            
        case .coronal:
            mniX = Int(Double(bounds.xMin) + (pixelX / sliceWidth) * Double(bounds.xMax - bounds.xMin))
            mniY = slice.mniPosition
            mniZ = Int(Double(bounds.zMin) + (pixelY / sliceHeight) * Double(bounds.zMax - bounds.zMin))
            
        case .axial:
            mniX = Int(Double(bounds.xMin) + (pixelX / sliceWidth) * Double(bounds.xMax - bounds.xMin))
            mniY = Int(Double(bounds.yMin) + (pixelY / sliceHeight) * Double(bounds.yMax - bounds.yMin))
            mniZ = slice.mniPosition
        }
        
        return MNICoordinate(x: mniX, y: mniY, z: mniZ)
    }
    
    static func mniToScreen(coordinate: MNICoordinate, containerSize: CGSize, slice: BrainSlice) -> CGPoint {
        // Reverse of screenToMNI - convert MNI coordinates back to screen position
        let bounds = slice.bounds
        let sliceWidth = Double(slice.sliceShape[0])
        let sliceHeight = Double(slice.sliceShape[1])
        
        let pixelX: Double
        let pixelY: Double
        
        switch slice.plane {
        case .sagittal:
            pixelX = (Double(coordinate.y - bounds.yMin) / Double(bounds.yMax - bounds.yMin)) * sliceWidth
            pixelY = (Double(coordinate.z - bounds.zMin) / Double(bounds.zMax - bounds.zMin)) * sliceHeight
            
        case .coronal:
            pixelX = (Double(coordinate.x - bounds.xMin) / Double(bounds.xMax - bounds.xMin)) * sliceWidth
            pixelY = (Double(coordinate.z - bounds.zMin) / Double(bounds.zMax - bounds.zMin)) * sliceHeight
            
        case .axial:
            pixelX = (Double(coordinate.x - bounds.xMin) / Double(bounds.xMax - bounds.xMin)) * sliceWidth
            pixelY = (Double(coordinate.y - bounds.yMin) / Double(bounds.yMax - bounds.yMin)) * sliceHeight
        }
        
        // Convert to normalized coordinates
        let normalizedX = pixelX / sliceWidth
        let normalizedY = 1.0 - (pixelY / sliceHeight) // Flip Y axis
        
        // Convert to screen coordinates
        let screenX = normalizedX * containerSize.width
        let screenY = normalizedY * containerSize.height
        
        return CGPoint(x: screenX, y: screenY)
    }
}
