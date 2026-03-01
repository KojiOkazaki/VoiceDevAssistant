import SwiftUI
import MWDATCore
import MWDATCamera

@main
struct RayBanMetaAIApp: App {

    init() {
        // Step 3: SDK を初期化する - アプリ起動時に1回呼び出す
        Wearables.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
