//
//  3DModelView.swift
//  booksp
//
//  Created by Takuzen Toh on 1/9/24.
//

import SwiftUI
import RealityKit

struct CubeModelView: View {
    private let sample_3dmodelurl = URL(string: "https://developer.apple.com/augmented-reality/quick-look/models/teapot/teapot.usdz")!
    
    var body: some View {
        RealityView { content in
            let url = URL(fileURLWithPath: "/Users/ttoh/booksp/Packages/RealityKitContent/Sources/RealityKitContent/RealityKitContent.rkassets/solar_panels.usdz")
            let entity = try? Entity.load(contentsOf: url)
        }
    }
}
