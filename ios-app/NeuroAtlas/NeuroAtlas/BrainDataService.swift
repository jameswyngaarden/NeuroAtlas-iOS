// BrainDataService.swift - Updated with region mask loading
import Foundation
import UIKit

class BrainDataService {
    private let baseURL = "https://jameswyngaarden.github.io/NeuroAtlas-iOS"
    
    // Cache the lookup table for better performance
    private var regionLookupTable: [String: [BrainRegion]]?
    
    // Cache for region mask images
    private var maskImageCache: [String: UIImage] = [:]
    private let cacheQueue = DispatchQueue(label: "mask.cache", attributes: .concurrent)
    
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
    
    func loadRegionLookupTable() async throws {
        // Load the lookup table once and cache it
        guard regionLookupTable == nil else { return } // Already loaded
        
        print("🔍 Loading Harvard-Oxford region lookup table...")
        
        guard let url = URL(string: "\(baseURL)/harvard_oxford_lookup_2mm.json") else {
            throw BrainDataError.invalidData
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 Region lookup HTTP Status: \(httpResponse.statusCode)")
            }
            
            print("📄 Region lookup data size: \(data.count) bytes")
            
            regionLookupTable = try JSONDecoder().decode([String: [BrainRegion]].self, from: data)
            print("✅ Successfully loaded region lookup table with \(regionLookupTable?.count ?? 0) coordinate entries")
        } catch {
            print("❌ Error loading region lookup table: \(error)")
            throw error
        }
    }
    
    func lookupRegions(at coordinate: MNICoordinate) async throws -> [BrainRegion] {
        print("🔍 Looking up regions at coordinate: \(coordinate)")
        
        // Ensure lookup table is loaded
        try await loadRegionLookupTable()
        
        guard let lookupTable = regionLookupTable else {
            throw BrainDataError.invalidData
        }
        
        // IMPROVED: Smart lookup strategy for better precision
        // 1. Try exact coordinate first
        let exactKey = "\(coordinate.x),\(coordinate.y),\(coordinate.z)"
        
        if let exactRegions = lookupTable[exactKey], !exactRegions.isEmpty {
            print("🔍 Found exact match at \(exactKey)")
            return exactRegions
        }
        
        // 2. Try even coordinates first (since atlas is 2mm resolution)
        let evenCoord = MNICoordinate(
            x: coordinate.x % 2 == 0 ? coordinate.x : coordinate.x - 1,
            y: coordinate.y % 2 == 0 ? coordinate.y : coordinate.y - 1,
            z: coordinate.z % 2 == 0 ? coordinate.z : coordinate.z - 1
        )
        let evenKey = "\(evenCoord.x),\(evenCoord.y),\(evenCoord.z)"
        
        if let evenRegions = lookupTable[evenKey], !evenRegions.isEmpty {
            print("🔍 Found even coordinate match at \(evenKey) for original \(exactKey)")
            return evenRegions
        }
        
        // 3. Try small neighborhood search (±2mm)
        let nearbyCoordinates = generateSmartNearbyCoordinates(coordinate)
        for nearbyCoord in nearbyCoordinates {
            let key = "\(nearbyCoord.x),\(nearbyCoord.y),\(nearbyCoord.z)"
            if let regions = lookupTable[key], !regions.isEmpty {
                print("🔍 Found nearby match at \(key) for original \(exactKey)")
                return regions
            }
        }
        
        // 4. Fallback: traditional 2mm grid snapping
        let snappedX = Int(round(Double(coordinate.x) / 2.0)) * 2
        let snappedY = Int(round(Double(coordinate.y) / 2.0)) * 2
        let snappedZ = Int(round(Double(coordinate.z) / 2.0)) * 2
        
        let snappedCoord = MNICoordinate(x: snappedX, y: snappedY, z: snappedZ)
        let coordKey = "\(snappedCoord.x),\(snappedCoord.y),\(snappedCoord.z)"
        
        print("🔍 Fallback: snapped to 2mm grid: \(snappedCoord)")
        
        let regions = lookupTable[coordKey] ?? []
        
        if regions.isEmpty {
            let backgroundRegion = BrainRegion(
                id: 0,
                name: "Background / CSF / White Matter",
                category: "background",
                probability: 1.0,
                description: "Area outside labeled cortical/subcortical regions"
            )
            print("🔍 Found background region at \(coordKey)")
            return [backgroundRegion]
        } else {
            print("🔍 Found \(regions.count) regions at \(coordKey)")
            for region in regions {
                print("   - \(region.name) (\(region.category))")
            }
            return regions
        }
    }
    
    // NEW: Load region mask image
    func loadRegionMask(for region: BrainRegion, slice: BrainSlice) async throws -> UIImage? {
        let cacheKey = "\(region.id)_\(slice.plane.rawValue)_\(slice.imageFilename)"
        
        // Check cache first
        if let cachedImage = await getCachedMaskImage(for: cacheKey) {
            print("💾 Using cached mask for region \(region.name)")
            return cachedImage
        }
        
        let maskURL = slice.regionMaskURL(for: region.id)
        print("🔍 Attempting to load mask from: \(maskURL)")
        print("🔍 Region ID: \(region.id), Region Name: \(region.name)")
        print("🔍 Slice filename: \(slice.imageFilename)")
        print("🔍 Plane: \(slice.plane.rawValue)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: maskURL)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP Response: \(httpResponse.statusCode)")
                
                guard httpResponse.statusCode == 200 else {
                    print("⚠️ Region mask not found (HTTP \(httpResponse.statusCode)) for region \(region.name) at \(maskURL)")
                    return nil
                }
            }
            
            print("📄 Mask data size: \(data.count) bytes")
            
            guard let image = UIImage(data: data) else {
                print("❌ Could not create image from mask data for region \(region.name)")
                return nil
            }
            
            print("✅ Successfully loaded mask for region \(region.name) - Image size: \(image.size)")
            
            // Cache the image
            await cacheMaskImage(image, for: cacheKey)
            
            return image
            
        } catch {
            print("❌ Error loading region mask for \(region.name): \(error)")
            print("❌ Full error details: \(error.localizedDescription)")
            return nil
        }
    }
    
    // IMPROVED: Smart nearby coordinate generation for atlas lookup
    private func generateSmartNearbyCoordinates(_ coordinate: MNICoordinate) -> [MNICoordinate] {
        var nearby: [MNICoordinate] = []
        
        // Priority order: check 2mm grid points first (most likely to have data)
        let baseCoords = [
            MNICoordinate(x: coordinate.x - 2, y: coordinate.y, z: coordinate.z),
            MNICoordinate(x: coordinate.x + 2, y: coordinate.y, z: coordinate.z),
            MNICoordinate(x: coordinate.x, y: coordinate.y - 2, z: coordinate.z),
            MNICoordinate(x: coordinate.x, y: coordinate.y + 2, z: coordinate.z),
            MNICoordinate(x: coordinate.x, y: coordinate.y, z: coordinate.z - 2),
            MNICoordinate(x: coordinate.x, y: coordinate.y, z: coordinate.z + 2)
        ]
        
        // Add diagonal 2mm neighbors
        let diagonalCoords = [
            MNICoordinate(x: coordinate.x - 2, y: coordinate.y - 2, z: coordinate.z),
            MNICoordinate(x: coordinate.x + 2, y: coordinate.y + 2, z: coordinate.z),
            MNICoordinate(x: coordinate.x - 2, y: coordinate.y, z: coordinate.z - 2),
            MNICoordinate(x: coordinate.x + 2, y: coordinate.y, z: coordinate.z + 2),
            MNICoordinate(x: coordinate.x, y: coordinate.y - 2, z: coordinate.z - 2),
            MNICoordinate(x: coordinate.x, y: coordinate.y + 2, z: coordinate.z + 2)
        ]
        
        nearby.append(contentsOf: baseCoords)
        nearby.append(contentsOf: diagonalCoords)
        
        return nearby
    }
    
    // MARK: - Cache management
    
    private func getCachedMaskImage(for key: String) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            cacheQueue.async {
                continuation.resume(returning: self.maskImageCache[key])
            }
        }
    }
    
    private func cacheMaskImage(_ image: UIImage, for key: String) async {
        await withCheckedContinuation { continuation in
            cacheQueue.async(flags: .barrier) {
                self.maskImageCache[key] = image
                continuation.resume()
            }
        }
    }
    
    func clearMaskCache() {
        cacheQueue.async(flags: .barrier) {
            self.maskImageCache.removeAll()
        }
        print("🧹 Cleared region mask cache")
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
