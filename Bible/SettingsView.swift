//
//  SettingsView.swift
//  Bible
//
//  Created by William Creecy on 10/27/25.
//

import SwiftUI
import AVFoundation

enum TextSizeOption: String, CaseIterable, Identifiable {
    case small, medium, large
    var id: String { rawValue }

    var contentSizeCategory: ContentSizeCategory {
        switch self {
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        }
    }
}

enum AppearanceOption: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct SettingsView: View {
    @Binding var textSizeOption: TextSizeOption
    @Binding var appearanceOption: AppearanceOption

    // Store selected speech voice identifier in app storage for persistence
    @AppStorage("speechVoiceIdentifier") private var speechVoiceIdentifier: String = AVSpeechSynthesisVoice(language: "en-US")?.identifier ?? ""

    // List of available voices sorted by language code
    private var availableVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices().sorted { $0.language < $1.language }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Text Size") {
                    Picker("Text Size", selection: $textSizeOption) {
                        ForEach(TextSizeOption.allCases) { option in
                            Text(option.rawValue.capitalized).tag(option)
                        }
                    }.pickerStyle(.segmented)
                }

                Section("Appearance") {
                    Picker("Appearance", selection: $appearanceOption) {
                        ForEach(AppearanceOption.allCases) { option in
                            Text(option.rawValue.capitalized).tag(option)
                        }
                    }.pickerStyle(.segmented)
                }

                // Text-to-Speech voice selection
                Section("Text-to-Speech") {
                    Picker("Voice", selection: $speechVoiceIdentifier) {
                        ForEach(availableVoices, id: \.identifier) { voice in
                            Text("\(voice.name) (\(voice.language))").tag(voice.identifier)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
