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

// New Note model with date
struct Note: Identifiable {
    let id = UUID()
    let book: Book
    let bookIndex: Int
    let chapterIndex: Int
    let verseIndex: Int
    var text: String
    var date: Date
}

// New Bookmark model with date
struct Bookmark: Identifiable, Equatable {
    let id = UUID()
    let book: Book
    let bookIndex: Int
    let chapterIndex: Int
    let verseIndex: Int
    let text: String
    var date: Date
    
    static func == (lhs: Bookmark, rhs: Bookmark) -> Bool {
        lhs.bookIndex == rhs.bookIndex &&
        lhs.chapterIndex == rhs.chapterIndex &&
        lhs.verseIndex == rhs.verseIndex
    }
}

// New Favorite model with date
struct Favorite: Identifiable, Equatable {
    let id = UUID()
    let book: Book
    let bookIndex: Int
    let chapterIndex: Int
    let verseIndex: Int
    let text: String
    var date: Date
    
    static func == (lhs: Favorite, rhs: Favorite) -> Bool {
        lhs.bookIndex == rhs.bookIndex &&
        lhs.chapterIndex == rhs.chapterIndex &&
        lhs.verseIndex == rhs.verseIndex
    }
}

// MARK: - ViewModel

class BibleViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var loadingError: String?
    
    @Published var notes: [Note] = []
    @Published var bookmarks: [Bookmark] = []
    @Published var favorites: [Favorite] = []
    
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
    
    func upsertNote(_ note: Note) {
        if let idx = notes.firstIndex(where: { $0.bookIndex == note.bookIndex && $0.chapterIndex == note.chapterIndex && $0.verseIndex == note.verseIndex }) {
            var updatedNote = note
            updatedNote.date = Date() // update last edited date
            notes[idx] = updatedNote
        } else {
            notes.append(note)
        }
    }
    
    func note(for bookIndex: Int, chapter: Int, verse: Int) -> Note? {
        notes.first(where: { $0.bookIndex == bookIndex && $0.chapterIndex == chapter && $0.verseIndex == verse })
    }
    
    // MARK: - Bookmark Helpers
    
    func upsertBookmark(_ bookmark: Bookmark) {
        if let idx = bookmarks.firstIndex(where: {
            $0.bookIndex == bookmark.bookIndex &&
            $0.chapterIndex == bookmark.chapterIndex &&
            $0.verseIndex == bookmark.verseIndex
        }) {
            // Update date to now (refresh)
            var updatedBookmark = bookmarks[idx]
            updatedBookmark.date = Date()
            bookmarks[idx] = updatedBookmark
        } else {
            bookmarks.append(bookmark)
        }
    }
    
    func removeBookmark(for bookIndex: Int, chapter: Int, verse: Int) {
        if let idx = bookmarks.firstIndex(where: {
            $0.bookIndex == bookIndex &&
            $0.chapterIndex == chapter &&
            $0.verseIndex == verse
        }) {
            bookmarks.remove(at: idx)
        }
    }
    
    func isBookmarked(for bookIndex: Int, chapter: Int, verse: Int) -> Bool {
        bookmarks.contains(where: {
            $0.bookIndex == bookIndex &&
            $0.chapterIndex == chapter &&
            $0.verseIndex == verse
        })
    }
    
    // MARK: - Favorite Helpers
    
    func upsertFavorite(_ favorite: Favorite) {
        if let idx = favorites.firstIndex(where: {
            $0.bookIndex == favorite.bookIndex &&
            $0.chapterIndex == favorite.chapterIndex &&
            $0.verseIndex == favorite.verseIndex
        }) {
            var updatedFavorite = favorites[idx]
            updatedFavorite.date = Date()
            favorites[idx] = updatedFavorite
        } else {
            favorites.append(favorite)
        }
    }
    
    func removeFavorite(for bookIndex: Int, chapter: Int, verse: Int) {
        if let idx = favorites.firstIndex(where: {
            $0.bookIndex == bookIndex &&
            $0.chapterIndex == chapter &&
            $0.verseIndex == verse
        }) {
            favorites.remove(at: idx)
        }
    }
    
    func isFavorite(for bookIndex: Int, chapter: Int, verse: Int) -> Bool {
        favorites.contains(where: {
            $0.bookIndex == bookIndex &&
            $0.chapterIndex == chapter &&
            $0.verseIndex == verse
        })
    }
}

