//
//  bookspApp.swift
//  booksp
//
//  Created by Takuzen Toh on 7/5/23.
//

import SwiftUI
import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct bookspApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(FirebaseViewModel.shared)
                .environmentObject(FeedModel())
        }
        
        WindowGroup(id: "webview") {
            WebViewWindow()
        }.defaultSize(CGSize(width: 1920, height: 1080))
        
        WindowGroup(id: "CubeModelWindow") {
            CubeModelView()
                }
                .windowStyle(.volumetric)
                .defaultSize(width: 0.6, height: 0.6, depth: 0.6, in: .meters)
        
        ImmersiveSpace(id: "ImmersiveSpace_Progressive") {
            ImmersiveView()
                .environmentObject(FirebaseViewModel.shared)
        }.immersionStyle(selection: .constant(.progressive), in: .progressive)
    }
}
