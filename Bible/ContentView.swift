import SwiftUI
import Combine

// MARK: - Models

struct Book: Codable, Identifiable, Hashable {
    var id: String { abbrev } // use abbrev as unique ID
    let abbrev: String
    let name: String
    let chapters: [[String]]

    enum CodingKeys: String, CodingKey {
        case abbrev, name, chapters
    }
}

struct ChapterSelection: Hashable {
    let bookAbbrev: String
    let chapterIndex: Int
}

// MARK: - ViewModel

class BibleViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var loadingError: String?

    init() {
        loadBible()
    }

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
        } catch {
            loadingError = error.localizedDescription
        }
    }
}

// MARK: - Main TabView

struct ContentView: View {
    var body: some View {
        TabView {
            Text("Home Page")
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            BibleTabView()
                .tabItem {
                    Label("Bible", systemImage: "book")
                }
            Text("Search Page")
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            Text("Favorites Page")
                .tabItem {
                    Label("Favorites", systemImage: "heart")
                }
            Text("Bookmarks Page")
                .tabItem {
                    Label("Bookmarks", systemImage: "bookmark")
                }
            Text("Notes Page")
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }
            Text("Settings Page")
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

// MARK: - Bible Views

struct BibleTabView: View {
    @StateObject private var viewModel = BibleViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                List(viewModel.books) { book in
                    NavigationLink(book.name, value: book)
                }
                .navigationTitle("Books")
                .navigationDestination(for: Book.self) { book in
                    ChapterListView(book: book, books: viewModel.books)
                }

                if let error = viewModel.loadingError {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
    }
}

struct ChapterListView: View {
    let book: Book
    let books: [Book]

    var body: some View {
        List(0..<book.chapters.count, id: \.self) { chapterIndex in
            NavigationLink(
                "Chapter \(chapterIndex + 1)",
                value: ChapterSelection(bookAbbrev: book.abbrev, chapterIndex: chapterIndex)
            )
        }
        .navigationTitle(book.name)
        .navigationDestination(for: ChapterSelection.self) { selection in
            if let selectedBook = books.first(where: { $0.abbrev == selection.bookAbbrev }) {
                VerseSelectionView(
                    book: selectedBook,
                    chapterIndex: selection.chapterIndex,
                    books: books
                )
            }
        }
    }
}

struct VerseSelectionView: View {
    let book: Book
    let chapterIndex: Int
    let books: [Book]

    var body: some View {
        List(0..<book.chapters[chapterIndex].count, id: \.self) { verseIndex in
            if let bookIndex = books.firstIndex(of: book) {
                NavigationLink(
                    "Verse \(verseIndex + 1)",
                    destination: VerseDetailView(
                        books: books,
                        bookIndex: bookIndex,
                        chapterIndex: chapterIndex,
                        verseIndex: verseIndex
                    )
                )
            }
        }
        .navigationTitle("\(book.name) \(chapterIndex + 1)")
    }
}

// MARK: - Verse Detail

struct VerseDetailView: View {
    let books: [Book]
    @State private var bookIndex: Int
    @State private var chapterIndex: Int
    @State private var verseIndex: Int
    @State private var highlightedVerse: Int? = nil
    @State private var isPersistentHighlight: Bool = false
    @State private var menuVerse: Int? = nil

    // Custom initializer for @State properties
    init(books: [Book], bookIndex: Int, chapterIndex: Int, verseIndex: Int) {
        self.books = books
        _bookIndex = State(initialValue: bookIndex)
        _chapterIndex = State(initialValue: chapterIndex)
        _verseIndex = State(initialValue: verseIndex)
    }

    var currentBook: Book { books[bookIndex] }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(currentBook.chapters[chapterIndex].indices, id: \.self) { idx in
                        VStack(alignment: .leading, spacing: 4) {
                            if idx > 0 {
                                Divider()
                                    .background(highlightedVerse == idx ? Color.yellow.opacity(0.4) : Color.clear)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(currentBook.chapters[chapterIndex][idx])
                                    .padding(.top, 8)
                                    .padding(.bottom, 2)

                                Text("\(currentBook.name) \(chapterIndex + 1):\(idx + 1)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                if menuVerse == idx {
                                    HStack(spacing: 24) {
                                        Image(systemName: "doc.on.doc").foregroundColor(.blue)
                                        Image(systemName: "square.and.arrow.up").foregroundColor(.blue)
                                        Image(systemName: "note.text").foregroundColor(.blue)
                                        Image(systemName: "bookmark").foregroundColor(.blue)
                                        Image(systemName: "heart").foregroundColor(.red)
                                    }
                                    .padding(.top, 8)
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 8)
                        }
                        .background(highlightedVerse == idx ? Color.yellow.opacity(0.4) : Color.clear) // ✅ includes divider
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .animation(.easeInOut(duration: 0.5), value: highlightedVerse)
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if highlightedVerse == idx && isPersistentHighlight {
                                highlightedVerse = nil
                                isPersistentHighlight = false
                            } else {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    highlightedVerse = idx
                                    isPersistentHighlight = true
                                }
                            }
                        }
                        .onLongPressGesture {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            menuVerse = (menuVerse == idx ? nil : idx)
                        }
                        .id(idx)
                    }
                }
                .padding(.vertical)
                .padding(.horizontal)
            }
            .navigationTitle("\(currentBook.name) \(chapterIndex + 1)")
            .onAppear {
                highlightedVerse = verseIndex
                isPersistentHighlight = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    proxy.scrollTo(verseIndex, anchor: .center)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if !isPersistentHighlight {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            highlightedVerse = nil
                        }
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let horizontalAmount = value.translation.width
                        if horizontalAmount < -40 {
                            goToNextChapter()
                        } else if horizontalAmount > 40 {
                            goToPreviousChapter()
                        }
                    }
            )
        }
    }

    // MARK: - Navigation Helpers
    func goToNextChapter() {
        if chapterIndex < currentBook.chapters.count - 1 {
            chapterIndex += 1
            verseIndex = 0
        } else if bookIndex < books.count - 1 {
            bookIndex += 1
            chapterIndex = 0
            verseIndex = 0
        }
    }

    func goToPreviousChapter() {
        if chapterIndex > 0 {
            chapterIndex -= 1
            verseIndex = 0
        } else if bookIndex > 0 {
            bookIndex -= 1
            chapterIndex = books[bookIndex].chapters.count - 1
            verseIndex = 0
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
