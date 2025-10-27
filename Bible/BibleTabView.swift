//
//  BibleTabView.swift
//  Bible
//
//  Created by William Creecy on 10/27/25.
//

import SwiftUI

enum BiblePathEntry: Hashable {
    case book(Book)
    case chapter(Book, Int)
    case verse(Int, Int, Int)
}

struct BibleTabView: View {
    @EnvironmentObject private var viewModel: BibleViewModel
    var pendingNavigation: BibleVerseNavigation? = nil
    var onNavigationHandled: (() -> Void)? = nil
    @State private var path: [BiblePathEntry] = []

    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                List(viewModel.books) { book in
                    NavigationLink(book.name, value: BiblePathEntry.book(book))
                }
                .navigationTitle("Books")
                .navigationDestination(for: BiblePathEntry.self) { entry in
                    switch entry {
                    case .book(let book):
                        ChapterListView(book: book, books: viewModel.books)
                    case .chapter(let book, let chapterIndex):
                        VerseSelectionView(book: book, chapterIndex: chapterIndex, books: viewModel.books)
                    case .verse(let bookIndex, let chapterIndex, let verseIndex):
                        VerseDetailView(
                            books: viewModel.books,
                            bookIndex: bookIndex,
                            chapterIndex: chapterIndex,
                            verseIndex: verseIndex
                        )
                    }
                }
                if let error = viewModel.loadingError {
                    Text(error).foregroundStyle(.red)
                }
            }
            .onAppear {
                if let nav = pendingNavigation, path.isEmpty {
                    path = viewModel.navigationPath(for: nav)
                    DispatchQueue.main.async { onNavigationHandled?() }
                }
            }
            .onChange(of: pendingNavigation) { newValue in
                guard let nav = newValue else { return }
                path = viewModel.navigationPath(for: nav)
                DispatchQueue.main.async { onNavigationHandled?() }
            }
        }
    }
}

struct ChapterListView: View {
    let book: Book
    let books: [Book]

    var body: some View {
        List(0..<book.chapters.count, id: \.self) { chapterIndex in
            NavigationLink("Chapter \(chapterIndex + 1)", value: BiblePathEntry.chapter(book, chapterIndex))
        }
        .navigationTitle(book.name)
    }
}

struct VerseSelectionView: View {
    let book: Book
    let chapterIndex: Int
    let books: [Book]

    var body: some View {
        List(0..<book.chapters[chapterIndex].count, id: \.self) { verseIndex in
            if let bookIndex = books.firstIndex(of: book) {
                NavigationLink("Verse \(verseIndex + 1)", value: BiblePathEntry.verse(bookIndex, chapterIndex, verseIndex))
            }
        }
        .navigationTitle("\(book.name) \(chapterIndex + 1)")
    }
}
