//
//  Models.swift
//  Bible
//
//  Created by William Creecy on 10/27/25.
//

import SwiftUI
import Combine

// MARK: - Models

struct Book: Codable, Identifiable, Hashable {
    var id: String { abbrev }
    let abbrev: String
    let name: String
    let chapters: [[String]]
}

enum VerseItemType: String, Codable {
    case note, bookmark, favorite
}

struct VerseItem: Identifiable, Codable, Equatable {
    let id: UUID
    let book: Book
    let bookIndex: Int
    let chapterIndex: Int
    let verseIndex: Int
    var text: String
    var customText: String? // used for Notes
    var date: Date
    let type: VerseItemType

    init(book: Book, bookIndex: Int, chapterIndex: Int, verseIndex: Int, text: String, type: VerseItemType, customText: String? = nil, date: Date = Date()) {
        self.id = UUID()
        self.book = book
        self.bookIndex = bookIndex
        self.chapterIndex = chapterIndex
        self.verseIndex = verseIndex
        self.text = text
        self.customText = customText
        self.date = date
        self.type = type
    }

    static func == (lhs: VerseItem, rhs: VerseItem) -> Bool {
        lhs.bookIndex == rhs.bookIndex &&
        lhs.chapterIndex == rhs.chapterIndex &&
        lhs.verseIndex == rhs.verseIndex &&
        lhs.type == rhs.type
    }
}

struct BibleVerseNavigation: Equatable {
    let bookIndex: Int
    let chapterIndex: Int
    let verseIndex: Int
}

struct VerseResult: Identifiable {
    let id = UUID()
    let bookIndex: Int
    let chapterIndex: Int
    let verseIndex: Int
    let book: Book
    let text: String
}
