//
//  WebView.swift
//  booksp
//
//  Created by NANAMI MIMURA on 2023/11/04.
//

import Foundation
import SwiftUI
import WebKit


struct WebView: UIViewRepresentable {
    
    let loardUrl: URL

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: loardUrl)
        uiView.load(request)
    }
}

struct WebViewWindow: View {
    var body: some View {
        WebView(loardUrl: URL(string: "https://amzn.asia/d/5D2hIpo")!)
    }
}
