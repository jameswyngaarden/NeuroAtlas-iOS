//
//  ContentView.swift - Main app interface
//  NeuroAtlas
//
//  Created by James Wyngaarden on 9/9/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = BrainAtlasViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with current coordinates
                CoordinateHeaderView(viewModel: viewModel)
                
                // Main brain viewer
                BrainViewerContainer(viewModel: viewModel)
                
                // Bottom controls
                ControlPanelView(viewModel: viewModel)
            }
            .navigationTitle("NeuroAtlas")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        #if os(iOS)
        .navigationViewStyle(StackNavigationViewStyle()) // Force single view on iPhone
        #endif
    }
}

#Preview {
    ContentView()
}
