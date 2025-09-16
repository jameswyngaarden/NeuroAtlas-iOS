// BrainDataService.swift - Handles data loading and API calls
import Foundation

class BrainDataService {
    private let baseURL = "https://your-server.com" // We'll configure this later
    
    func loadCoordinateMappings() async throws -> CoordinateMappings {
        // For now, we'll load from a local JSON file
        // Later we'll switch to loading from your hosted data
        
        guard let url = Bundle.main.url(forResource: "coordinate_mappings", withExtension: "json") else {
            throw BrainDataError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
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