// MARK: - VerseResult

struct VerseResult: Identifiable {
    let id = UUID()
    let bookIndex: Int
    let chapterIndex: Int
    let verseIndex: Int
    let book: Book
    let text: String
}

// MARK: - BibleSearchView

struct BibleSearchView: View {
    @ObservedObject var viewModel: BibleViewModel
    @State private var searchText: String = ""
    @State private var results: [VerseResult] = []
    @State private var allVerses: [VerseResult] = []

    var body: some View {
        NavigationStack {
            Group {
                if searchText.split(separator: " ").count < 2 {
                    VStack(spacing: 16) {
                        Text("Enter at least two words to search.")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                        Spacer()
                    }
                } else if results.isEmpty {
                    VStack(spacing: 16) {
                        Text("No results found.")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                        Spacer()
                    }
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
                                Text(result.text)
                                    .lineLimit(2)
                                    .foregroundColor(.primary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .onChange(of: searchText) { newValue in
                performSearch()
            }
            .onAppear {
                preprocessAllVerses()
            }
        }
    }

    private func preprocessAllVerses() {
        guard !viewModel.books.isEmpty else { return }
        var verses: [VerseResult] = []
        for (bIndex, book) in viewModel.books.enumerated() {
            for (cIndex, chapter) in book.chapters.enumerated() {
                for (vIndex, verseText) in chapter.enumerated() {
                    verses.append(
                        VerseResult(
                            bookIndex: bIndex,
                            chapterIndex: cIndex,
                            verseIndex: vIndex,
                            book: book,
                            text: verseText
                        )
                    )
                }
            }
        }
        allVerses = verses
    }

    private func performSearch() {
        let words = searchText.lowercased().split(separator: " ").map { String($0) }
        guard words.count >= 2 else {
            results = []
            return
        }

        // Efficient filtering: verse must contain all words (case insensitive)
        results = allVerses.filter { verse in
            let lowerText = verse.text.lowercased()
            for word in words {
                if !lowerText.contains(word) {
                    return false
                }
            }
            return true
        }
    }
}

// MARK: - Main TabView

struct ContentView: View {
    @StateObject private var bibleViewModel = BibleViewModel()
    
    @AppStorage("textSizeOption") private var textSizeOption: TextSizeOption = .medium
    @AppStorage("appearanceOption") private var appearanceOption: AppearanceOption = .system

    var body: some View {
        TabView {
            Text("Home Page")
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            BibleTabView()
                .environmentObject(bibleViewModel)
                .tabItem {
                    Label("Bible", systemImage: "book")
                }
            BibleSearchView(viewModel: bibleViewModel)
                .environmentObject(bibleViewModel)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            FavoritesListView()
                .environmentObject(bibleViewModel)
                .tabItem {
                    Label("Favorites", systemImage: "heart")
                }
            BookmarksListView()
                .environmentObject(bibleViewModel)
                .tabItem {
                    Label("Bookmarks", systemImage: "bookmark")
                }
            NotesListView()
                .environmentObject(bibleViewModel)
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }
            SettingsView(textSizeOption: $textSizeOption, appearanceOption: $appearanceOption)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .preferredColorScheme(appearanceOption.colorScheme)
        .environment(\.sizeCategory, textSizeOption.contentSizeCategory)
    }
}

// MARK: - Bible Views

struct BibleTabView: View {
    @EnvironmentObject private var viewModel: BibleViewModel

    var body: some View {
        NavigationStack {
            VStack {
                List(viewModel.books) { book in
                    NavigationLink(book.name, value: book)
                }
                .navigationTitle("Books")
                .navigationDestination(for: Book.self) { book in
                    ChapterListView(book: book, books: viewModel.books)
                        .environmentObject(viewModel)
                }

                if let error = viewModel.loadingError {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
    }
}

struct ChapterListView: View {
    @EnvironmentObject var bibleViewModel: BibleViewModel

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
                .environmentObject(bibleViewModel)
            }
        }
    }
}

struct VerseSelectionView: View {
    @EnvironmentObject var bibleViewModel: BibleViewModel

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
                    .environmentObject(bibleViewModel)
                )
            }
        }
        .navigationTitle("\(book.name) \(chapterIndex + 1)")
    }
}

