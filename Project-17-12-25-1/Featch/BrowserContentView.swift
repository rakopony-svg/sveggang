import SwiftUI
import WebKit

struct BrowserContentView: UIViewRepresentable {
    let targetUrl: String

    func makeUIView(context: Context) -> WKWebView {
        let browserView = WKWebView()
        browserView.navigationDelegate = context.coordinator
        browserView.allowsBackForwardNavigationGestures = true
        return browserView
    }

    func updateUIView(_ browserView: WKWebView, context: Context) {
        guard
            let encodedUrl = targetUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let validUrl = URL(string: encodedUrl)
        else { return }

        if browserView.url != validUrl {
            let urlRequest = URLRequest(url: validUrl)
            browserView.load(urlRequest)
        }
    }

    func makeCoordinator() -> NavigationCoordinator {
        NavigationCoordinator()
    }

    final class NavigationCoordinator: NSObject, WKNavigationDelegate {
        func webView(_ browserView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("🔄 Navigation started: \(browserView.url?.absoluteString ?? "")")
        }

        func webView(_ browserView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ Navigation completed")
        }

        func webView(_ browserView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("⚠️ Navigation failed: \(error.localizedDescription)")
        }
    }
}
