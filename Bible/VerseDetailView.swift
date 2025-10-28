//
//  VerseDetailView.swift
//  Bible
//
//  Created by William Creecy on 10/27/25.
//

import SwiftUI
import AVFoundation
import Combine

class BibleSpeechCoordinator: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isReading = false
    @Published var readingVerseIdx: Int? = nil
    private(set) var bookIndex: Int
    private(set) var chapterIndex: Int
    private(set) var verseIndex: Int
    private let books: [Book]
    private var proxy: ScrollViewProxy?
    private var synthesizer: AVSpeechSynthesizer?
    private let selectedVoice: String
    private let speechRate: Double

    init(books: [Book], bookIndex: Int, chapterIndex: Int, verseIndex: Int, selectedVoice: String, speechRate: Double) {
        self.books = books
        self.bookIndex = bookIndex
        self.chapterIndex = chapterIndex
        self.verseIndex = verseIndex
        self.selectedVoice = selectedVoice
        self.speechRate = speechRate
    }

    func assignProxy(_ proxy: ScrollViewProxy) {
        self.proxy = proxy
    }

    func startReading() {
        synthesizer = AVSpeechSynthesizer()
        synthesizer?.delegate = self
        isReading = true
        readingVerseIdx = verseIndex
        speakNext()
    }

    func stopReading() {
        synthesizer?.stopSpeaking(at: .immediate)
        isReading = false
        readingVerseIdx = nil
        synthesizer = nil
    }

    private func speakNext() {
        guard chapterIndex < books[bookIndex].chapters.count else {
            stopReading()
            return
        }
        let verses = books[bookIndex].chapters[chapterIndex]
        guard let idx = readingVerseIdx, idx < verses.count else {
            if chapterIndex + 1 < books[bookIndex].chapters.count {
                chapterIndex += 1
                readingVerseIdx = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { self.speakNext() }
            } else if bookIndex + 1 < books.count {
                bookIndex += 1
                chapterIndex = 0
                readingVerseIdx = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { self.speakNext() }
            } else {
                stopReading()
            }
            return
        }
        let utterance = AVSpeechUtterance(string: verses[idx])
        if let voice = AVSpeechSynthesisVoice(identifier: selectedVoice) {
            utterance.voice = voice
        }
        utterance.rate = Float(speechRate)
        synthesizer?.speak(utterance)
        highlightAndScroll(idx)
    }

    private func highlightAndScroll(_ idx: Int) {
        withAnimation { self.readingVerseIdx = idx }
        proxy?.scrollTo(idx, anchor: .center)
    }

    func speechSynthesizer(_ synth: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if isReading, let idx = readingVerseIdx {
            readingVerseIdx = idx + 1
            speakNext()
        }
    }
}

struct VerseDetailView: View {
    let books: [Book]
    @EnvironmentObject var bibleViewModel: BibleViewModel

    @State private var bookIndex: Int
    @State private var chapterIndex: Int
    @State private var verseIndex: Int
    @State private var highlightedVerse: Int? = nil
    @State private var isPersistentHighlight: Bool = false
    @State private var toastMessage: String? = nil

    @AppStorage("speechVoiceIdentifier") private var speechVoiceIdentifier: String = AVSpeechSynthesisVoice(language: "en-US")?.identifier ?? ""
    @AppStorage("speechRate") private var speechRate: Double = 0.5

    @StateObject private var speechCoordinator: BibleSpeechCoordinator

    init(books: [Book], bookIndex: Int, chapterIndex: Int, verseIndex: Int) {
        self.books = books
        _bookIndex = State(initialValue: bookIndex)
        _chapterIndex = State(initialValue: chapterIndex)
        _verseIndex = State(initialValue: verseIndex)
        _speechCoordinator = StateObject(wrappedValue: BibleSpeechCoordinator(
            books: books,
            bookIndex: bookIndex,
            chapterIndex: chapterIndex,
            verseIndex: verseIndex,
            selectedVoice: AVSpeechSynthesisVoice(language: "en-US")?.identifier ?? "",
            speechRate: 0.5
        ))
    }

    var currentBook: Book { books[bookIndex] }

