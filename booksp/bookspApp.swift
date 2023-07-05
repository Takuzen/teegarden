//
//  bookspApp.swift
//  booksp
//
//  Created by Takuzen Toh on 7/5/23.
//

import SwiftUI

@main
struct bookspApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }.immersionStyle(selection: .constant(.full), in: .full)
    }
}
