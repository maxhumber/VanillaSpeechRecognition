import Speech
import SwiftUI

// MARK: - View

struct SpeechRecognitionView: View {
    @Environment(\.speechRecognitionClient) private var client: SpeechRecognitionClient
    @State private var viewModel = SpeechRecognitionViewModel()
    
    var body: some View {
        content
            .alert("Error", isPresented: .constant(viewModel.alertMessage != nil)) {
                Button("OK", role: .cancel) { viewModel.alertMessage = nil }
            } message: {
                Text(viewModel.alertMessage ?? "No Error")
            }
    }
    
    private var content: some View {
        VStack {
            scrollingTranscription
            startStopButton
        }
        .padding()
    }
    
    private var scrollingTranscription: some View {
        ScrollView {
            Text(viewModel.transcribedText)
                .animation(.linear, value: viewModel.transcribedText)
                .font(.title2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .scrollIndicators(.hidden)
    }
    
    private var startStopButton: some View {
        Button {
            Task { await viewModel.handleRecording(using: client) }
        } label: {
            Label(viewModel.labelText, systemImage: viewModel.labelSymbol)
                .font(.title3)
                .foregroundColor(Color(uiColor: .systemBackground))
                .padding()
                .background(viewModel.isRecording ? Color.red : Color.green)
                .cornerRadius(16)
        }
    }
}

// MARK: - View Model

@MainActor @Observable
class SpeechRecognitionViewModel {
    var isRecording = false
    var transcribedText = ""
    var alertMessage: String? = nil
    
    var labelText: String {
        isRecording ? "Stop Recording" : "Start Recording"
    }
    
    var labelSymbol: String {
        isRecording ? "stop.circle.fill" : "arrowtriangle.right.circle.fill"
    }
    
    func handleRecording(using client: SpeechRecognitionClient) async {
        if isRecording {
            await client.finishTask()
            isRecording = false
        } else {
            guard await checkAuthorization(using: client) else { return }
            await startRecording(using: client)
        }
    }
    
    private func checkAuthorization(using client: SpeechRecognitionClient) async -> Bool {
        let status = await client.requestAuthorization()
        if status == .authorized {
            return true
        } else {
            alertMessage = "You denied access to speech recognition or it is not available"
            return false
        }
    }
    
    private func startRecording(using client: SpeechRecognitionClient) async {
        do {
            isRecording = true
            for try await result in await client.startTask() {
                transcribedText = result
            }
        } catch {
            alertMessage = "An error occurred while transcribing"
            isRecording = false
        }
    }
}

// MARK: - Speech Recognition Client

extension EnvironmentValues {
    @Entry var speechRecognitionClient: SpeechRecognitionClient = .live
}

struct SpeechRecognitionClient {
    var requestAuthorization: @Sendable () async -> SFSpeechRecognizerAuthorizationStatus = { .notDetermined }
    var startTask: @Sendable () async -> AsyncThrowingStream<String, Error> = { AsyncThrowingStream { $0.finish() } }
    var finishTask: @Sendable () async -> Void = {}
    
    static var live: Self {
        let actor = SpeechRecognitionActor()
        return Self(
            requestAuthorization: { await actor.requestAuthorization() },
            startTask: { await actor.startTask() },
            finishTask: { await actor.finishTask() }
        )
    }
}

// MARK: - Speech Recognition Actor

extension SFSpeechAudioBufferRecognitionRequest: @unchecked @retroactive Sendable {}

private actor SpeechRecognitionActor {
    private var audioEngine: AVAudioEngine?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionContinuation: AsyncThrowingStream<String, Error>.Continuation?
    
    func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
    
    func startTask() async -> AsyncThrowingStream<String, Error> {
        let request = SFSpeechAudioBufferRecognitionRequest()
        return AsyncThrowingStream { continuation in
            recognitionContinuation = continuation
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                continuation.finish(throwing: SpeechRecognitionError.couldNotConfigureAudioSession)
                return
            }
            audioEngine = AVAudioEngine()
            guard let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) else {
                continuation.finish(throwing: SpeechRecognitionError.taskError)
                return
            }
            recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
                switch (result, error) {
                case (.some(let result), _): continuation.yield(result.bestTranscription.formattedString)
                case (_, .some): continuation.finish(throwing: SpeechRecognitionError.taskError)
                case (nil, nil): fatalError("Unexpected state: No result and no error")
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
                return
            }
        }
    }
    
    func finishTask() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionTask?.finish()
        recognitionContinuation?.finish()
    }
}

// MARK: - Errors

enum SpeechRecognitionError: Error {
    case taskError
    case couldNotStartAudioEngine
    case couldNotConfigureAudioSession
}

// MARK: - Preview

#Preview {
    SpeechRecognitionView()
        .environment(\.speechRecognitionClient, .preview)
}

extension SpeechRecognitionClient {
    static var preview: Self {
        let actor = PreviewActor()
        return Self(
            requestAuthorization: { .authorized },
            startTask: { await actor.start("This is just going to stream in...") },
            finishTask: { await actor.stop() }
        )
    }
    
    private actor PreviewActor {
        private var task: Task<Void, Never>?
        
        func start(_ fullText: String) -> AsyncThrowingStream<String, Error> {
            AsyncThrowingStream { continuation in
                task = Task {
                    let words = fullText.split(separator: " ").map(String.init)
                    var currentText = ""
                    for word in words {
                        if Task.isCancelled { break }
                        try? await Task.sleep(for: .seconds(0.3))
                        currentText += "\(word) "
                        continuation.yield(currentText)
                    }
                    continuation.finish()
                }
            }
        }
        
        func stop() {
            task?.cancel()
            task = nil
        }
    }
}
