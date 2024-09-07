import AVFoundation
import Speech

typealias SpeechRecognitionStream = AsyncThrowingStream<SpeechRecognitionResult, Error>

protocol SpeechRecognizing: Actor, Sendable {
    func requestAuthorization() async throws -> SFSpeechRecognizerAuthorizationStatus
    func startTask() -> SpeechRecognitionStream
    func finishTask() async
}

actor SpeechRecognitionService: SpeechRecognizing {
    var audioEngine: AVAudioEngine?
    var recognitionTask: SFSpeechRecognitionTask?
    
    func requestAuthorization() async throws -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
    
    func startTask() -> SpeechRecognitionStream {
        let request = SFSpeechAudioBufferRecognitionRequest()
        return AsyncThrowingStream { continuation in
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                continuation.finish(throwing: SpeechRecognitionError.couldNotConfigureAudioSession)
            }
            audioEngine = AVAudioEngine()
            guard let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) else {
                continuation.finish(throwing: SpeechRecognitionError.taskError)
                return
            }
            self.recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
                switch (result, error) {
                case (.some(let result), _):
                    continuation.yield(SpeechRecognitionResult(result))
                case (_, .some(let error)):
                    continuation.finish(throwing: error)
                case (.none, .none):
                    fatalError("Unexpected state: No result and no error.")
                }
            }
            continuation.onTermination = { [weak self] _ in
                Task { await self?.finishTask() }
            }
            let format = audioEngine?.inputNode.outputFormat(forBus: 0)
            audioEngine?.inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                request.append(buffer)
            }
            audioEngine?.prepare()
            do {
                try audioEngine?.start()
            } catch {
                continuation.finish(throwing: SpeechRecognitionError.couldNotStartAudioEngine)
            }
        }
    }
    
    func finishTask() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        recognitionTask = nil
    }
}

actor SpeechRecognitionServiceMock: SpeechRecognizing {
    var authorization: SFSpeechRecognizerAuthorizationStatus
    var stream: SpeechRecognitionStream
    
    init(authorization: SFSpeechRecognizerAuthorizationStatus, stream: SpeechRecognitionStream = .preview) {
        self.authorization = authorization
        self.stream = stream
    }
    
    func requestAuthorization() async throws -> SFSpeechRecognizerAuthorizationStatus {
        authorization
    }
    
    func startTask() -> SpeechRecognitionStream {
        stream
    }
    
    func finishTask() async {
        //...
    }
}

extension SpeechRecognitionStream {
    static let preview: Self = {
        AsyncThrowingStream { continuation in
            Task {
                var fullText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
                var words = fullText.split(separator: " ").map(String.init)
                var currentText = ""
                for word in words {
                    try await Task.sleep(for: .seconds(0.3))
                    currentText += "\(word) "
                    continuation.yield(
                        SpeechRecognitionResult(
                            bestTranscription: Transcription(formattedString: currentText, segments: []),
                            isFinal: false,
                            transcriptions: []
                        )
                    )
                }
                continuation.finish()
            }
        }
    }()
}
