import Testing
@testable import VanillaSpeechRecognition

struct VanillaSpeechTests {
    @Test
    func testDenyAuthorization() async throws {
        let service = SpeechRecognitionServiceMock(authorization: .denied)
        let viewModel = await SpeechRecognitionViewModel()
        await viewModel.handleRecording(using: service)
        #expect(await viewModel.alertMessage == "You denied access to speech recognition or it is not available.")
    }
    
    @Test
    func testRestrictedAuthorization() async throws {
        let service = SpeechRecognitionServiceMock(authorization: .restricted)
        let viewModel = await SpeechRecognitionViewModel()
        await viewModel.handleRecording(using: service)
        #expect(await viewModel.alertMessage == "You denied access to speech recognition or it is not available.")
    }
    
    @Test
    func testAllowAndRecord() async throws {
        let service = SpeechRecognitionServiceMock(authorization: .authorized, stream: .preview)
        let viewModel = await SpeechRecognitionViewModel()
        await viewModel.handleRecording(using: service)
        #expect(await viewModel.transcribedText.contains("Lorem ipsum"))
    }
    
    @Test
    func testAudioSessionFailure() async throws {
        let stream: SpeechRecognitionStream = {
            AsyncThrowingStream { continuation in
                continuation.finish(throwing: SpeechRecognitionError.couldNotConfigureAudioSession)
            }
        }()
        let service = SpeechRecognitionServiceMock(authorization: .authorized, stream: stream)
        let viewModel = await SpeechRecognitionViewModel()
        await viewModel.handleRecording(using: service)
        #expect(await viewModel.alertMessage == "An error occurred while transcribing.")
        #expect(await viewModel.isRecording == false)
    }
    
    @Test
    func testAudioEngineFailure() async throws {
        let stream: SpeechRecognitionStream = {
            AsyncThrowingStream { continuation in
                continuation.finish(throwing: SpeechRecognitionError.couldNotStartAudioEngine)
            }
        }()
        let service = SpeechRecognitionServiceMock(authorization: .authorized, stream: stream)
        let viewModel = await SpeechRecognitionViewModel()
        await viewModel.handleRecording(using: service)
        #expect(await viewModel.alertMessage == "An error occurred while transcribing.")
        #expect(await viewModel.isRecording == false)
    }
}
