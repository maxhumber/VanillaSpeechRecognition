import Speech

struct SpeechRecognitionResult: Equatable {
    var bestTranscription: Transcription
    var isFinal: Bool
    var speechRecognitionMetadata: SpeechRecognitionMetadata?
    var transcriptions: [Transcription]
}

extension SpeechRecognitionResult {
    init(_ speechRecognitionResult: SFSpeechRecognitionResult) {
        self.bestTranscription = Transcription(speechRecognitionResult.bestTranscription)
        self.isFinal = speechRecognitionResult.isFinal
        self.speechRecognitionMetadata = speechRecognitionResult.speechRecognitionMetadata
            .map(SpeechRecognitionMetadata.init)
        self.transcriptions = speechRecognitionResult.transcriptions.map(Transcription.init)
    }
}

struct Transcription: Equatable {
    var formattedString: String
    var segments: [TranscriptionSegment]
}

extension Transcription {
    init(_ transcription: SFTranscription) {
        self.formattedString = transcription.formattedString
        self.segments = transcription.segments.map(TranscriptionSegment.init)
    }
}

struct TranscriptionSegment: Equatable {
    var alternativeSubstrings: [String]
    var confidence: Float
    var duration: TimeInterval
    var substring: String
    var timestamp: TimeInterval
}

extension TranscriptionSegment {
    init(_ transcriptionSegment: SFTranscriptionSegment) {
        self.alternativeSubstrings = transcriptionSegment.alternativeSubstrings
        self.confidence = transcriptionSegment.confidence
        self.duration = transcriptionSegment.duration
        self.substring = transcriptionSegment.substring
        self.timestamp = transcriptionSegment.timestamp
    }
}

struct SpeechRecognitionMetadata: Equatable {
    var averagePauseDuration: TimeInterval
    var speakingRate: Double
    var voiceAnalytics: VoiceAnalytics?
}

extension SpeechRecognitionMetadata {
    init(_ speechRecognitionMetadata: SFSpeechRecognitionMetadata) {
        self.averagePauseDuration = speechRecognitionMetadata.averagePauseDuration
        self.speakingRate = speechRecognitionMetadata.speakingRate
        self.voiceAnalytics = speechRecognitionMetadata.voiceAnalytics.map(VoiceAnalytics.init)
    }
}

struct VoiceAnalytics: Equatable {
    var jitter: AcousticFeature
    var pitch: AcousticFeature
    var shimmer: AcousticFeature
    var voicing: AcousticFeature
}

extension VoiceAnalytics {
    init(_ voiceAnalytics: SFVoiceAnalytics) {
        self.jitter = AcousticFeature(voiceAnalytics.jitter)
        self.pitch = AcousticFeature(voiceAnalytics.pitch)
        self.shimmer = AcousticFeature(voiceAnalytics.shimmer)
        self.voicing = AcousticFeature(voiceAnalytics.voicing)
    }
}

struct AcousticFeature: Equatable {
    var acousticFeatureValuePerFrame: [Double]
    var frameDuration: TimeInterval
}

extension AcousticFeature {
    init(_ acousticFeature: SFAcousticFeature) {
        self.acousticFeatureValuePerFrame = acousticFeature.acousticFeatureValuePerFrame
        self.frameDuration = acousticFeature.frameDuration
    }
}