// MARK: - NotesListView

struct NotesListView: View {
    @EnvironmentObject var bibleViewModel: BibleViewModel
    
    var body: some View {
        NavigationStack {
            if bibleViewModel.notes.isEmpty {
                Text("No notes added yet.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                List {
                    ForEach(bibleViewModel.notes) { note in
                        if let bookIndex = bibleViewModel.books.firstIndex(of: note.book) {
                            NavigationLink {
                                VerseDetailView(
                                    books: bibleViewModel.books,
                                    bookIndex: bookIndex,
                                    chapterIndex: note.chapterIndex,
                                    verseIndex: note.verseIndex
                                )
                                .environmentObject(bibleViewModel)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(note.book.name) \(note.chapterIndex + 1):\(note.verseIndex + 1)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(note.text)
                                        .lineLimit(2)
                                        .foregroundColor(.primary)
                                    Text(NoteEditView.dateFormatter.string(from: note.date))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .navigationTitle("Notes")
            }
        }
    }
}

// MARK: - BookmarksListView

struct BookmarksListView: View {
    @EnvironmentObject var bibleViewModel: BibleViewModel
    
    var body: some View {
        NavigationStack {
            if bibleViewModel.bookmarks.isEmpty {
                Text("No bookmarks added yet.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                List {
                    ForEach(bibleViewModel.bookmarks.sorted(by: { $0.date > $1.date })) { bookmark in
                        if let bookIndex = bibleViewModel.books.firstIndex(of: bookmark.book) {
                            NavigationLink {
                                VerseDetailView(
                                    books: bibleViewModel.books,
                                    bookIndex: bookIndex,
                                    chapterIndex: bookmark.chapterIndex,
                                    verseIndex: bookmark.verseIndex
                                )
                                .environmentObject(bibleViewModel)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(bookmark.book.name) \(bookmark.chapterIndex + 1):\(bookmark.verseIndex + 1)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(bookmark.text)
                                        .lineLimit(2)
                                        .foregroundColor(.primary)
                                    Text(BookmarksListView.dateFormatter.string(from: bookmark.date))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .navigationTitle("Bookmarks")
            }
        }
    }
    
    static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy, h:mm a"
        return df
    }()
}

// MARK: - FavoritesListView

struct FavoritesListView: View {
    @EnvironmentObject var bibleViewModel: BibleViewModel
    
    var body: some View {
        NavigationStack {
            if bibleViewModel.favorites.isEmpty {
                Text("No favorites added yet.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                List {
                    ForEach(bibleViewModel.favorites.sorted(by: { $0.date > $1.date })) { favorite in
                        if let bookIndex = bibleViewModel.books.firstIndex(of: favorite.book) {
                            NavigationLink {
                                VerseDetailView(
                                    books: bibleViewModel.books,
                                    bookIndex: bookIndex,
                                    chapterIndex: favorite.chapterIndex,
                                    verseIndex: favorite.verseIndex
                                )
                                .environmentObject(bibleViewModel)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(favorite.book.name) \(favorite.chapterIndex + 1):\(favorite.verseIndex + 1)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(favorite.text)
                                        .lineLimit(2)
                                        .foregroundColor(.primary)
                                    Text(FavoritesListView.dateFormatter.string(from: favorite.date))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .navigationTitle("Favorites")
            }
        }
    }
    
    static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy, h:mm a"
        return df
    }()
}

// MARK: - ShareTextItem

struct ShareTextItem: Identifiable {
    let id = UUID()
    let text: String
}

// MARK: - Verse Detail

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
    
    @State private var editingNote: Note? = nil
    
    @State private var toastMessage: String? = nil

    // Custom initializer for @State properties
    init(books: [Book], bookIndex: Int, chapterIndex: Int, verseIndex: Int) {
        self.books = books
        _bookIndex = State(initialValue: bookIndex)
        _chapterIndex = State(initialValue: chapterIndex)
        _verseIndex = State(initialValue: verseIndex)
    }

    var currentBook: Book { books[bookIndex] }

    private var verseRows: some View {
        ForEach(currentBook.chapters[chapterIndex].indices, id: \.self) { idx in
            let isBookmarked = bibleViewModel.isBookmarked(for: bookIndex, chapter: chapterIndex, verse: idx)
            let isFavorite = bibleViewModel.isFavorite(for: bookIndex, chapter: chapterIndex, verse: idx)
            VerseRowView(
                book: currentBook,
                chapterIndex: chapterIndex,
                idx: idx,
                highlightedVerse: highlightedVerse,
                isPersistentHighlight: isPersistentHighlight,
                menuVerse: menuVerse,
                copiedVerse: copiedVerse,
                isBookmarked: isBookmarked,
                isFavorite: isFavorite,
                onTap: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if menuVerse == idx {
                        menuVerse = nil
                    } else {
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
                },
                onLongPress: {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    menuVerse = (menuVerse == idx ? nil : idx)
                },
                onCopy: {
                    UIPasteboard.general.string = currentBook.chapters[chapterIndex][idx]
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    copiedVerse = idx
                    menuVerse = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        if copiedVerse == idx { copiedVerse = nil }
                    }
                },
                onShare: {
                    shareText = ShareTextItem(text: currentBook.chapters[chapterIndex][idx])
                    menuVerse = nil
                },
                onNote: {
                    // Open note editor with existing or new note
                    if let existingNote = bibleViewModel.note(for: bookIndex, chapter: chapterIndex, verse: idx) {
                        editingNote = existingNote
                    } else {
                        editingNote = Note(book: currentBook, bookIndex: bookIndex, chapterIndex: chapterIndex, verseIndex: idx, text: "", date: Date())
                    }
                    menuVerse = nil
                },
                onBookmark: {
                    if isBookmarked {
                        bibleViewModel.removeBookmark(for: bookIndex, chapter: chapterIndex, verse: idx)
                    } else {
                        let newBookmark = Bookmark(
                            book: currentBook,
                            bookIndex: bookIndex,
                            chapterIndex: chapterIndex,
                            verseIndex: idx,
                            text: currentBook.chapters[chapterIndex][idx],
                            date: Date()
                        )
                        bibleViewModel.upsertBookmark(newBookmark)
                        toastMessage = "Added to Bookmarks"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                toastMessage = nil
                            }
                        }
                    }
                    menuVerse = nil
                },
                onFavorite: {
                    if isFavorite {
                        bibleViewModel.removeFavorite(for: bookIndex, chapter: chapterIndex, verse: idx)
                    } else {
                        let newFavorite = Favorite(
                            book: currentBook,
                            bookIndex: bookIndex,
                            chapterIndex: chapterIndex,
                            verseIndex: idx,
                            text: currentBook.chapters[chapterIndex][idx],
                            date: Date()
                        )
                        bibleViewModel.upsertFavorite(newFavorite)
                        toastMessage = "Added to Favorites"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                toastMessage = nil
                            }
                        }
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
        .safeAreaInset(edge: .bottom) {
            Group {
                if let toast = toastMessage {
                    HStack(spacing: 8) {
                        if toast == "Added to Favorites" {
                            Image(systemName: "heart.fill").foregroundColor(.red)
                        } else if toast == "Added to Bookmarks" {
                            Image(systemName: "bookmark.fill").foregroundColor(.blue)
                        } else {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        }
                        Text(toast).fontWeight(.medium)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 24)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .shadow(radius: 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: toastMessage)
                } else if copiedVerse != nil {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        Text("Copied!")
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 24)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .shadow(radius: 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: copiedVerse)
                }
            }
        }
        .sheet(item: $shareText, onDismiss: {
            shareText = nil
        }) { item in
            ShareSheet(activityItems: [item.text])
        }
        .sheet(item: $editingNote, onDismiss: {
            editingNote = nil
        }) { note in
            NoteEditView(note: note) { updatedNote in
                bibleViewModel.upsertNote(updatedNote)
                editingNote = nil
            } onCancel: {
                editingNote = nil
            }
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

    // MARK: - VerseRowView

    private struct VerseRowView: View {
        let book: Book
        let chapterIndex: Int
        let idx: Int
        let highlightedVerse: Int?
        let isPersistentHighlight: Bool
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
                if idx > 0 {
                    Divider()
                        .background(highlightedVerse == idx ? Color.yellow.opacity(0.4) : Color.clear)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(book.chapters[chapterIndex][idx])
                        .padding(.top, 8)
                        .padding(.bottom, 2)

                    Text("\(book.name) \(chapterIndex + 1):\(idx + 1)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if menuVerse == idx {
                        HStack(spacing: 24) {
                            Button(action: onCopy) {
                                Image(systemName: "doc.on.doc").foregroundColor(.blue)
                            }
                            Button(action: onShare) {
                                Image(systemName: "square.and.arrow.up").foregroundColor(.blue)
                            }
                            Button(action: onNote) {
                                Image(systemName: "note.text").foregroundColor(.blue)
                            }
                            Button(action: onBookmark) {
                                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                    .foregroundColor(.blue)
                            }
                            Button(action: onFavorite) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart").foregroundColor(.red)
                            }
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
            .onTapGesture(perform: onTap)
            .onLongPressGesture(perform: onLongPress)
        }
    }
}

// MARK: - NoteEditView

struct NoteEditView: View {
    @State private var noteText: String
    let note: Note
    let onSave: (Note) -> Void
    let onCancel: () -> Void
    
    init(note: Note, onSave: @escaping (Note) -> Void, onCancel: @escaping () -> Void) {
        self.note = note
        self.onSave = onSave
        self.onCancel = onCancel
        _noteText = State(initialValue: note.text)
    }
    
    static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy, h:mm a"
        return df
    }()
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("Last Edited: \(Self.dateFormatter.string(from: note.date))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding([.top, .horizontal])
                
                TextEditor(text: $noteText)
                    .padding(.horizontal)
                    .padding(.bottom)
                    .navigationTitle("Edit Note")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                onCancel()
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                var updatedNote = note
                                updatedNote.text = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
                                updatedNote.date = Date()
                                onSave(updatedNote)
                            }
                            .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
            }
        }
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Settings Enums and View

enum TextSizeOption: String, CaseIterable, Identifiable {
    case small
    case medium
    case large
    
    var id: String { rawValue }
    
    var contentSizeCategory: ContentSizeCategory {
        switch self {
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        }
    }
}

enum AppearanceOption: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
    
    var id: String { rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct SettingsView: View {
    @Binding var textSizeOption: TextSizeOption
    @Binding var appearanceOption: AppearanceOption
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Text Size") {
                    Picker("Text Size", selection: $textSizeOption) {
                        ForEach(TextSizeOption.allCases) { option in
                            Text(option.rawValue.capitalized).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Appearance") {
                    Picker("Appearance", selection: $appearanceOption) {
                        ForEach(AppearanceOption.allCases) { option in
                            Text(option.rawValue.capitalized).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
