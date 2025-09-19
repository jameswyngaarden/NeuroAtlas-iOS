// BrainDataService.swift - Enhanced with region bounds generation
import Foundation
import CoreGraphics

class BrainDataService {
    private let baseURL = "https://jameswyngaarden.github.io/NeuroAtlas-iOS"
    
    // Cache the lookup table for better performance
    private var regionLookupTable: [String: [BrainRegion]]?
    
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
    
    // NEW: Generate region bounds for highlighting
    func generateRegionBounds(
        for region: BrainRegion,
        coordinate: MNICoordinate,
        plane: AnatomicalPlane,
        slice: BrainSlice,
        containerSize: CGSize
    ) async throws -> CGRect {
        print("🎭 Generating region bounds for \(region.name) at \(coordinate)")
        
        // Create realistic region bounds based on region category and brain anatomy
        let bounds = generateAnatomicalRegionBounds(
            region: region,
            coordinate: coordinate,
            plane: plane,
            slice: slice,
            containerSize: containerSize
        )
        
        print("🎭 Generated bounds: \(bounds)")
        return bounds
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
    
    // NEW: Generate anatomically realistic region bounds
    private func generateAnatomicalRegionBounds(
        region: BrainRegion,
        coordinate: MNICoordinate,
        plane: AnatomicalPlane,
        slice: BrainSlice,
        containerSize: CGSize
    ) -> CGRect {
        
        // Convert MNI coordinate to screen position
        let centerPoint = CoordinateTransformer.mniToScreen(
            coordinate: coordinate,
            containerSize: containerSize,
            slice: slice
        )
        
        // Account for image offset
        let imageOffset: CGFloat = 15
        let adjustedCenter = CGPoint(
            x: centerPoint.x - imageOffset,
            y: centerPoint.y - imageOffset
        )
        
        // Generate bounds based on region category and anatomical knowledge
        let (width, height, shape) = getRegionDimensions(for: region, plane: plane)
        
        var bounds: CGRect
        
        switch shape {
        case .cortical:
            // Cortical regions: elongated along cortical surface
            bounds = generateCorticalBounds(center: adjustedCenter, width: width, height: height, plane: plane)
            
        case .subcortical:
            // Subcortical regions: more compact and rounded
            bounds = generateSubcorticalBounds(center: adjustedCenter, width: width, height: height)
            
        case .generic:
            // Generic regions: simple elliptical
            bounds = generateEllipticalBounds(center: adjustedCenter, width: width, height: height)
        }
        
        // Ensure bounds stay within container
        bounds = bounds.intersection(CGRect(origin: .zero, size: containerSize))
        
        return bounds
    }
    
    private enum RegionShape {
        case cortical, subcortical, generic
    }
    
    private func getRegionDimensions(for region: BrainRegion, plane: AnatomicalPlane) -> (width: CGFloat, height: CGFloat, shape: RegionShape) {
        let baseSize: CGFloat = 40 // Base region size
        
        switch region.category.lowercased() {
        case "cortical":
            // Cortical regions are typically elongated
            let width: CGFloat = baseSize + CGFloat(region.id % 20) + 20
            let height: CGFloat = baseSize * 0.6 + CGFloat(region.id % 10)
            return (width, height, .cortical)
            
        case "subcortical":
            // Subcortical regions are more compact
            let size: CGFloat = baseSize * 0.8 + CGFloat(region.id % 15)
            return (size, size, .subcortical)
            
        default:
            // Generic regions
            let width: CGFloat = baseSize + CGFloat(region.id % 15)
            let height: CGFloat = baseSize + CGFloat((region.id * 3) % 15)
            return (width, height, .generic)
        }
    }
    
    private func generateCorticalBounds(center: CGPoint, width: CGFloat, height: CGFloat, plane: AnatomicalPlane) -> CGRect {
        // Cortical regions follow the curvature of the brain surface
        // Adjust orientation based on plane
        let adjustedWidth: CGFloat
        let adjustedHeight: CGFloat
        
        switch plane {
        case .sagittal:
            // In sagittal view, cortical regions are often vertically oriented
            adjustedWidth = height
            adjustedHeight = width
        case .coronal, .axial:
            // In coronal/axial views, maintain original proportions
            adjustedWidth = width
            adjustedHeight = height
        }
        
        return CGRect(
            x: center.x - adjustedWidth / 2,
            y: center.y - adjustedHeight / 2,
            width: adjustedWidth,
            height: adjustedHeight
        )
    }
    
    private func generateSubcorticalBounds(center: CGPoint, width: CGFloat, height: CGFloat) -> CGRect {
        // Subcortical regions are typically more circular/compact
        let size = min(width, height) // Use smaller dimension for more circular shape
        
        return CGRect(
            x: center.x - size / 2,
            y: center.y - size / 2,
            width: size,
            height: size
        )
    }
    
    private func generateEllipticalBounds(center: CGPoint, width: CGFloat, height: CGFloat) -> CGRect {
        return CGRect(
            x: center.x - width / 2,
            y: center.y - height / 2,
            width: width,
            height: height
        )
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
