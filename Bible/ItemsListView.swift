//
//  ItemsListView.swift
//  Bible
//
//  Created by William Creecy on 10/27/25.
//

import SwiftUI

struct ItemsListView: View {
    @EnvironmentObject var bibleViewModel: BibleViewModel
    let type: VerseItemType
    let title: String
    let icon: String
    let dateFormatter: DateFormatter

    var body: some View {
        NavigationStack {
            let filtered = bibleViewModel.items(of: type).sorted { $0.date > $1.date }
            if filtered.isEmpty {
                Text("No \(title.lowercased()) added yet.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                List {
                    ForEach(filtered) { item in
                        NavigationLink {
                            VerseDetailView(
                                books: bibleViewModel.books,
                                bookIndex: item.bookIndex,
                                chapterIndex: item.chapterIndex,
                                verseIndex: item.verseIndex
                            )
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(item.book.name) \(item.chapterIndex + 1):\(item.verseIndex + 1)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if type == .note, let custom = item.customText, !custom.isEmpty {
                                    Text(custom).lineLimit(2).foregroundColor(.primary)
                                } else {
                                    Text(item.text).lineLimit(2).foregroundColor(.primary)
                                }
                                Text(dateFormatter.string(from: item.date))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .navigationTitle(title)
            }
        }
    }
}

struct BookmarksListView {
    static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy, h:mm a"
        return df
    }()
}

struct FavoritesListView {
    static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy, h:mm a"
        return df
    }()
}
