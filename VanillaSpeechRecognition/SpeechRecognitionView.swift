import Speech
import SwiftUI

struct SpeechRecognitionView: View {
    @Environment(\.speechRecognitionService) var service: SpeechRecognizing
    @State var viewModel = SpeechRecognitionViewModel()
    
    var body: some View {
        content
            .alert("Error", isPresented: $viewModel.alertIsPresented) {
                Button("OK", role: .cancel, action: {})
            } message: {
                Text(viewModel.alertMessage)
            }
    }
    
    private var content: some View {
        VStack {
            scrollingTranscription
            button
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
    
    private var button: some View {
        Button {
            Task { await viewModel.handleRecording(using: service) }
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

@MainActor @Observable
class SpeechRecognitionViewModel {
    var isRecording = false
    var transcribedText = ""
    var alertMessage = ""
    var alertIsPresented = false
    
    var labelText: String {
        isRecording ? "Stop Recording" : "Start Recording"
    }
    
    var labelSymbol: String {
        isRecording ? "stop.circle.fill" : "arrowtriangle.right.circle.fill"
    }
    
    func handleRecording(using service: SpeechRecognizing) async {
        if isRecording {
            await service.finishTask()
            isRecording = false
        } else {
            guard await checkAuthorization(using: service) else { return }
            await startRecording(using: service)
        }
    }
    
    private func checkAuthorization(using service: SpeechRecognizing) async -> Bool {
        let status = try? await service.requestAuthorization()
        if status == .authorized {
            return true
        } else {
            presentAlert("You denied access to speech recognition or it is not available.")
            return false
        }
    }
    
    private func startRecording(using service: SpeechRecognizing) async {
        do {
            isRecording = true
            for try await result in await service.startTask() {
                transcribedText = result.bestTranscription.formattedString
            }
        } catch {
            presentAlert("An error occurred while transcribing.")
            isRecording = false
        }
    }
    
    private func presentAlert(_ message: String) {
        alertMessage = message
        alertIsPresented = true
    }
}

#Preview {
    SpeechRecognitionView()
        .environment(\.speechRecognitionService, SpeechRecognitionServiceMock(authorization: .authorized, stream: .preview))
}
