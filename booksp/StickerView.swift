//
//  StickerView.swift
//  Day28
//
//  Created by Takuzen Toh on 3/17/24.
//

import SwiftUI

struct StickerView: View, Identifiable {
    
    @State private var stickerText = ""

    var viewModel = ViewModel()
    
    var id = UUID()

    var body: some View {
        viewToSnapshot()
    }

    func viewToSnapshot() -> some View {
        VStack {
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.yellow.opacity(0.6))
                    .overlay(
                        VStack {
                            TextEditor(text: $stickerText)
                            /*
                            Text("X: \(geometry.frame(in: .global).origin.x) Y: \(geometry.frame(in: .global).origin.y) width: \(geometry.frame(in: .global).width) height: \(geometry.frame(in: .global).height)")
                                .foregroundColor(.white)
                             */
                        }
                    )
            }
        }
        .frame(width: targetSize.width, height: targetSize.height)
    }

    @MainActor
    func generateSnapshot() async {
        let renderer = ImageRenderer(content: viewToSnapshot())
        if let image = renderer.uiImage {
            viewModel.targetSnapshot = image
        }
    }
}
