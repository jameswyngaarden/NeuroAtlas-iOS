// BrainModels.swift - Updated with region mask support
import Foundation
import SwiftUI

// MARK: - Core Data Models

struct MNICoordinate: Codable, Equatable {
    let x: Int
    let y: Int
    let z: Int
    
    static let zero = MNICoordinate(x: 0, y: 0, z: 0)
}

enum AnatomicalPlane: String, CaseIterable, Codable {
    case sagittal = "sagittal"
    case coronal = "coronal"
    case axial = "axial"
    
    var displayName: String {
        switch self {
        case .sagittal: return "Sagittal"
        case .coronal: return "Coronal"
        case .axial: return "Axial"
        }
    }
    
    var coordinateAxis: String {
        switch self {
        case .sagittal: return "X"
        case .coronal: return "Y"
        case .axial: return "Z"
        }
    }
}

struct BrainSlice: Codable, Identifiable {
    let id = UUID()
    let plane: AnatomicalPlane
    let mniPosition: Int
    let sliceShape: [Int]
    let voxelCoordinates: [Int]
    let affineTransform: [[Double]]
    let bounds: CoordinateBounds
    let description: String
    let imageFilename: String
    let imagePath: String
    
    var imageURL: URL {
        URL(string: "https://jameswyngaarden.github.io/NeuroAtlas-Images/slices/\(plane.rawValue)/\(imageFilename)")!
    }
    
    // NEW: URL for region mask overlay
    func regionMaskURL(for regionId: Int) -> URL {
        URL(string: "https://jameswyngaarden.github.io/NeuroAtlas-Images/region_masks/\(plane.rawValue)/region_\(String(format: "%02d", regionId))/\(imageFilename)")!
    }
    
    private enum CodingKeys: String, CodingKey {
        case plane, bounds, description
        case mniPosition = "mni_position"
        case sliceShape = "slice_shape"
        case voxelCoordinates = "voxel_coordinates"
        case affineTransform = "affine_transform"
        case imageFilename = "image_filename"
        case imagePath = "image_path"
    }
}

struct CoordinateBounds: Codable {
    let xMin: Int
    let xMax: Int
    let yMin: Int
    let yMax: Int
    let zMin: Int
    let zMax: Int
    
    private enum CodingKeys: String, CodingKey {
        case xMin = "x_min"
        case xMax = "x_max"
        case yMin = "y_min"
        case yMax = "y_max"
        case zMin = "z_min"
        case zMax = "z_max"
    }
}

// MARK: - Brain Region Models

struct BrainRegion: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let category: String
    let probability: Float?
    let description: String?
    
    // Color for highlighting this region
    var highlightColor: Color {
        switch category.lowercased() {
        case "cortical":
            return .blue.opacity(0.5)
        case "subcortical":
            return .red.opacity(0.5)
        case "white matter":
            return .green.opacity(0.5)
        case "csf":
            return .cyan.opacity(0.5)
        default:
            return .yellow.opacity(0.5)
        }
    }
}

struct RegionLookupResponse: Codable {
    let coordinate: String
    let regions: [BrainRegion]
}

// MARK: - API Response Models

struct CoordinateMappings: Codable {
    let sagittal: [BrainSlice]
    let coronal: [BrainSlice]
    let axial: [BrainSlice]
    
    func slices(for plane: AnatomicalPlane) -> [BrainSlice] {
        switch plane {
        case .sagittal: return sagittal
        case .coronal: return coronal
        case .axial: return axial
        }
    }
}

// UPDATED: Region highlight data structure with actual mask image
struct RegionHighlight {
    let region: BrainRegion
    let coordinate: MNICoordinate
    let plane: AnatomicalPlane
    let maskImage: UIImage // Store the actual transparent PNG
    
    var color: Color {
        region.highlightColor
    }
}
