// BrainDataService.swift - Handles data loading and API calls
import Foundation

class BrainDataService {
    private let baseURL = "https://your-server.com" // We'll configure this later
    
    func loadCoordinateMappings() async throws -> CoordinateMappings {
        guard let url = URL(string: "https://jameswyngaarden.github.io/NeuroAtlas-iOS/coordinate_mappings.json") else {
            throw BrainDataError.invalidData
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let mappings = try JSONDecoder().decode(CoordinateMappings.self, from: data)
        
        return mappings
    }
    
    func loadSliceImage(for slice: BrainSlice) async throws -> Data {
        // Load image data from URL
        let (data, _) = try await URLSession.shared.data(from: slice.imageURL)
        return data
    }
}

enum BrainDataError: LocalizedError {
    case fileNotFound
    case invalidData
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Brain data file not found"
        case .invalidData:
            return "Invalid brain data format"
        case .networkError:
            return "Network error loading brain data"
        }
    }
}
