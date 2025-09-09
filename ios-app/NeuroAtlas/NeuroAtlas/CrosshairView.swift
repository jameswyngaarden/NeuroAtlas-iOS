// CrosshairView.swift - Coordinate indicator overlay
import SwiftUI

struct CrosshairView: View {
    let position: CGPoint
    
    var body: some View {
        ZStack {
            // Vertical line
            Rectangle()
                .fill(Color.red.opacity(0.8))
                .frame(width: 1, height: 20)
                .position(x: position.x, y: position.y)
            
            // Horizontal line  
            Rectangle()
                .fill(Color.red.opacity(0.8))
                .frame(width: 20, height: 1)
                .position(x: position.x, y: position.y)
            
            // Center dot
            Circle()
                .fill(Color.red)
                .frame(width: 4, height: 4)
                .position(position)
        }
    }
}