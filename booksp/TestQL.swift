//
//  TestQL.swift
//  booksp
//
//  Created by Takuzen Toh on 1/17/24.
//

import UIKit
import SwiftUI
import QuickLook

struct TestQL: View {
    @State private var isPreviewing: Bool = false

    var body: some View {
        VStack {
            Button("Preview USDZ") {
                isPreviewing = true
            }
            .sheet(isPresented: $isPreviewing) {
                USDZQLPreview(url: URL(string: "https://developer.apple.com/augmented-reality/quick-look/models/teapot/teapot.usdz")!)
            }
        }
    }
}

/*
struct USDZQLPreview: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let previewController = QLPreviewController()
        previewController.dataSource = context.coordinator
        return previewController
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        // No need to update
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return Bundle.main.url(forResource: "teapot", withExtension: ".usdz")! as QLPreviewItem
        }
    }
}
*/
