//
//  BibleSearchView.swift
//  Bible
//
//  Created by William Creecy on 10/27/25.
//

import SwiftUI

struct BibleSearchView: View {
    @ObservedObject var viewModel: BibleViewModel
    @State private var searchText: String = ""
    @State private var results: [VerseResult] = []

    var body: some View {
        NavigationStack {
            Group {
                if let error = viewModel.loadingError {
                    Text("Error: \(error)").foregroundColor(.red).padding()
                } else if searchText.split(separator: " ").count < 2 {
                    Text("Enter at least two words to search.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                } else if results.isEmpty {
                    Text("No results found.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    List(results) { result in
                        NavigationLink {
                            VerseDetailView(
                                books: viewModel.books,
                                bookIndex: result.bookIndex,
                                chapterIndex: result.chapterIndex,
                                verseIndex: result.verseIndex
                            )
                            .environmentObject(viewModel)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(result.book.name) \(result.chapterIndex + 1):\(result.verseIndex + 1)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(result.text).lineLimit(2).foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText)
            .onChange(of: searchText) { _ in performSearch() }
        }
    }

    private func performSearch() {
        let words = searchText.lowercased().split(separator: " ").map { String($0) }
        guard words.count >= 2 else { results = []; return }
        results = viewModel.allVerses.filter { verse in
            let lowerText = verse.text.lowercased()
            return words.allSatisfy { lowerText.contains($0) }
        }
    }
}
