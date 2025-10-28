//
//  RandomVerseView.swift
//  Bible
//
//  Created by William Creecy on 10/27/25.
//

import SwiftUI
import AVFoundation
import AudioToolbox

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

    var body: some View {
        VStack(spacing: 24) {
            Text("Word of God")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .padding(.top, 32)
                .accessibilityAddTraits(.isHeader)
            
            Text("Verse of the day")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.bottom, 2)
                .accessibilityAddTraits(.isHeader)
            
            Group {
                if let error = viewModel.loadingError {
                    Text("Error: \(error)").foregroundColor(.red)
                } else if let verse = currentVerse {
                    VStack(spacing: 12) {
                        Text(verse.text)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
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
            }.padding(.top, 6)
            
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
            
            VStack(alignment: .center, spacing: 12) {
                Text("Prayer/Study Timer").font(.headline)
                Text("Start a focused timer with an alert when time is up.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button(action: { showTimerSheet = true }) {
                    Label("Start Timer", systemImage: "timer")
                        .font(.body.bold())
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
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
                            showTimerSheet = false
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Cancel", role: .cancel) { showTimerSheet = false }
                    }
                    .padding()
                    .presentationDetents([.medium])
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
            .padding(.horizontal)
            
            Spacer()
        }
        .safeAreaInset(edge: .bottom) {
            Button("Resume") {
                // No action yet
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal)
        }
        .onAppear(perform: pickRandomVerse)
        .sheet(isPresented: $showingShare) {
            if let verse = currentVerse {
                ShareSheet(activityItems: ["\(verse.text)\n\n\(verse.book.name) \(verse.chapterIndex + 1):\(verse.verseIndex + 1)"])
            }
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
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer.invalidate()
            }
        }
    }
}

