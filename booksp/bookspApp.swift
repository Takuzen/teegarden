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
        }
        
        WindowGroup(id: "webview") {
            WebViewWindow()
        }.defaultSize(CGSize(width: 1920, height: 1080))
        
        ImmersiveSpace(id: "ImmersiveSpace_Progressive") {
            ImmersiveView()
                .environmentObject(FirebaseViewModel.shared)
        }.immersionStyle(selection: .constant(.progressive), in: .progressive)
    }
}
