//
//  WebView.swift
//  HappyTime
//
//  Created by Finn Wu on 2021/12/29.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {

    let url: URL?

    func makeUIView(context: Context) -> WKWebView {
        .init(frame: .zero)
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let sharedCookies = HTTPCookieStorage.shared.cookies
        if (sharedCookies?.count ?? 0) > 0 {
            let wkCookies = uiView.configuration.websiteDataStore.httpCookieStore
            sharedCookies?.forEach {
                guard let url = url, url.absoluteString.contains($0.domain) else {
                    return
                }
                wkCookies.setCookie($0, completionHandler: { })
            }
        }
        
        guard let url = url else { return }
        uiView.load(.init(url: url))
    }
}
