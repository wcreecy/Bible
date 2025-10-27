import SwiftUI

struct ContentView: View {
    @StateObject private var bibleViewModel = BibleViewModel()

    @AppStorage("textSizeOption") private var textSizeOption: TextSizeOption = .medium
    @AppStorage("appearanceOption") private var appearanceOption: AppearanceOption = .system

    @State private var selectedTab: Int = 0
    @State private var pendingBibleNavigation: BibleVerseNavigation? = nil

    var body: some View {
        TabView(selection: $selectedTab) {
            RandomVerseView(viewModel: bibleViewModel, onTapVerse: { verse in
                if let verse = verse {
                    pendingBibleNavigation = BibleVerseNavigation(bookIndex: verse.bookIndex, chapterIndex: verse.chapterIndex, verseIndex: verse.verseIndex)
                    selectedTab = 1
                }
            })
            .font(.callout)
            .tabItem { Label("Home", systemImage: "house") }
            .tag(0)

            BibleTabView(pendingNavigation: pendingBibleNavigation, onNavigationHandled: { pendingBibleNavigation = nil })
                .environmentObject(bibleViewModel)
                .tabItem { Label("Bible", systemImage: "book") }
                .tag(1)

            BibleSearchView(viewModel: bibleViewModel)
                .environmentObject(bibleViewModel)
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(2)

            ItemsListView(type: .favorite, title: "Favorites", icon: "heart", dateFormatter: FavoritesListView.dateFormatter)
                .environmentObject(bibleViewModel)
                .tabItem { Label("Favorites", systemImage: "heart") }
                .tag(3)

            ItemsListView(type: .bookmark, title: "Bookmarks", icon: "bookmark", dateFormatter: BookmarksListView.dateFormatter)
                .environmentObject(bibleViewModel)
                .tabItem { Label("Bookmarks", systemImage: "bookmark") }
                .tag(4)

            ItemsListView(type: .note, title: "Notes", icon: "note.text", dateFormatter: NoteEditView.dateFormatter)
                .environmentObject(bibleViewModel)
                .tabItem { Label("Notes", systemImage: "note.text") }
                .tag(5)

            SettingsView(textSizeOption: $textSizeOption, appearanceOption: $appearanceOption)
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(6)
        }
        .preferredColorScheme(appearanceOption.colorScheme)
        .environment(\.sizeCategory, textSizeOption.contentSizeCategory)
    }
}
