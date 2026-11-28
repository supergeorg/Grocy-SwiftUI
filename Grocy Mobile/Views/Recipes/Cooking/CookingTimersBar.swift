//
//  CookingTimersBar.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 28.11.26.
//

import SwiftUI

/// The running cooking timers, floating above the bottom of the cooking mode on every page.
struct CookingTimersBar: View {
    var store: CookingTimerStore = .shared
    /// The recipe of this cooking mode; timers of other recipes show their recipe's name.
    var recipeID: Int
    /// Opens the timer's step, if it's of this recipe.
    var onSelect: (CookingTimer) -> Void = { _ in }

    var body: some View {
        if !store.timers.isEmpty {
            ScrollView(.horizontal) {
                GlassEffectContainer(spacing: Spacing.small) {
                    HStack(spacing: Spacing.small) {
                        ForEach(store.timers) { timer in
                            CookingTimerCapsule(
                                timer: timer,
                                showsRecipe: timer.recipeID != recipeID,
                                store: store,
                                onSelect: { onSelect(timer) }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, Spacing.small)
                }
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            .sensoryFeedback(.warning, trigger: store.timers.filter(\.isFinished).count) { old, new in new > old }
            .animation(.smooth, value: store.timers)
        }
    }
}

/// One timer: a progress ring, the time left and what it's for, and buttons to pause and remove it.
private struct CookingTimerCapsule: View {
    var timer: CookingTimer
    var showsRecipe: Bool
    var store: CookingTimerStore
    var onSelect: () -> Void

    @Environment(\.locale) private var locale

    private var title: Text {
        if showsRecipe {
            return Text(timer.recipeName)
        }
        if let stepNumber = timer.stepNumber {
            return Text("Step \(stepNumber)")
        }
        return Text("Timer")
    }

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Button(action: onSelect) {
                HStack(spacing: Spacing.small) {
                    CookingTimerRing(timer: timer)
                    VStack(alignment: .leading, spacing: 0) {
                        timeText
                            .font(.title3.weight(.semibold).monospacedDigit())
                            .contentTransition(.numericText(countsDown: true))
                        title
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint(Text("Shows the step"))

            if timer.isFinished {
                Button {
                    store.remove(timer.id)
                } label: {
                    Label("Stop", systemImage: MySymbols.timerRemove)
                        .labelStyle(.iconOnly)
                        .frame(width: Sizes.minimumHitTarget, height: Sizes.minimumHitTarget)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .macHelp("Stop")
            } else {
                pauseButton
                Button {
                    store.remove(timer.id)
                } label: {
                    Label("Remove timer", systemImage: MySymbols.timerRemove)
                        .labelStyle(.iconOnly)
                        .frame(width: Sizes.minimumHitTarget, height: Sizes.minimumHitTarget)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .macHelp("Remove timer")
            }
        }
        .padding(.leading, Spacing.medium)
        .padding(.trailing, Spacing.xxSmall)
        .padding(.vertical, Spacing.xxSmall)
        .glassEffect(
            timer.isFinished ? .regular.tint(Color(.GrocyColors.grocyRed).opacity(0.35)).interactive() : .regular.interactive(),
            in: .capsule
        )
    }

    @ViewBuilder
    private var timeText: some View {
        switch timer.state {
        case .running(let endDate):
            Text(timerInterval: min(Date.now, endDate)...endDate, countsDown: true)
        case .paused(let remaining):
            Text(Self.format(remaining, locale: locale))
        case .finished:
            Text("Done")
        }
    }

    private var isPaused: Bool {
        if case .paused = timer.state { return true }
        return false
    }

    private var pauseButton: some View {
        Button {
            if isPaused {
                store.resume(timer.id)
            } else {
                store.pause(timer.id)
            }
        } label: {
            if isPaused {
                Label("Resume", systemImage: MySymbols.timerResume)
                    .labelStyle(.iconOnly)
                    .frame(width: Sizes.minimumHitTarget, height: Sizes.minimumHitTarget)
                    .contentShape(.circle)
            } else {
                Label("Pause", systemImage: MySymbols.timerPause)
                    .labelStyle(.iconOnly)
                    .frame(width: Sizes.minimumHitTarget, height: Sizes.minimumHitTarget)
                    .contentShape(.circle)
            }
        }
        .buttonStyle(.plain)
        .contentTransition(.symbolEffect(.replace))
        .macHelp(isPaused ? "Resume" : "Pause")
    }

    static func format(_ seconds: TimeInterval, locale: Locale) -> String {
        let duration = Duration.seconds(seconds.rounded(.up))
        if seconds >= 3600 {
            return duration.formatted(.time(pattern: .hourMinuteSecond).locale(locale))
        }
        return duration.formatted(.time(pattern: .minuteSecond).locale(locale))
    }
}

/// How much of a timer is left, as a ring that empties.
private struct CookingTimerRing: View {
    var timer: CookingTimer

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let fraction = timer.duration > 0 ? timer.remaining(at: context.date) / timer.duration : 0
            ZStack {
                Circle()
                    .stroke(.tint.opacity(0.2), lineWidth: Sizes.cookingTimerRingLineWidth)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(.tint, style: StrokeStyle(lineWidth: Sizes.cookingTimerRingLineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: fraction)
                if timer.isFinished {
                    Image(systemName: MySymbols.timerDone)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(.GrocyColors.grocyRed))
                        .symbolEffect(.wiggle, options: .repeat(.periodic(delay: 1)))
                } else if case .paused = timer.state {
                    Image(systemName: MySymbols.timerPause)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.tint)
                }
            }
            .frame(width: Sizes.cookingTimerRing, height: Sizes.cookingTimerRing)
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack {
        Spacer()
        CookingTimersBar(recipeID: 1)
    }
    .task {
        await CookingTimerStore.shared.start(duration: 300, recipeID: 1, recipeName: "Lasagne", stepNumber: 2)
    }
}
