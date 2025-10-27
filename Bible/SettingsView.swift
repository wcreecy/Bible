//
//  SettingsView.swift
//  Bible
//
//  Created by William Creecy on 10/27/25.
//

import SwiftUI

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
            }
            .navigationTitle("Settings")
        }
    }
}