    private var verseRows: some View {
        ForEach(currentBook.chapters[chapterIndex].indices, id: \.self) { idx in
            let existingBookmark = bibleViewModel.item(for: .bookmark, bookIndex: bookIndex, chapter: chapterIndex, verse: idx)
            let existingFavorite = bibleViewModel.item(for: .favorite, bookIndex: bookIndex, chapter: chapterIndex, verse: idx)

            VerseRowView(
                book: currentBook,
                chapterIndex: chapterIndex,
                idx: idx,
                highlightedVerse: speechCoordinator.isReading ? speechCoordinator.readingVerseIdx : highlightedVerse,
                menuVerse: nil,
                copiedVerse: nil,
                isBookmarked: existingBookmark != nil,
                isFavorite: existingFavorite != nil,
                onTap: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if highlightedVerse == idx && isPersistentHighlight {
                        highlightedVerse = nil
                        isPersistentHighlight = false
                    } else {
                        withAnimation { highlightedVerse = idx; isPersistentHighlight = true }
                    }
                },
                onLongPress: {},
                onCopy: {},
                onShare: {},
                onNote: {},
                onBookmark: {},
                onFavorite: {}
            )
            .id(idx)
        }
    }

    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        verseRows
                    }
                    .padding(.vertical)
                    .padding(.horizontal)
                }
                .gesture(
                    DragGesture().onEnded { value in
                        if value.translation.width < -40 {
                            // Swipe left: next chapter (if available)
                            if chapterIndex + 1 < currentBook.chapters.count {
                                chapterIndex += 1
                                verseIndex = 0
                                highlightedVerse = 0
                                isPersistentHighlight = false
                                DispatchQueue.main.async {
                                    proxy.scrollTo(0, anchor: .center)
                                }
                            }
                        } else if value.translation.width > 40 {
                            // Swipe right: previous chapter (if available)
                            if chapterIndex > 0 {
                                chapterIndex -= 1
                                verseIndex = 0
                                highlightedVerse = 0
                                isPersistentHighlight = false
                                DispatchQueue.main.async {
                                    proxy.scrollTo(0, anchor: .center)
                                }
                            }
                        }
                    }
                )
                .navigationTitle("\(currentBook.name) \(chapterIndex + 1)")
                .onAppear {
                    highlightedVerse = verseIndex
                    isPersistentHighlight = false
                    speechCoordinator.assignProxy(proxy)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { proxy.scrollTo(verseIndex, anchor: .center) }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        if !isPersistentHighlight { withAnimation { highlightedVerse = nil } }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                Button(action: {
                    if speechCoordinator.isReading {
                        speechCoordinator.stopReading()
                    } else {
                        speechCoordinator.startReading()
                    }
                }) {
                    Image(systemName: speechCoordinator.isReading ? "stop.circle.fill" : "play.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.primary)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial)
                        .opacity(0.75)
                        .clipShape(Circle())
                        .contentShape(Circle())
                }
                Spacer()
            }
            .padding(.vertical, 10)
        }
    }

    private func showToast(_ text: String) {
        toastMessage = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation { toastMessage = nil } }
    }
}

// MARK: - VerseRowView
private struct VerseRowView: View {
    let book: Book
    let chapterIndex: Int
    let idx: Int
    let highlightedVerse: Int?
    let menuVerse: Int?
    let copiedVerse: Int?
    let isBookmarked: Bool
    let isFavorite: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onCopy: () -> Void
    let onShare: () -> Void
    let onNote: () -> Void
    let onBookmark: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if idx > 0 { Divider() }
            VStack(alignment: .leading, spacing: 6) {
                Text(book.chapters[chapterIndex][idx])
                    .padding(.top, 8)
                    .padding(.bottom, 2)

                Text("\(book.name) \(chapterIndex + 1):\(idx + 1)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if menuVerse == idx {
                    HStack(spacing: 24) {
                        Button(action: onCopy) { Image(systemName: "doc.on.doc").foregroundColor(.blue) }
                        Button(action: onShare) { Image(systemName: "square.and.arrow.up").foregroundColor(.blue) }
                        Button(action: onNote) { Image(systemName: "note.text").foregroundColor(.blue) }
                        Button(action: onBookmark) { Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark").foregroundColor(.blue) }
                        Button(action: onFavorite) { Image(systemName: isFavorite ? "heart.fill" : "heart").foregroundColor(.red) }
                    }
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
        }
        .background(RoundedRectangle(cornerRadius: 6).fill(highlightedVerse == idx ? Color.yellow.opacity(0.3) : Color.clear))
        .onTapGesture(perform: onTap)
        .onLongPressGesture(perform: onLongPress)
    }
}
