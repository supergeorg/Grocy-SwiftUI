//
//  CookingTimerLiveActivity.swift
//  Grocy Widget
//
//  Created by Georg Meißner on 28.11.26.
//

#if os(iOS)
    import ActivityKit
    import AlarmKit
    import SwiftUI
    import WidgetKit

    /// A cooking timer of the cooking mode on the Lock Screen and in the Dynamic Island. The app schedules it with AlarmKit,
    /// which also alerts when it's done.
    struct CookingTimerLiveActivity: Widget {
        var body: some WidgetConfiguration {
            ActivityConfiguration(for: AlarmAttributes<CookingTimerMetadata>.self) { context in
                CookingTimerLockScreenView(attributes: context.attributes, state: context.state)
                    .activityBackgroundTint(nil)
            } dynamicIsland: { context in
                DynamicIsland {
                    DynamicIslandExpandedRegion(.leading) {
                        CookingTimerTitle(attributes: context.attributes)
                            .padding(.leading, Spacing.xxSmall)
                    }
                    DynamicIslandExpandedRegion(.trailing) {
                        CookingTimerTime(state: context.state)
                            .font(.title2.weight(.semibold).monospacedDigit())
                            .foregroundStyle(context.attributes.tintColor)
                    }
                    DynamicIslandExpandedRegion(.bottom) {
                        CookingTimerProgress(state: context.state, tint: context.attributes.tintColor)
                    }
                } compactLeading: {
                    Image(systemName: MySymbols.timer)
                        .foregroundStyle(context.attributes.tintColor)
                } compactTrailing: {
                    CookingTimerTime(state: context.state)
                        .monospacedDigit()
                        .frame(maxWidth: Sizes.cookingTimerCompactWidth)
                        .foregroundStyle(context.attributes.tintColor)
                } minimal: {
                    Image(systemName: MySymbols.timer)
                        .foregroundStyle(context.attributes.tintColor)
                }
                .keylineTint(context.attributes.tintColor)
            }
        }
    }

    private struct CookingTimerLockScreenView: View {
        var attributes: AlarmAttributes<CookingTimerMetadata>
        var state: AlarmPresentationState

        var body: some View {
            VStack(alignment: .leading, spacing: Spacing.small) {
                HStack(alignment: .firstTextBaseline) {
                    CookingTimerTitle(attributes: attributes)
                    Spacer()
                    CookingTimerTime(state: state)
                        .font(.largeTitle.weight(.semibold).monospacedDigit())
                        .foregroundStyle(attributes.tintColor)
                        .multilineTextAlignment(.trailing)
                }
                CookingTimerProgress(state: state, tint: attributes.tintColor)
            }
            .padding()
        }
    }

    private struct CookingTimerTitle: View {
        var attributes: AlarmAttributes<CookingTimerMetadata>

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Label(attributes.metadata?.recipeName ?? "", systemImage: MySymbols.timer)
                    .font(.headline)
                    .lineLimit(1)
                if let stepNumber = attributes.metadata?.stepNumber {
                    Text("Step \(stepNumber)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    /// The time left, counting down while running.
    private struct CookingTimerTime: View {
        var state: AlarmPresentationState

        var body: some View {
            switch state.mode {
            case .countdown(let countdown):
                Text(timerInterval: Date.now...max(Date.now, countdown.fireDate), countsDown: true)
            case .paused(let paused):
                Text(
                    Duration.seconds(max(paused.totalCountdownDuration - paused.previouslyElapsedDuration, 0))
                        .formatted(.time(pattern: .minuteSecond))
                )
            default:
                Text("Done")
            }
        }
    }

    private struct CookingTimerProgress: View {
        var state: AlarmPresentationState
        var tint: Color

        var body: some View {
            switch state.mode {
            case .countdown(let countdown):
                ProgressView(
                    timerInterval: countdown.startDate.addingTimeInterval(-countdown.previouslyElapsedDuration)...max(countdown.startDate, countdown.fireDate),
                    countsDown: true
                ) {
                } currentValueLabel: {
                }
                .tint(tint)
            case .paused(let paused):
                ProgressView(value: max(paused.totalCountdownDuration - paused.previouslyElapsedDuration, 0), total: max(paused.totalCountdownDuration, 1))
                    .tint(tint)
            default:
                EmptyView()
            }
        }
    }
#endif
