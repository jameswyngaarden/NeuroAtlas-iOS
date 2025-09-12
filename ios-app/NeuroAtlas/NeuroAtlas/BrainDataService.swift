// BrainDataService.swift - Handles data loading and API calls
import Foundation

class BrainDataService {
    private let baseURL = "https://jameswyngaarden.github.io/NeuroAtlas-iOS"
    
    func loadCoordinateMappings() async throws -> CoordinateMappings {
        print("🔍 Starting to load coordinate mappings...")
        
        guard let url = URL(string: "\(baseURL)/coordinate_mappings.json") else {
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
    
    func lookupRegions(at coordinate: MNICoordinate) async throws -> [BrainRegion] {
        print("🔍 Looking up regions at coordinate: \(coordinate)")
        
        // Snap to 2mm grid for lookup table compatibility
        let snappedX = Int(round(Double(coordinate.x) / 2.0)) * 2
        let snappedY = Int(round(Double(coordinate.y) / 2.0)) * 2
        let snappedZ = Int(round(Double(coordinate.z) / 2.0)) * 2
        
        let snappedCoord = MNICoordinate(x: snappedX, y: snappedY, z: snappedZ)
        print("📍 Snapped to 2mm grid: \(snappedCoord)")
        
        let coordKey = "\(snappedCoord.x),\(snappedCoord.y),\(snappedCoord.z)"
        
        guard let url = URL(string: "\(baseURL)/harvard_oxford_lookup_2mm.json") else {
            throw BrainDataError.invalidData
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let lookupTable = try JSONDecoder().decode([String: [BrainRegion]].self, from: data)
            
            let regions = lookupTable[coordKey] ?? []
            
            if regions.isEmpty {
                let backgroundRegion = BrainRegion(
                    id: 0,
                    name: "Background / CSF / White Matter",
                    category: "background",
                    probability: 1.0,
                    description: "Area outside labeled cortical/subcortical regions"
                )
                print("📍 Found background region at \(coordKey)")
                return [backgroundRegion]
            } else {
                print("📍 Found \(regions.count) regions at \(coordKey)")
                for region in regions {
                    print("   - \(region.name) (\(region.category))")
                }
                return regions
            }
        } catch {
            print("❌ Error looking up regions: \(error)")
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
