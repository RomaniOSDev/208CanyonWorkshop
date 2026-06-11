//
//  WebDocumentSurfaceView.swift
//  157Countdown
//

import SwiftUI
import WebKit

struct WebDocumentSurfaceView: View {
    let url: URL
    var onFailure: () -> Void

    @State private var webView: WKWebView?
    @State private var canGoBack = false
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        webView?.goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(canGoBack ? .white : .gray)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                    }
                    .disabled(!(canGoBack))

                    Spacer()

                    Button {
                        webView?.reload()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                    }
                }
                .frame(minHeight: 52)
                .background(Color.black)

                WebDocumentHostRepresentable(
                    url: url,
                    webView: $webView,
                    canGoBack: $canGoBack,
                    isLoading: $isLoading,
                    onFailure: onFailure
                )
            }

            if isLoading {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2.0)
                }
            }
        }
        .persistentSystemOverlays(.hidden)
    }
}

// MARK: - UIViewRepresentable

struct WebDocumentHostRepresentable: UIViewRepresentable {
    let url: URL
    @Binding var webView: WKWebView?
    @Binding var canGoBack: Bool
    @Binding var isLoading: Bool
    var onFailure: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.backgroundColor = .black
        view.isOpaque = false
        view.allowsBackForwardNavigationGestures = true
        context.coordinator.attach(webView: view)
        view.load(URLRequest(url: url))
        DispatchQueue.main.async {
            webView = view
        }
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.parent = self
        canGoBack = uiView.canGoBack
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: WebDocumentHostRepresentable
        private weak var attachedWebView: WKWebView?
        private var failureCalled = false

        init(parent: WebDocumentHostRepresentable) {
            self.parent = parent
        }

        func attach(webView: WKWebView) {
            attachedWebView = webView
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            if let httpResponse = navigationResponse.response as? HTTPURLResponse {
                if LaunchSessionStore.shared.savedLastURL == nil && !failureCalled {
                    if (400...599).contains(httpResponse.statusCode) {
                        failureCalled = true
                        LaunchSessionStore.shared.hasShownNativeShell = true
                        decisionHandler(.cancel)
                        DispatchQueue.main.async { self.parent.onFailure() }
                        return
                    }
                }
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url,
               ["mailto", "tel", "sms"].contains(url.scheme) {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.canGoBack = webView.canGoBack
            parent.isLoading = false
            if LaunchSessionStore.shared.savedLastURL == nil, let current = webView.url {
                LaunchSessionStore.shared.savedLastURL = current
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            triggerFailureIfNeeded()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            if LaunchSessionStore.shared.savedLastURL == nil {
                triggerFailureIfNeeded()
            }
        }

        private func triggerFailureIfNeeded() {
            guard LaunchSessionStore.shared.savedLastURL == nil, !failureCalled else { return }
            failureCalled = true
            LaunchSessionStore.shared.hasShownNativeShell = true
            DispatchQueue.main.async { self.parent.onFailure() }
        }
    }
}
