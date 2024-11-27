import Testing
@testable import VanillaSpeechRecognition

@Suite
struct VanillaSpeechRecognitionTests {
    @Test
    func testDenyAuthorization() async throws {
        let client = SpeechRecognitionClient(
            requestAuthorization: { .denied }
        )
        let viewModel = await SpeechRecognitionViewModel()
        await viewModel.handleRecording(using: client)
        #expect(await viewModel.alertMessage == "You denied access to speech recognition or it is not available")
    }
    
    @Test
    func testRestrictedAuthorization() async throws {
        let client = SpeechRecognitionClient(
            requestAuthorization: { .restricted }
        )
        let viewModel = await SpeechRecognitionViewModel()
        await viewModel.handleRecording(using: client)
        #expect(await viewModel.alertMessage == "You denied access to speech recognition or it is not available")
    }
    
    @Test
    func testAllowAndRecord() async throws {
        let client = SpeechRecognitionClient(
            requestAuthorization: { .authorized },
            startTask: {
                AsyncThrowingStream { continuation in
                    continuation.yield("Lorem ipsum")
                    continuation.finish()
                }
            }
        )
        let viewModel = await SpeechRecognitionViewModel()
        await viewModel.handleRecording(using: client)
        #expect(await viewModel.transcribedText.contains("Lorem ipsum"))
    }
    
    @Test
    func testAudioSessionFailure() async throws {
        let client = SpeechRecognitionClient(
            requestAuthorization: { .authorized },
            startTask: {
                AsyncThrowingStream { continuation in
                    continuation.finish(throwing: SpeechRecognitionError.couldNotConfigureAudioSession)
                }
            }
        )
        let viewModel = await SpeechRecognitionViewModel()
        await viewModel.handleRecording(using: client)
        #expect(await viewModel.alertMessage == "An error occurred while transcribing")
        #expect(await viewModel.isRecording == false)
    }
    
    @Test
    func testAudioEngineFailure() async throws {
        let client = SpeechRecognitionClient(
            requestAuthorization: { .authorized },
            startTask: {
                AsyncThrowingStream { continuation in
                    continuation.finish(throwing: SpeechRecognitionError.couldNotStartAudioEngine)
                }
            }
        )
        let viewModel = await SpeechRecognitionViewModel()
        await viewModel.handleRecording(using: client)
        #expect(await viewModel.alertMessage == "An error occurred while transcribing")
        #expect(await viewModel.isRecording == false)
    }
}
