// BrainDataService.swift - Enhanced debugging version
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
        print("DEBUG: Starting to load coordinate mappings...")
        
        guard let url = URL(string: "\(baseURL)/coordinate_mappings.json") else {
            print("DEBUG: Invalid URL")
            throw BrainDataError.invalidData
        }
        
        print("DEBUG: Fetching data from: \(url)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("DEBUG: HTTP Status: \(httpResponse.statusCode)")
            }
            
            let mappings = try JSONDecoder().decode(CoordinateMappings.self, from: data)
            
            // DEBUG: Print first few slices from each plane to understand coordinate system
            print("DEBUG: === COORDINATE SYSTEM ANALYSIS ===")
            print("DEBUG: Sagittal slices (first 5):")
            for (index, slice) in mappings.sagittal.prefix(5).enumerated() {
                print("DEBUG:   [\(index)] MNI: \(slice.mniPosition), File: \(slice.imageFilename)")
            }
            
            print("DEBUG: Coronal slices (first 5):")
            for (index, slice) in mappings.coronal.prefix(5).enumerated() {
                print("DEBUG:   [\(index)] MNI: \(slice.mniPosition), File: \(slice.imageFilename)")
            }
            
            print("DEBUG: Axial slices (first 5):")
            for (index, slice) in mappings.axial.prefix(5).enumerated() {
                print("DEBUG:   [\(index)] MNI: \(slice.mniPosition), File: \(slice.imageFilename)")
            }
            
            return mappings
        } catch {
            print("DEBUG: Error loading coordinate mappings: \(error)")
            throw error
        }
    }
    
    func loadRegionLookupTable() async throws {
        // Load the lookup table once and cache it
        guard regionLookupTable == nil else { return } // Already loaded
        
        print("DEBUG: Loading Harvard-Oxford region lookup table...")
        
        guard let url = URL(string: "\(baseURL)/harvard_oxford_lookup_2mm.json") else {
            throw BrainDataError.invalidData
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("DEBUG: Region lookup HTTP Status: \(httpResponse.statusCode)")
            }
            
            regionLookupTable = try JSONDecoder().decode([String: [BrainRegion]].self, from: data)
            print("DEBUG: Successfully loaded region lookup table with \(regionLookupTable?.count ?? 0) coordinate entries")
        } catch {
            print("DEBUG: Error loading region lookup table: \(error)")
            throw error
        }
    }
    
    func lookupRegions(at coordinate: MNICoordinate) async throws -> [BrainRegion] {
        print("DEBUG: === REGION LOOKUP ===")
        print("DEBUG: Looking up regions at coordinate: \(coordinate)")
        
        // Ensure lookup table is loaded
        try await loadRegionLookupTable()
        
        guard let lookupTable = regionLookupTable else {
            throw BrainDataError.invalidData
        }
        
        // Try exact coordinate first
        let exactKey = "\(coordinate.x),\(coordinate.y),\(coordinate.z)"
        print("DEBUG: Trying exact key: \(exactKey)")
        
        if let exactRegions = lookupTable[exactKey], !exactRegions.isEmpty {
            print("DEBUG: Found exact match with \(exactRegions.count) regions")
            for region in exactRegions {
                print("DEBUG:   - Region \(region.id): \(region.name) (\(region.category))")
            }
            return exactRegions
        }
        
        // Try even coordinates (2mm grid alignment)
        let evenCoord = MNICoordinate(
            x: coordinate.x % 2 == 0 ? coordinate.x : coordinate.x - 1,
            y: coordinate.y % 2 == 0 ? coordinate.y : coordinate.y - 1,
            z: coordinate.z % 2 == 0 ? coordinate.z : coordinate.z - 1
        )
        let evenKey = "\(evenCoord.x),\(evenCoord.y),\(evenCoord.z)"
        print("DEBUG: Trying even coordinate key: \(evenKey)")
        
        if let evenRegions = lookupTable[evenKey], !evenRegions.isEmpty {
            print("DEBUG: Found even coordinate match with \(evenRegions.count) regions")
            for region in evenRegions {
                print("DEBUG:   - Region \(region.id): \(region.name) (\(region.category))")
            }
            return evenRegions
        }
        
        // Try neighborhood search
        let nearbyCoordinates = generateSmartNearbyCoordinates(coordinate)
        print("DEBUG: Trying \(nearbyCoordinates.count) nearby coordinates...")
        
        for nearbyCoord in nearbyCoordinates {
            let key = "\(nearbyCoord.x),\(nearbyCoord.y),\(nearbyCoord.z)"
            if let regions = lookupTable[key], !regions.isEmpty {
                print("DEBUG: Found nearby match at \(key) with \(regions.count) regions")
                for region in regions {
                    print("DEBUG:   - Region \(region.id): \(region.name) (\(region.category))")
                }
                return regions
            }
        }
        
        // Fallback: 2mm grid snapping
        let snappedX = Int(round(Double(coordinate.x) / 2.0)) * 2
        let snappedY = Int(round(Double(coordinate.y) / 2.0)) * 2
        let snappedZ = Int(round(Double(coordinate.z) / 2.0)) * 2
        
        let snappedCoord = MNICoordinate(x: snappedX, y: snappedY, z: snappedZ)
        let coordKey = "\(snappedCoord.x),\(snappedCoord.y),\(snappedCoord.z)"
        
        print("DEBUG: Fallback to 2mm grid: \(coordKey)")
        
        let regions = lookupTable[coordKey] ?? []
        
        if regions.isEmpty {
            let backgroundRegion = BrainRegion(
                id: 0,
                name: "Background / CSF / White Matter",
                category: "background",
                probability: 1.0,
                description: "Area outside labeled cortical/subcortical regions"
            )
            print("DEBUG: Using background region")
            return [backgroundRegion]
        } else {
            print("DEBUG: Found \(regions.count) regions at snapped coordinate")
            for region in regions {
                print("DEBUG:   - Region \(region.id): \(region.name) (\(region.category))")
            }
            return regions
        }
    }
    
    // ENHANCED: Load region mask image with comprehensive debugging
    func loadRegionMask(for region: BrainRegion, slice: BrainSlice) async throws -> UIImage? {
        print("DEBUG: === MASK LOADING ===")
        print("DEBUG: Current slice info:")
        print("DEBUG:   - Plane: \(slice.plane.rawValue)")
        print("DEBUG:   - MNI Position: \(slice.mniPosition)")
        print("DEBUG:   - Image Filename: \(slice.imageFilename)")
        print("DEBUG:   - Description: \(slice.description)")
        
        let cacheKey = "\(region.id)_\(slice.plane.rawValue)_\(slice.imageFilename)"
        
        // Check cache first
        if let cachedImage = await getCachedMaskImage(for: cacheKey) {
            print("DEBUG: Using cached mask for region \(region.name)")
            return cachedImage
        }
        
        let maskURL = slice.regionMaskURL(for: region.id)
        print("DEBUG: Constructed mask URL: \(maskURL)")
        print("DEBUG: Region info:")
        print("DEBUG:   - ID: \(region.id)")
        print("DEBUG:   - Name: \(region.name)")
        print("DEBUG:   - Category: \(region.category)")
        
        // ENHANCED: Try to predict what the filename should be
        print("DEBUG: Expected mask path breakdown:")
        print("DEBUG:   - Base: region_masks/\(slice.plane.rawValue)/region_\(String(format: "%02d", region.id))/")
        print("DEBUG:   - Filename: \(slice.imageFilename)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: maskURL)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("DEBUG: HTTP Response: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 404 {
                    print("DEBUG: 404 - Mask file not found. This could mean:")
                    print("DEBUG:   1. No mask exists for this region in this slice")
                    print("DEBUG:   2. Filename mismatch between brain slice and mask")
                    print("DEBUG:   3. Region ID mismatch")
                    return nil
                }
                
                guard httpResponse.statusCode == 200 else {
                    print("DEBUG: HTTP error \(httpResponse.statusCode) for region \(region.name)")
                    return nil
                }
            }
            
            print("DEBUG: Downloaded \(data.count) bytes")
            
            guard let image = UIImage(data: data) else {
                print("DEBUG: Failed to create UIImage from data")
                return nil
            }
            
            print("DEBUG: Successfully created image:")
            print("DEBUG:   - Size: \(image.size)")
            print("DEBUG:   - Scale: \(image.scale)")
            
            // Cache the image
            await cacheMaskImage(image, for: cacheKey)
            
            return image
            
        } catch {
            print("DEBUG: Network error loading mask: \(error)")
            print("DEBUG: Error details: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Helper methods (unchanged)
    
    private func generateSmartNearbyCoordinates(_ coordinate: MNICoordinate) -> [MNICoordinate] {
        var nearby: [MNICoordinate] = []
        
        let baseCoords = [
            MNICoordinate(x: coordinate.x - 2, y: coordinate.y, z: coordinate.z),
            MNICoordinate(x: coordinate.x + 2, y: coordinate.y, z: coordinate.z),
            MNICoordinate(x: coordinate.x, y: coordinate.y - 2, z: coordinate.z),
            MNICoordinate(x: coordinate.x, y: coordinate.y + 2, z: coordinate.z),
            MNICoordinate(x: coordinate.x, y: coordinate.y, z: coordinate.z - 2),
            MNICoordinate(x: coordinate.x, y: coordinate.y, z: coordinate.z + 2)
        ]
        
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
        print("DEBUG: Cleared region mask cache")
    }
    
    func loadSliceImage(for slice: BrainSlice) async throws -> Data {
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
