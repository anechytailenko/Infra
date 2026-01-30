import SwiftUI
import Combine

// MARK: - 1. App Entry Point
@main
struct FileSorterApp: App {
    var body: some Scene {
        WindowGroup {
            PromptView()
        }
        .windowStyle(.hiddenTitleBar)
    }
}
