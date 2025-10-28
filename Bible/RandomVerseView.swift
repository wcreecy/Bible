//
//  RandomVerseView.swift
//  Bible
//
//  Created by William Creecy on 10/27/25.
//

import SwiftUI
import AVFoundation
import AudioToolbox

extension View {
    func heroCard() -> some View {
        self
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.10), radius: 7, y: 2)
            .padding(.horizontal)
    }
}

struct RandomVerseView: View {
    @ObservedObject var viewModel: BibleViewModel
    var onTapVerse: ((VerseResult?) -> Void)? = nil
    @State private var currentVerse: VerseResult?
    @State private var showingShare: Bool = false
    @State private var copied: Bool = false
    
    @State private var showTimerSheet = false
    @State private var timerDuration: Int = 300 // default 5 minutes
    @State private var timerActive = false
    @State private var timeRemaining: Int = 0
    @State private var showTimerEndedAlert = false
    @State private var timerPaused = false

    private var isFavorite: Bool {
        guard let verse = currentVerse else { return false }
        return viewModel.item(for: .favorite, bookIndex: verse.bookIndex, chapter: verse.chapterIndex, verse: verse.verseIndex) != nil
    }
    
    private var timerCardColor: Color {
        guard timerActive, timerDuration > 0 else { return .clear }
        let percent = Double(timeRemaining) / Double(timerDuration)
        if percent > 0.5 {
            return .green.opacity(0.18)
        } else if percent > 0.10 {
            return .yellow.opacity(0.18)
        } else {
            return .red.opacity(0.18)
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            // Card 1: Main Title
            VStack {
                Text("Word of God")
                    .font(.system(size: 44, weight: .black, design: .serif))
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.accentColor, .primary]), startPoint: .leading, endPoint: .trailing))
                    .multilineTextAlignment(.center)
                    .tracking(1.2)
                    .shadow(color: .black.opacity(0.08), radius: 3, y: 2)
                    .accessibilityAddTraits(.isHeader)
            }
            .frame(maxWidth: .infinity)
            .heroCard()
            .padding(.vertical, 4)
            
            Spacer().frame(height: 10)

            // Card 2: Verse of the day section
            VStack(spacing: 8) {
                HStack(alignment: .top, spacing: 6) {
                    Text("“")
                        .font(.system(size: 42, weight: .bold, design: .serif))
                        .foregroundColor(.accentColor)
                        .padding(.top, -6)

                    Text("Verse of the day")
                        .font(.headline)  // matches Prayer/Study Timer
                        .foregroundColor(.primary)
                        .accessibilityAddTraits(.isHeader)
                }
                
                Group {
                    if let error = viewModel.loadingError {
                        Text("Error: \(error)").foregroundColor(.red)
                    } else if let verse = currentVerse {
                        VStack(spacing: 6) {
                            Text(verse.text)
                                .font(.body)
                                .multilineTextAlignment(.center)

                            Text("\(verse.book.name) \(verse.chapterIndex + 1):\(verse.verseIndex + 1)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onTapVerse?(verse)
                        }
                    } else {
                        ProgressView().progressViewStyle(.circular)
                    }
                }
                
                HStack(spacing: 32) {
                    Button(action: pickRandomVerse) {
                        Image(systemName: "arrow.clockwise").font(.title2)
                    }
                    Button(action: {
                        if let verse = currentVerse {
                            UIPasteboard.general.string = verse.text
                            copied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { copied = false }
                        }
                    }) {
                        Image(systemName: "doc.on.doc").font(.title2)
                    }
                    Button(action: { showingShare = true }) {
                        Image(systemName: "square.and.arrow.up").font(.title2)
                    }
                    .disabled(currentVerse == nil)
                    Button(action: {
                        guard let verse = currentVerse else { return }
                        if isFavorite {
                            if let item = viewModel.item(for: .favorite, bookIndex: verse.bookIndex, chapter: verse.chapterIndex, verse: verse.verseIndex) {
                                viewModel.removeItem(item)
                            }
                        } else {
                            viewModel.addOrUpdateItem(VerseItem(book: verse.book, bookIndex: verse.bookIndex, chapterIndex: verse.chapterIndex, verseIndex: verse.verseIndex, text: verse.text, type: .favorite))
                        }
                    }) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(.red)
                            .font(.title2)
                    }
                    .disabled(currentVerse == nil)
                }
                .padding(.top, 2)
                
                if copied {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        Text("Copied!").fontWeight(.medium)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 18)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .shadow(radius: 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .heroCard()
            .padding(.vertical, 4)
            
            Spacer().frame(height: 4)

            // Card 3: Prayer/Study Timer section
            ZStack {
                if timerActive {
                    RoundedRectangle(cornerRadius: 22, style: .continuous).fill(timerCardColor)
                }
                VStack(alignment: .center, spacing: 12) {
                    // Header with timer icon
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                        Text("Prayer/Study Timer")
                            .font(.headline)
                    }

                    Text("Start a focused timer with an alert when time is up.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    if !timerActive {
                        Button(action: { showTimerSheet = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "play.circle.fill")   // Start/play icon
                                    .font(.title2)
                                Text("Start")
                                    .font(.body)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    } else {
                        HStack(spacing: 40) {
                            Button(action: {
                                timerPaused.toggle()
                            }) {
                                Image(systemName: timerPaused ? "play.circle" : "pause.circle")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            Button(action: {
                                timerActive = false
                                timerPaused = false
                                timeRemaining = 0
                            }) {
                                Image(systemName: "stop.circle")
                                    .font(.title2)
                                    .foregroundColor(.red)
                            }
                        }
                        if timerActive {
                            VStack(spacing: 4) {
                                Text("Timer Running")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                Text(timeString(from: timeRemaining))
                                    .font(.title.monospacedDigit().weight(.medium))
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .heroCard()
            .frame(height: 130)
            .padding(.vertical, 4)
            
            Spacer().frame(height: 12)
        }
        .padding(.top, 20)
        .safeAreaInset(edge: .bottom) {
            Button(action: {
                // No action yet
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.uturn.forward.circle.fill") // Resume icon
                        .font(.headline)
                    Text("Resume")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 2)
            .padding(.horizontal)
            .heroCard()
            .padding(.vertical, 2)
            .padding(.bottom, 10)
        }
        .onAppear(perform: pickRandomVerse)
        .sheet(isPresented: $showingShare) {
            if let verse = currentVerse {
                ShareSheet(activityItems: ["\(verse.text)\n\n\(verse.book.name) \(verse.chapterIndex + 1):\(verse.verseIndex + 1)"])
            }
        }
        .sheet(isPresented: $showTimerSheet) {
            VStack(spacing: 20) {
                Text("Select timer length").font(.title3.bold())
                Picker("Duration", selection: $timerDuration) {
                    ForEach(1...120, id: \.self) { min in
                        Text("\(min) minute\(min == 1 ? "" : "s")").tag(min * 60)
                    }
                }
                .pickerStyle(.wheel)
                Button("Start") {
                    timeRemaining = timerDuration
                    timerActive = true
                    timerPaused = false
                    showTimerSheet = false
                }
                .buttonStyle(.borderedProminent)
                Button("Cancel", role: .cancel) { showTimerSheet = false }
            }
            .padding()
            .presentationDetents([.medium])
        }
        .onChange(of: timerActive) { isActive in
            if isActive {
                startTimer()
            }
        }
        .onChange(of: timeRemaining) { value in
            if timerActive && value <= 0 {
                timerActive = false
                showTimerEndedAlert = true
                AudioServicesPlaySystemSound(1005)
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        }
        .alert("Time's Up!", isPresented: $showTimerEndedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your prayer/study timer has ended.")
        }
    }

    private func pickRandomVerse() {
        guard !viewModel.allVerses.isEmpty else { currentVerse = nil; return }
        currentVerse = viewModel.allVerses.randomElement()
    }
    
    private func timeString(from seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if timerPaused || !timerActive {
                return
            }
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer.invalidate()
            }
        }
    }
}
