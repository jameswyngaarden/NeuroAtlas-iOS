// CoordinateHeaderView.swift - Displays current MNI coordinates
import SwiftUI

struct CoordinateHeaderView: View {
    @ObservedObject var viewModel: BrainAtlasViewModel
    
    var body: some View {
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
