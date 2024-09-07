import SwiftUI

@main
struct VanillaSpeechRecognitionApp: App {
    let speechRecognitionService = SpeechRecognitionService()
    
    var body: some Scene {
        WindowGroup {
            SpeechRecognitionView()
                .environment(\.speechRecognitionService, speechRecognitionService)
        }
    }
}
