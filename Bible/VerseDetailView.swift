//
//  VerseDetailView.swift
//  Bible
//
//  Created by William Creecy on 10/27/25.
//

import SwiftUI

struct VerseDetailView: View {
    let books: [Book]
    @EnvironmentObject var bibleViewModel: BibleViewModel

    @State private var bookIndex: Int
    @State private var chapterIndex: Int
    @State private var verseIndex: Int
    @State private var highlightedVerse: Int? = nil
    @State private var isPersistentHighlight: Bool = false
    @State private var menuVerse: Int? = nil
    @State private var copiedVerse: Int? = nil
    @State private var shareText: ShareTextItem? = nil
    @State private var editingNote: VerseItem? = nil
    @State private var toastMessage: String? = nil

    init(books: [Book], bookIndex: Int, chapterIndex: Int, verseIndex: Int) {
        self.books = books
        _bookIndex = State(initialValue: bookIndex)
        _chapterIndex = State(initialValue: chapterIndex)
        _verseIndex = State(initialValue: verseIndex)
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
                highlightedVerse: highlightedVerse,
                menuVerse: menuVerse,
                copiedVerse: copiedVerse,
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
                onLongPress: { menuVerse = (menuVerse == idx ? nil : idx) },
                onCopy: {
                    UIPasteboard.general.string = currentBook.chapters[chapterIndex][idx]
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    copiedVerse = idx
                    menuVerse = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { if copiedVerse == idx { copiedVerse = nil } }
                },
                onShare: {
                    shareText = ShareTextItem(text: currentBook.chapters[chapterIndex][idx])
                    menuVerse = nil
                },
                onNote: {
                    if let existing = bibleViewModel.item(for: .note, bookIndex: bookIndex, chapter: chapterIndex, verse: idx) {
                        editingNote = existing
                    } else {
                        let newNote = VerseItem(book: currentBook, bookIndex: bookIndex, chapterIndex: chapterIndex, verseIndex: idx, text: currentBook.chapters[chapterIndex][idx], type: .note, customText: "")
                        editingNote = newNote
                    }
                    menuVerse = nil
                },
                onBookmark: {
                    if let existing = existingBookmark { bibleViewModel.removeItem(existing) }
                    else {
                        let newBookmark = VerseItem(book: currentBook, bookIndex: bookIndex, chapterIndex: chapterIndex, verseIndex: idx, text: currentBook.chapters[chapterIndex][idx], type: .bookmark)
                        bibleViewModel.addOrUpdateItem(newBookmark)
                        showToast("Added to Bookmarks")
                    }
                    menuVerse = nil
                },
                onFavorite: {
                    if let existing = existingFavorite { bibleViewModel.removeItem(existing) }
                    else {
                        let newFav = VerseItem(book: currentBook, bookIndex: bookIndex, chapterIndex: chapterIndex, verseIndex: idx, text: currentBook.chapters[chapterIndex][idx], type: .favorite)
                        bibleViewModel.addOrUpdateItem(newFav)
                        showToast("Added to Favorites")
                    }
                    menuVerse = nil
                }
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
                .navigationTitle("\(currentBook.name) \(chapterIndex + 1)")
                .onAppear {
                    highlightedVerse = verseIndex
                    isPersistentHighlight = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { proxy.scrollTo(verseIndex, anchor: .center) }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        if !isPersistentHighlight { withAnimation { highlightedVerse = nil } }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let toast = toastMessage {
                HStack(spacing: 8) {
                    if toast.contains("Favorites") { Image(systemName: "heart.fill").foregroundColor(.red) }
                    else if toast.contains("Bookmarks") { Image(systemName: "bookmark.fill").foregroundColor(.blue) }
                    Text(toast).fontWeight(.medium)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 24)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(radius: 10)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(item: $shareText) { item in ShareSheet(activityItems: [item.text]) }
        .sheet(item: $editingNote) { note in
            NoteEditView(note: note) { updated in
                var toSave = updated
                toSave.date = Date()
                bibleViewModel.addOrUpdateItem(toSave)
                editingNote = nil
            } onCancel: { editingNote = nil }
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
