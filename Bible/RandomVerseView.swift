//
//  RandomVerseView.swift
//  Bible
//
//  Created by William Creecy on 10/27/25.
//

import SwiftUI

struct RandomVerseView: View {
    @ObservedObject var viewModel: BibleViewModel
    var onTapVerse: ((VerseResult?) -> Void)? = nil
    @State private var currentVerse: VerseResult?
    @State private var showingShare: Bool = false
    @State private var copied: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 40)
            Group {
                if let error = viewModel.loadingError {
                    Text("Error: \(error)").foregroundColor(.red)
                } else if let verse = currentVerse {
                    VStack(spacing: 12) {
                        Text(verse.text)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Text("\(verse.book.name) \(verse.chapterIndex + 1):\(verse.verseIndex + 1)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onTapVerse?(verse)
                    }
                } else {
                    ProgressView().progressViewStyle(.circular)
                }
            }
            HStack(spacing: 32) {
                Button(action: pickRandomVerse) {
                    Image(systemName: "arrow.clockwise").font(.title2)
                }
                Button(action: {
                    if let verse = currentVerse {
                        UIPasteboard.general.string = verse.text
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { copied = false }
                    }
                }) {
                    Image(systemName: "doc.on.doc").font(.title2)
                }
                Button(action: { showingShare = true }) {
                    Image(systemName: "square.and.arrow.up").font(.title2)
                }
                .disabled(currentVerse == nil)
            }.padding(.top, 6)

            if copied {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    Text("Copied!").fontWeight(.medium)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 18)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(radius: 6)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer()
        }
        .onAppear(perform: pickRandomVerse)
        .sheet(isPresented: $showingShare) {
            if let verse = currentVerse {
                ShareSheet(activityItems: ["\(verse.text)\n\n\(verse.book.name) \(verse.chapterIndex + 1):\(verse.verseIndex + 1)"])
            }
        }
    }

    private func pickRandomVerse() {
        guard !viewModel.allVerses.isEmpty else { currentVerse = nil; return }
        currentVerse = viewModel.allVerses.randomElement()
    }
}
