### 🍦 VanillaSpeechRecognition

A 1:1 "vanilla" implementation of the [TCA SpeechRecognition](https://github.com/pointfreeco/swift-composable-architecture/tree/1.16.1/Examples/SpeechRecognition) app (v1.16.1)

It is 100% compatible with **Swift 6**, **Xcode 16**, and **iOS 18**, and does not use any third-party dependencies.

#### Comparison

| Metric                      | 🍦          | TCA             |
| --------------------------- | ---------- | --------------- |
| Dependencies                | 0          | 16              |
| "Cold" Build Time (seconds) | 1.1        | 32.4            |
| "Warm" Build Time (seconds) | 0.1        | 0.4             |
| Indexing Time               | Negligible | Several minutes |
| Lines of code\*             | 319        | 579             |

\*Calculated by:

```zsh
% find . -name '*.swift' | xargs wc -l
      73 ./VanillaSpeechRecognitionTests/VanillaSpeechRecognitionTests.swift
     236 ./VanillaSpeechRecognition/SpeechRecognitionView.swift
      10 ./VanillaSpeechRecognition/VanillaSpeechRecognitionApp.swift
     319 total
```

#### Screenshot

<img src="Images/VSR.png" alt="VSR" width="200">
