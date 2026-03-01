import SwiftUI
#if MWDAT_ENABLED
import MWDATCore
import MWDATCamera
#endif

@main
struct RayBanMetaAIApp: App {

    init() {
        #if MWDAT_ENABLED
        // Step 3: SDK を初期化する - アプリ起動時に1回呼び出す
        Wearables.configure()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
