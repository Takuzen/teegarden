//
//  3DModelView.swift
//  booksp
//
//  Created by Takuzen Toh on 1/9/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct CubeModelView: View {
    private let sample_3dmodelurl = URL(string: "https://developer.apple.com/augmented-reality/quick-look/models/teapot/teapot.usdz")!
    
    /// The sun entity that the view creates and stores for later updates.
    @State private var sample_model: Entity?
    
    var body: some View {
        RealityView { content in
            guard let sample_model = await RealityKitContent.entity(named: "solar_panels") else {
                return
            }
            
            content.add(sample_model)
            self.sample_model = sample_model
        }
    }
}
            /*
             RealityView { content in
             let url = URL(fileURLWithPath: "/Users/ttoh/booksp/Packages/RealityKitContent/Sources/RealityKitContent/RealityKitContent.rkassets/solar_panels.usdz")
             let entity = try? Entity.load(contentsOf: url)
             }
             */
