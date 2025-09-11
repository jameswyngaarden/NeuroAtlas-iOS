// BrainModels.swift - Core data structures
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
        URL(string: "https://jameswyngaarden.github.io/NeuroAtlas-iOS/slices/\(plane.rawValue)/\(imageFilename)")!
    }
    
    private enum CodingKeys: String, CodingKey {
        case plane, sliceShape, voxelCoordinates, affineTransform, bounds, description, imageFilename, imagePath
        case mniPosition = "mni_position"
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

struct BrainRegion: Codable, Identifiable {
    let id: Int
    let name: String
    let category: String
    let probability: Float?
    let description: String?
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
