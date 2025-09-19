// RegionHighlightToggle.swift - Toggle button for region highlighting
import SwiftUI

struct RegionHighlightToggle: View {
    @ObservedObject var viewModel: BrainAtlasViewModel
    
    var body: some View {
        Button(action: {
            viewModel.toggleRegionHighlight()
        }) {
            HStack(spacing: 4) {
                Image(systemName: viewModel.showRegionHighlight ? "brain.head.profile.fill" : "brain.head.profile")
                    .font(.caption)
                    .foregroundColor(viewModel.showRegionHighlight ? .white : .primary)
                
                Text("Regions")
                    .font(.caption2)
                    .foregroundColor(viewModel.showRegionHighlight ? .white : .primary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(viewModel.showRegionHighlight ? Color.blue : Color(.systemGray5))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Alternative version with just an icon (more compact)
struct RegionHighlightIconToggle: View {
    @ObservedObject var viewModel: BrainAtlasViewModel
    
    var body: some View {
        Button(action: {
            viewModel.toggleRegionHighlight()
        }) {
            Image(systemName: viewModel.showRegionHighlight ? "brain.head.profile.fill" : "brain.head.profile")
                .font(.caption)
                .foregroundColor(viewModel.showRegionHighlight ? .white : .primary)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(viewModel.showRegionHighlight ? Color.blue : Color(.systemGray5))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Enhanced version with region list
struct RegionHighlightControl: View {
    @ObservedObject var viewModel: BrainAtlasViewModel
    @State private var showRegionList = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Toggle button
            HStack {
                RegionHighlightToggle(viewModel: viewModel)
                
                if !viewModel.currentRegions.isEmpty {
                    Button(action: {
                        showRegionList.toggle()
                    }) {
                        Image(systemName: showRegionList ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Region list (collapsible)
            if showRegionList && !viewModel.currentRegions.isEmpty {
                VStack(spacing: 4) {
                    ForEach(viewModel.currentRegions.prefix(3)) { region in
                        RegionRowButton(
                            region: region,
                            isSelected: viewModel.selectedRegion?.id == region.id,
                            isHighlighted: viewModel.showRegionHighlight && viewModel.selectedRegion?.id == region.id
                        ) {
                            viewModel.selectRegionForHighlight(region)
                        }
                    }
                    
                    if viewModel.currentRegions.count > 3 {
                        Text("+ \(viewModel.currentRegions.count - 3) more")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray6))
                )
                .transition(.asymmetric(
                    insertion: .slide.combined(with: .opacity),
                    removal: .slide.combined(with: .opacity)
                ))
            }
        }
    }
}

struct RegionRowButton: View {
    let region: BrainRegion
    let isSelected: Bool
    let isHighlighted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Circle()
                    .fill(region.highlightColor)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(region.name)
                        .font(.caption2)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    Text(region.category)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isHighlighted {
                    Image(systemName: "eye.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Integration helpers for your existing ControlPanelView

// Simple version to add next to crosshair toggle
struct RegionToggleForControlPanel: View {
    @ObservedObject var viewModel: BrainAtlasViewModel
    
    var body: some View {
        RegionHighlightIconToggle(viewModel: viewModel)
    }
}

// Extended version that can replace or supplement your existing controls
struct ExtendedRegionControls: View {
    @ObservedObject var viewModel: BrainAtlasViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !viewModel.currentRegions.isEmpty {
                Text("Brain Regions")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                RegionHighlightControl(viewModel: viewModel)
            } else {
                // Show just the toggle when no regions are detected
                HStack {
                    RegionHighlightToggle(viewModel: viewModel)
                    Spacer()
                }
            }
        }
    }
}