// CoordinateInputView.swift - Manual coordinate entry
import SwiftUI

struct CoordinateInputView: View {
    @ObservedObject var viewModel: BrainAtlasViewModel
    @State private var showingInput = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { showingInput.toggle() }) {
                HStack {
                    Image(systemName: "location")
                    Text("Enter Coordinates")
                }
                .foregroundColor(.blue)
            }
        }
        .sheet(isPresented: $showingInput) {
            CoordinateInputSheet(viewModel: viewModel, isPresented: $showingInput)
        }
    }
}

struct CoordinateInputSheet: View {
    @ObservedObject var viewModel: BrainAtlasViewModel
    @Binding var isPresented: Bool
    
    @State private var xInput = ""
    @State private var yInput = ""
    @State private var zInput = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Enter MNI Coordinates")
                    .font(.title2)
                    .padding()
                
                VStack(spacing: 16) {
                    CoordinateTextField(label: "X", value: $xInput, color: .red)
                    CoordinateTextField(label: "Y", value: $yInput, color: .green)
                    CoordinateTextField(label: "Z", value: $zInput, color: .blue)
                }
                .padding()
                
                Button("Go to Coordinate") {
                    if let x = Int(xInput), let y = Int(yInput), let z = Int(zInput) {
                        viewModel.goToCoordinate(MNICoordinate(x: x, y: y, z: z))
                        isPresented = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(xInput.isEmpty || yInput.isEmpty || zInput.isEmpty)
                
                Spacer()
            }
            .navigationTitle("Coordinates")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            xInput = String(viewModel.currentCoordinate.x)
            yInput = String(viewModel.currentCoordinate.y)
            zInput = String(viewModel.currentCoordinate.z)
        }
    }
}

struct CoordinateTextField: View {
    let label: String
    @Binding var value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.headline)
                .foregroundColor(color)
                .frame(width: 30)
            
            TextField("0", text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}
