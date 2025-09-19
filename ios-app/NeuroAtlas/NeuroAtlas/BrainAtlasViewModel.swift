// MARK: - Private Methods
    private func setupCoordinateTransformer() {
        // Setup any coordinate transformation configuration
    }// BrainAtlasViewModel.swift - Updated to start at sagittal +00
import Foundation
import SwiftUI
import Combine

@MainActor
class BrainAtlasViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentPlane: AnatomicalPlane = .sagittal {
        didSet {
            // FIXED: When changing planes, preserve current coordinate and find appropriate slice
            if oldValue != currentPlane {
                goToCurrentCoordinateInNewPlane()
            }
        }
    }
    @Published var currentRegions: [BrainRegion] = []
    @Published var selectedRegion: BrainRegion?
    
    @Published var currentCoordinate = MNICoordinate.zero {
        didSet {
            // FIXED: Update brain regions whenever coordinates change (not just on tap)
            if oldValue != currentCoordinate {
                updateBrainRegions()
            }
        }
    }
    @Published var currentSlice: BrainSlice?
    @Published var currentSliceIndex: Int = 0 {
        didSet {
            updateCurrentSlice()
        }
    }
    
    @Published var showCrosshair = false
    @Published var crosshairPosition = CGPoint.zero
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var coordinateMappings: CoordinateMappings?
    private let dataService = BrainDataService()
    private var cancellables = Set<AnyCancellable>()
    private var lastContainerSize: CGSize = CGSize(width: 400, height: 400) // Default assumption
    
    // MARK: - Computed Properties
    var totalSlicesInCurrentPlane: Int {
        guard let mappings = coordinateMappings else { return 0 }
        return mappings.slices(for: currentPlane).count
    }
    
    var canGoPrevious: Bool {
        currentSliceIndex > 0
    }
    
    var canGoNext: Bool {
        currentSliceIndex < totalSlicesInCurrentPlane - 1
    }
    
    // MARK: - Initialization
    init() {
        setupCoordinateTransformer()
    }
    
    // MARK: - Public Methods
    func loadInitialData() {
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                coordinateMappings = try await dataService.loadCoordinateMappings()
                
                // NEW: Set default to sagittal slice closest to 0
                setDefaultSlicePosition()
                
                updateCurrentSlice()
                updateCurrentCoordinateFromSlice()
            } catch {
                errorMessage = "Failed to load brain data: \(error.localizedDescription)"
                print("❌ Error loading data: \(error)")
            }
            
            isLoading = false
        }
    }
    
    // NEW: Helper method to find sagittal slice closest to 0
    private func setDefaultSlicePosition() {
        guard let mappings = coordinateMappings else { return }
        
        let sagittalSlices = mappings.slices(for: .sagittal)
        
        // Find the slice closest to MNI position 0
        var closestIndex = 0
        var closestDistance = abs(sagittalSlices[0].mniPosition - 0)
        
        for (index, slice) in sagittalSlices.enumerated() {
            let distance = abs(slice.mniPosition - 0)
            if distance < closestDistance {
                closestDistance = distance
                closestIndex = index
            }
        }
        
        currentSliceIndex = closestIndex
        print("🎯 Set default slice to index \(closestIndex) (MNI position: \(sagittalSlices[closestIndex].mniPosition))")
    }
    
    func handleTap(at location: CGPoint, containerSize: CGSize) {
        guard let slice = currentSlice else { return }
        
        // Store container size for future crosshair calculations
        lastContainerSize = containerSize
        
        // Convert tap location to MNI coordinates
        let mniCoordinate = CoordinateTransformer.screenToMNI(
            screenPoint: location,
            containerSize: containerSize,
            slice: slice
        )
        
        updateCoordinate(mniCoordinate)
        updateCrosshair(at: location)
        
        // Note: Brain regions will be updated automatically via currentCoordinate didSet
    }
    
    func handleDrag(at location: CGPoint, containerSize: CGSize) {
        handleTap(at: location, containerSize: containerSize)
    }
    
    func previousSlice() {
        guard canGoPrevious else { return }
        currentSliceIndex -= 1
    }
    
    func nextSlice() {
        guard canGoNext else { return }
        currentSliceIndex += 1
    }
    
    func setSliceIndex(_ index: Int) {
        let clampedIndex = max(0, min(index, totalSlicesInCurrentPlane - 1))
        currentSliceIndex = clampedIndex
    }
    
    func goToCoordinate(_ coordinate: MNICoordinate) {
        // Find the closest slice to this coordinate
        guard let mappings = coordinateMappings else { return }
        
        let slicesForPlane = mappings.slices(for: currentPlane)
        let targetPosition = coordinateValue(for: coordinate, in: currentPlane)
        
        // Find slice with closest MNI position
        var closestIndex = 0
        var closestDistance = abs(slicesForPlane[0].mniPosition - targetPosition)
        
        for (index, slice) in slicesForPlane.enumerated() {
            let distance = abs(slice.mniPosition - targetPosition)
            if distance < closestDistance {
                closestDistance = distance
                closestIndex = index
            }
        }
        
        currentSliceIndex = closestIndex
        updateCurrentCoordinateFromSlice()
        
        // Only update crosshair position if crosshair is enabled
        // Don't force it on
        if showCrosshair {
            // Update crosshair position for the new coordinate
            // This would need the screen position calculation
        }
    }
    
    // FIXED: New method to preserve coordinates when switching planes
    private func goToCurrentCoordinateInNewPlane() {
        guard let mappings = coordinateMappings else {
            updateCurrentSlice()
            return
        }
        
        let preservedCoordinate = currentCoordinate
        let slicesForPlane = mappings.slices(for: currentPlane)
        let targetPosition = coordinateValue(for: preservedCoordinate, in: currentPlane)
        
        // Find slice with closest MNI position to preserve coordinate
        var closestIndex = 0
        var closestDistance = abs(slicesForPlane[0].mniPosition - targetPosition)
        
        for (index, slice) in slicesForPlane.enumerated() {
            let distance = abs(slice.mniPosition - targetPosition)
            if distance < closestDistance {
                closestDistance = distance
                closestIndex = index
            }
        }
        
        currentSliceIndex = closestIndex
        // Restore the preserved coordinate after slice selection
        currentCoordinate = preservedCoordinate
        updateCurrentSlice()
        
        // FIXED: Update crosshair position for the new plane view
        updateCrosshairForNewPlane()
        
        print("🔄 Switched to \(currentPlane.rawValue) plane, preserved coordinate: \(preservedCoordinate)")
    }
    
    // FIXED: Update crosshair position when switching planes
    private func updateCrosshairForNewPlane() {
        guard let slice = currentSlice, showCrosshair else { return }
        
        // Use the last known container size from interactions
        let screenPosition = CoordinateTransformer.mniToScreen(
            coordinate: currentCoordinate,
            containerSize: lastContainerSize,
            slice: slice
        )
        
        // Apply the same offset compensation as in BrainSliceView
        let imageOffset: CGFloat = 15
        crosshairPosition = CGPoint(
            x: screenPosition.x - imageOffset,
            y: screenPosition.y - imageOffset
        )
        
        print("🎯 Updated crosshair position to \(crosshairPosition) for coordinate \(currentCoordinate) in \(currentPlane.rawValue) view")
    }
    
    // FIXED: Separate method for updating brain regions
    private func updateBrainRegions() {
        Task {
            do {
                let regions = try await dataService.lookupRegions(at: currentCoordinate)
                await MainActor.run {
                    currentRegions = regions
                    selectedRegion = regions.first
                }
                
                print("🧠 Updated regions for coordinate \(currentCoordinate): found \(regions.count) regions")
                for region in regions {
                    print("   - \(region.name) (\(region.category))")
                }
            } catch {
                print("❌ Error updating regions: \(error)")
                await MainActor.run {
                    currentRegions = []
                    selectedRegion = nil
                }
            }
        }
    }
    
    private func updateCurrentSlice() {
        guard let mappings = coordinateMappings else { return }
        
        let slicesForPlane = mappings.slices(for: currentPlane)
        guard currentSliceIndex < slicesForPlane.count else { return }
        
        currentSlice = slicesForPlane[currentSliceIndex]
        // Only update coordinate if we're not preserving it from a plane switch
        updateCurrentCoordinateFromSlice()
    }
    
    private func updateCurrentCoordinateFromSlice() {
        guard let slice = currentSlice else { return }
        
        // Update coordinate based on current slice position
        let newCoordinate: MNICoordinate
        switch currentPlane {
        case .sagittal:
            newCoordinate = MNICoordinate(x: slice.mniPosition, y: currentCoordinate.y, z: currentCoordinate.z)
        case .coronal:
            newCoordinate = MNICoordinate(x: currentCoordinate.x, y: slice.mniPosition, z: currentCoordinate.z)
        case .axial:
            newCoordinate = MNICoordinate(x: currentCoordinate.x, y: currentCoordinate.y, z: slice.mniPosition)
        }
        
        // Avoid triggering didSet if coordinate hasn't actually changed
        if newCoordinate != currentCoordinate {
            currentCoordinate = newCoordinate
        }
    }
    
    private func updateCoordinate(_ coordinate: MNICoordinate) {
        currentCoordinate = coordinate
    }
    
    private func updateCrosshair(at position: CGPoint) {
        // ADDED: Compensate crosshair position for the image offset
        let imageOffset: CGFloat = 15
        crosshairPosition = CGPoint(
            x: position.x - imageOffset,
            y: position.y - imageOffset
        )
        // Only show crosshair if the toggle is enabled
        // Don't automatically hide it - let the user control it with the toggle
        if showCrosshair {
            // Keep crosshair visible as long as toggle is on
            // Position is already set above
        }
    }
    
    private func coordinateValue(for coordinate: MNICoordinate, in plane: AnatomicalPlane) -> Int {
        switch plane {
        case .sagittal: return coordinate.x
        case .coronal: return coordinate.y
        case .axial: return coordinate.z
        }
    }
}
