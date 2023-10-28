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
                .environmentObject(FirebaseViewModel())
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
                .environmentObject(FirebaseViewModel())
        }.immersionStyle(selection: .constant(.full), in: .full)
    }
}
