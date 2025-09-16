// BrainAtlasViewModel.swift - Main view model managing app state
import Foundation
import SwiftUI
import Combine

@MainActor
class BrainAtlasViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentPlane: AnatomicalPlane = .sagittal {
        didSet {
            updateCurrentSlice()
        }
    }
    @Published var currentRegions: [BrainRegion] = []
    @Published var selectedRegion: BrainRegion?
    
    @Published var currentCoordinate = MNICoordinate.zero
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
                updateCurrentSlice()
                updateCurrentCoordinate()
                
                // DEBUG: Try initial region lookup
                print("🧠 DEBUG: App loaded, attempting initial region lookup at \(currentCoordinate)")
                await performRegionLookup(at: currentCoordinate)
                
            } catch {
                errorMessage = "Failed to load brain data: \(error.localizedDescription)"
                print("❌ Error loading data: \(error)")
            }
            
            isLoading = false
        }
    }
    
    func handleTap(at location: CGPoint, containerSize: CGSize) {
        guard let slice = currentSlice else { return }
        
        // Convert tap location to MNI coordinates
        let mniCoordinate = CoordinateTransformer.screenToMNI(
            screenPoint: location,
            containerSize: containerSize,
            slice: slice
        )
        
        updateCoordinate(mniCoordinate)
        updateCrosshair(at: location)
        
        // Look up brain regions at this coordinate
        Task {
            do {
                let regions = try await dataService.lookupRegions(at: mniCoordinate)
                currentRegions = regions
                selectedRegion = regions.first
                
                print("Found \(regions.count) regions at \(mniCoordinate)")
                for region in regions {
                    print("   - \(region.name) (\(region.category))")
                }
            } catch {
                print("Error looking up regions: \(error)")
                currentRegions = []
                selectedRegion = nil
            }
        }
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
        print("🧠 DEBUG: goToCoordinate called with: \(coordinate)")
        
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
        updateCurrentCoordinate()
        
        // Update crosshair to show the coordinate
        showCrosshair = true
        
        // Look up regions at the new coordinate
        Task {
            await performRegionLookup(at: coordinate)
        }
    }
    
    // MARK: - Private Methods
    private func setupCoordinateTransformer() {
        // Setup any coordinate transformation configuration
    }
    
    private func updateCurrentSlice() {
        guard let mappings = coordinateMappings else { return }
        
        let slicesForPlane = mappings.slices(for: currentPlane)
        guard currentSliceIndex < slicesForPlane.count else { return }
        
        currentSlice = slicesForPlane[currentSliceIndex]
        updateCurrentCoordinate()
    }
    
    private func updateCurrentCoordinate() {
        guard let slice = currentSlice else { return }
        
        let oldCoordinate = currentCoordinate
        
        // Update coordinate based on current slice position
        switch currentPlane {
        case .sagittal:
            currentCoordinate = MNICoordinate(x: slice.mniPosition, y: currentCoordinate.y, z: currentCoordinate.z)
        case .coronal:
            currentCoordinate = MNICoordinate(x: currentCoordinate.x, y: slice.mniPosition, z: currentCoordinate.z)
        case .axial:
            currentCoordinate = MNICoordinate(x: currentCoordinate.x, y: currentCoordinate.y, z: slice.mniPosition)
        }
        
        print("🧠 DEBUG: updateCurrentCoordinate from \(oldCoordinate) to \(currentCoordinate)")
    }
    
    private func updateCoordinate(_ coordinate: MNICoordinate) {
        print("🧠 DEBUG: updateCoordinate to \(coordinate)")
        currentCoordinate = coordinate
    }
    
    private func updateCrosshair(at position: CGPoint) {
        print("🧠 DEBUG: updateCrosshair at position: \(position)")
        crosshairPosition = position
        showCrosshair = true
        
        // Hide crosshair after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            print("🧠 DEBUG: Auto-hiding crosshair")
            self?.showCrosshair = false
        }
    }
    
    private func coordinateValue(for coordinate: MNICoordinate, in plane: AnatomicalPlane) -> Int {
        switch plane {
        case .sagittal: return coordinate.x
        case .coronal: return coordinate.y
        case .axial: return coordinate.z
        }
    }
    
    // MARK: - Region Lookup Methods
    private func performRegionLookup(at coordinate: MNICoordinate) async {
        print("🧠 DEBUG: Starting region lookup at \(coordinate)")
        
        do {
            let regions = try await dataService.lookupRegions(at: coordinate)
            
            print("🧠 DEBUG: Successfully found \(regions.count) regions")
            for (index, region) in regions.enumerated() {
                print("🧠 DEBUG: Region \(index + 1): \(region.name) (\(region.category))")
            }
            
            // Ensure we're on the main thread for UI updates
            await MainActor.run {
                self.currentRegions = regions
                self.selectedRegion = regions.first
                print("🧠 DEBUG: Updated UI - currentRegions.count: \(self.currentRegions.count)")
                print("🧠 DEBUG: Updated UI - selectedRegion: \(self.selectedRegion?.name ?? "nil")")
            }
            
        } catch {
            print("❌ DEBUG: Error looking up regions: \(error)")
            await MainActor.run {
                self.currentRegions = []
                self.selectedRegion = nil
            }
        }
    }
}
