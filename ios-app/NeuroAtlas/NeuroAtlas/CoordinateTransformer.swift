// CoordinateTransformer.swift
import Foundation
import SwiftUI

struct CoordinateTransformer {
    static func screenToMNI(screenPoint: CGPoint, containerSize: CGSize, slice: BrainSlice) -> MNICoordinate {
        print("=== COORDINATE TRANSFORM DEBUG ===")
        print("Screen tap: (\(screenPoint.x), \(screenPoint.y))")
        print("Container size: \(containerSize)")
        print("Slice shape: \(slice.sliceShape)")
        print("Slice plane: \(slice.plane)")
        print("Slice MNI position: \(slice.mniPosition)")
        print("Slice bounds: xMin=\(slice.bounds.xMin), xMax=\(slice.bounds.xMax), yMin=\(slice.bounds.yMin), yMax=\(slice.bounds.yMax), zMin=\(slice.bounds.zMin), zMax=\(slice.bounds.zMax)")
        
        // Convert screen coordinates to normalized coordinates (0-1)
        let normalizedX = screenPoint.x / containerSize.width
        let normalizedY = screenPoint.y / containerSize.height
        
        print("Normalized: (\(normalizedX), \(normalizedY))")
        
        // Convert to slice pixel coordinates
        let sliceWidth = Double(slice.sliceShape[0])
        let sliceHeight = Double(slice.sliceShape[1])
        
        let pixelX = normalizedX * sliceWidth
        let pixelY = (1.0 - normalizedY) * sliceHeight // Flip Y axis for image coordinate system
        
        print("Slice dimensions: \(sliceWidth) x \(sliceHeight)")
        print("Pixel coordinates: (\(pixelX), \(pixelY))")
        
        // Convert pixel coordinates to MNI coordinates using bounds
        let bounds = slice.bounds
        
        let mniX: Int
        let mniY: Int
        let mniZ: Int
        
        switch slice.plane {
        case .sagittal:
            mniX = slice.mniPosition
            mniY = Int(Double(bounds.yMin) + (pixelX / sliceWidth) * Double(bounds.yMax - bounds.yMin))
            mniZ = Int(Double(bounds.zMin) + (pixelY / sliceHeight) * Double(bounds.zMax - bounds.zMin))
            print("Sagittal calculation:")
            print("  mniX = \(slice.mniPosition) (fixed)")
            print("  mniY = \(bounds.yMin) + (\(pixelX)/\(sliceWidth)) * \(bounds.yMax - bounds.yMin) = \(mniY)")
            print("  mniZ = \(bounds.zMin) + (\(pixelY)/\(sliceHeight)) * \(bounds.zMax - bounds.zMin) = \(mniZ)")
            
        case .coronal:
            mniX = Int(Double(bounds.xMin) + (pixelX / sliceWidth) * Double(bounds.xMax - bounds.xMin))
            mniY = slice.mniPosition
            mniZ = Int(Double(bounds.zMin) + (pixelY / sliceHeight) * Double(bounds.zMax - bounds.zMin))
            print("Coronal calculation:")
            print("  mniX = \(bounds.xMin) + (\(pixelX)/\(sliceWidth)) * \(bounds.xMax - bounds.xMin) = \(mniX)")
            print("  mniY = \(slice.mniPosition) (fixed)")
            print("  mniZ = \(bounds.zMin) + (\(pixelY)/\(sliceHeight)) * \(bounds.zMax - bounds.zMin) = \(mniZ)")
            
        case .axial:
            mniX = Int(Double(bounds.xMin) + (pixelX / sliceWidth) * Double(bounds.xMax - bounds.xMin))
            mniY = Int(Double(bounds.yMin) + (pixelY / sliceHeight) * Double(bounds.yMax - bounds.yMin))
            mniZ = slice.mniPosition
            print("Axial calculation:")
            print("  mniX = \(bounds.xMin) + (\(pixelX)/\(sliceWidth)) * \(bounds.xMax - bounds.xMin) = \(mniX)")
            print("  mniY = \(bounds.yMin) + (\(pixelY)/\(sliceHeight)) * \(bounds.yMax - bounds.yMin) = \(mniY)")
            print("  mniZ = \(slice.mniPosition) (fixed)")
        }
        
        let result = MNICoordinate(x: mniX, y: mniY, z: mniZ)
        print("Final MNI: \(result)")
        print("=== END DEBUG ===")
        
        return result
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
        let normalizedY = 1.0 - (pixelY / sliceHeight) // Flip Y axis back
        
        // Convert to screen coordinates
        let screenX = normalizedX * containerSize.width
        let screenY = normalizedY * containerSize.height
        
        return CGPoint(x: screenX, y: screenY)
    }
}
