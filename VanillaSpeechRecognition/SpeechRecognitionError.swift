import Foundation

enum SpeechRecognitionError: Error, Equatable {
    case taskError
    case couldNotStartAudioEngine
    case couldNotConfigureAudioSession
}
