//
//  NoteEditView.swift
//  Bible
//
//  Created by William Creecy on 10/27/25.
//

import SwiftUI

struct NoteEditView: View {
    @State private var noteText: String
    let note: VerseItem // type == .note
    let onSave: (VerseItem) -> Void
    let onCancel: () -> Void

    init(note: VerseItem, onSave: @escaping (VerseItem) -> Void, onCancel: @escaping () -> Void) {
        self.note = note
        self.onSave = onSave
        self.onCancel = onCancel
        _noteText = State(initialValue: note.customText ?? "")
    }

    static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy, h:mm a"
        return df
    }()

    @ViewBuilder
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("Last Edited: \(Self.dateFormatter.string(from: note.date))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding([.top, .horizontal])

                TextEditor(text: $noteText)
                    .padding()

                Spacer()
            }
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updated = note
                        updated.customText = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
                        updated.date = Date()
                        onSave(updated)
                    }
                    .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

