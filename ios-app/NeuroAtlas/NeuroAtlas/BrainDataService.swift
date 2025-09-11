// BrainDataService.swift - Handles data loading and API calls
import Foundation

class BrainDataService {
    private let baseURL = "https://your-server.com" // We'll configure this later
    
    func loadCoordinateMappings() async throws -> CoordinateMappings {
        print("🔍 Starting to load coordinate mappings...")
        
        guard let url = URL(string: "https://jameswyngaarden.github.io/NeuroAtlas-iOS/coordinate_mappings.json") else {
            print("❌ Invalid URL")
            throw BrainDataError.invalidData
        }
        
        print("📡 Fetching data from: \(url)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 HTTP Status: \(httpResponse.statusCode)")
            }
            
            print("📄 Data size: \(data.count) bytes")
            
            let mappings = try JSONDecoder().decode(CoordinateMappings.self, from: data)
            print("✅ Successfully decoded mappings")
            print("📊 Sagittal slices: \(mappings.sagittal.count)")
            print("📊 Coronal slices: \(mappings.coronal.count)")
            print("📊 Axial slices: \(mappings.axial.count)")
            
            return mappings
        } catch {
            print("❌ Error loading coordinate mappings: \(error)")
            throw error
        }
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
