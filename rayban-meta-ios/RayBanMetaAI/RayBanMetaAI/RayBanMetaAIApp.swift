import SwiftUI
#if canImport(MWDATCore)
import MWDATCore
#endif
#if canImport(MWDATCamera)
import MWDATCamera
#endif

@main
struct RayBanMetaAIApp: App {

    init() {
        // Step 3: SDK を初期化する - アプリ起動時に1回呼び出す
        #if canImport(MWDATCore)
        Wearables.configure()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
