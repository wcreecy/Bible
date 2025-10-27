//
//  BibleViewModel.swift
//  Bible
//
//  Created by William Creecy on 10/27/25.
//

import SwiftUI
import Combine

class BibleViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var loadingError: String?
    @Published var items: [VerseItem] = []

    private(set) var allVerses: [VerseResult] = []

    init() { loadBible() }

    // MARK: - Bible Loading
    func loadBible() {
        guard let url = Bundle.main.url(forResource: "kjv", withExtension: "json") else {
            loadingError = "Couldn't find kjv.json in bundle."
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let books = try decoder.decode([Book].self, from: data)
            self.books = books
            preprocessAllVerses()
            loadItems()
        } catch {
            loadingError = error.localizedDescription
        }
    }

    private func preprocessAllVerses() {
        var verses: [VerseResult] = []
        for (bIndex, book) in books.enumerated() {
            for (cIndex, chapter) in book.chapters.enumerated() {
                for (vIndex, verseText) in chapter.enumerated() {
                    verses.append(VerseResult(bookIndex: bIndex, chapterIndex: cIndex, verseIndex: vIndex, book: book, text: verseText))
                }
            }
        }
        allVerses = verses
    }

    // MARK: - Persistence
    private var itemsKey: String { "verseItems" }

    func saveItems() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: itemsKey)
        }
    }

    func loadItems() {
        guard let data = UserDefaults.standard.data(forKey: itemsKey),
              let saved = try? JSONDecoder().decode([VerseItem].self, from: data) else { return }
        self.items = saved
    }

    func addOrUpdateItem(_ item: VerseItem) {
        if let idx = items.firstIndex(of: item) {
            var updated = item
            updated.date = Date()
            items[idx] = updated
        } else {
            items.append(item)
        }
        saveItems()
    }

    func removeItem(_ item: VerseItem) {
        items.removeAll { $0 == item }
        saveItems()
    }

    func items(of type: VerseItemType) -> [VerseItem] {
        items.filter { $0.type == type }
    }

    func item(for type: VerseItemType, bookIndex: Int, chapter: Int, verse: Int) -> VerseItem? {
        items.first {
            $0.type == type &&
            $0.bookIndex == bookIndex &&
            $0.chapterIndex == chapter &&
            $0.verseIndex == verse
        }
    }

    // MARK: - Navigation Helper
    func navigationPath(for nav: BibleVerseNavigation) -> [BiblePathEntry] {
        guard books.indices.contains(nav.bookIndex) else { return [] }
        let book = books[nav.bookIndex]
        return [.book(book), .chapter(book, nav.chapterIndex), .verse(nav.bookIndex, nav.chapterIndex, nav.verseIndex)]
    }
}
