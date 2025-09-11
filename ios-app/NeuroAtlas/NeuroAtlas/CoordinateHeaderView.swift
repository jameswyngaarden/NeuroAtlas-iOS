// CoordinateHeaderView.swift - Displays current MNI coordinates and brain regions
import SwiftUI

struct CoordinateHeaderView: View {
    @ObservedObject var viewModel: BrainAtlasViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            // Coordinate display
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MNI Coordinates")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        CoordinateDisplay(label: "X", value: viewModel.currentCoordinate.x, color: .red)
                        CoordinateDisplay(label: "Y", value: viewModel.currentCoordinate.y, color: .green)
                        CoordinateDisplay(label: "Z", value: viewModel.currentCoordinate.z, color: .blue)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Current Plane")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.currentPlane.rawValue.capitalized)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            
            // Brain region display
            if let region = viewModel.selectedRegion {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Brain Region")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(region.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Text(region.category.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(region.category == "cortical" ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                        .foregroundColor(region.category == "cortical" ? .blue : .green)
                        .cornerRadius(8)
                }
            } else if !viewModel.currentRegions.isEmpty {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Brain Region")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(viewModel.currentRegions.count) regions found")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Text("Multiple")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}

struct CoordinateDisplay: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(color)
            Text("\(value)")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}
