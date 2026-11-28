//
//  CookingTimerStore.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 28.11.26.
//

import SwiftUI
import UserNotifications

#if os(iOS)
    import AlarmKit
#endif

/// A countdown started from a time in a cooking step.
struct CookingTimer: Identifiable, Hashable {
    enum State: Hashable {
        case running(endDate: Date)
        case paused(remaining: TimeInterval)
        case finished
    }

    let id: UUID
    var recipeID: Int
    var recipeName: String
    /// The step the time is from, starting at 1.
    var stepNumber: Int?
    var duration: TimeInterval
    var state: State

    var isFinished: Bool { state == .finished }

    /// The time left at `date`.
    func remaining(at date: Date) -> TimeInterval {
        switch state {
        case .running(let endDate): max(endDate.timeIntervalSince(date), 0)
        case .paused(let remaining): remaining
        case .finished: 0
        }
    }
}

/// The running cooking timers, shared by every cooking window. Each timer also alerts outside the app:
/// on iOS as an AlarmKit timer (Lock Screen, Dynamic Island and an alert like the Clock app's, also in Silent Mode),
/// on the Mac, or without the AlarmKit permission, as a local notification. Like the mise en place, timers aren't saved.
@Observable
final class CookingTimerStore {
    static let shared = CookingTimerStore()

    private(set) var timers: [CookingTimer] = []

    @ObservationIgnored private var finishTasks: [UUID: Task<Void, Never>] = [:]
    /// Timers that alert as an AlarmKit alarm (with the same ID); the others alert as a notification.
    @ObservationIgnored private var alarmTimerIDs: Set<UUID> = []
    @ObservationIgnored private let notificationPresenter = CookingTimerNotificationPresenter()
    #if os(iOS)
        @ObservationIgnored private var alarmUpdatesTask: Task<Void, Never>?
    #endif

    // MARK: Actions

    func start(duration: TimeInterval, recipeID: Int, recipeName: String, stepNumber: Int?) async {
        let timer = CookingTimer(
            id: UUID(),
            recipeID: recipeID,
            recipeName: recipeName,
            stepNumber: stepNumber,
            duration: duration,
            state: .running(endDate: .now.addingTimeInterval(duration))
        )
        timers.append(timer)
        scheduleFinish(of: timer.id, after: duration)
        #if os(iOS)
            if await scheduleAlarm(for: timer) {
                alarmTimerIDs.insert(timer.id)
                return
            }
        #endif
        await scheduleNotification(for: timer, after: duration)
    }

    func pause(_ id: UUID) {
        guard let index = timers.firstIndex(where: { $0.id == id }), case .running = timers[index].state else { return }
        timers[index].state = .paused(remaining: timers[index].remaining(at: .now))
        finishTasks.removeValue(forKey: id)?.cancel()
        #if os(iOS)
            if alarmTimerIDs.contains(id) {
                try? AlarmManager.shared.pause(id: id)
                return
            }
        #endif
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }

    func resume(_ id: UUID) {
        guard let index = timers.firstIndex(where: { $0.id == id }), case .paused(let remaining) = timers[index].state else { return }
        timers[index].state = .running(endDate: .now.addingTimeInterval(remaining))
        scheduleFinish(of: id, after: remaining)
        #if os(iOS)
            if alarmTimerIDs.contains(id) {
                try? AlarmManager.shared.resume(id: id)
                return
            }
        #endif
        let timer = timers[index]
        Task { await scheduleNotification(for: timer, after: remaining) }
    }

    /// Stops a timer (or its alert) and removes it.
    func remove(_ id: UUID) {
        timers.removeAll { $0.id == id }
        finishTasks.removeValue(forKey: id)?.cancel()
        #if os(iOS)
            if alarmTimerIDs.remove(id) != nil {
                try? AlarmManager.shared.cancel(id: id)
            }
        #endif
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id.uuidString])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [id.uuidString])
    }

    // MARK: Finishing

    private func scheduleFinish(of id: UUID, after seconds: TimeInterval) {
        finishTasks[id]?.cancel()
        finishTasks[id] = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            self?.finish(id)
        }
    }

    private func finish(_ id: UUID) {
        guard let index = timers.firstIndex(where: { $0.id == id }) else { return }
        timers[index].state = .finished
        finishTasks[id] = nil
        GrocyLogger.info("Cooking timer of \(timers[index].recipeName) finished.")
    }

    // MARK: Notification

    private func scheduleNotification(for timer: CookingTimer, after seconds: TimeInterval) async {
        let center = UNUserNotificationCenter.current()
        center.delegate = notificationPresenter
        do {
            guard try await center.requestAuthorization(options: [.alert, .sound]) else { return }
            let content = UNMutableNotificationContent()
            content.title = String(localized: "Timer done")
            content.body = timer.recipeName
            content.sound = .default
            content.interruptionLevel = .timeSensitive
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(seconds, 1), repeats: false)
            try await center.add(UNNotificationRequest(identifier: timer.id.uuidString, content: content, trigger: trigger))
        } catch {
            GrocyLogger.error("Scheduling the cooking timer notification failed. \(error)")
        }
    }

    // MARK: AlarmKit

    #if os(iOS)
        private func scheduleAlarm(for timer: CookingTimer) async -> Bool {
            let manager = AlarmManager.shared
            do {
                if manager.authorizationState == .notDetermined {
                    _ = try await manager.requestAuthorization()
                }
                guard manager.authorizationState == .authorized else { return false }
                let presentation = AlarmPresentation(
                    alert: AlarmPresentation.Alert(title: "Timer done"),
                    countdown: AlarmPresentation.Countdown(
                        title: "\(timer.recipeName)",
                        pauseButton: AlarmButton(text: "Pause", textColor: .white, systemImageName: MySymbols.timerPause)
                    ),
                    paused: AlarmPresentation.Paused(
                        title: "Paused",
                        resumeButton: AlarmButton(text: "Resume", textColor: .white, systemImageName: MySymbols.timerResume)
                    )
                )
                let attributes = AlarmAttributes(
                    presentation: presentation,
                    metadata: CookingTimerMetadata(recipeName: timer.recipeName, stepNumber: timer.stepNumber),
                    tintColor: Color(.GrocyColors.grocyBlue)
                )
                _ = try await manager.schedule(id: timer.id, configuration: .timer(duration: timer.duration, attributes: attributes))
                observeAlarms()
                return true
            } catch {
                GrocyLogger.error("Scheduling the cooking timer alarm failed. \(error)")
                return false
            }
        }

        /// Follows pauses, resumes and stops from the Lock Screen and Dynamic Island.
        private func observeAlarms() {
            guard alarmUpdatesTask == nil else { return }
            alarmUpdatesTask = Task { [weak self] in
                for await alarms in AlarmManager.shared.alarmUpdates {
                    self?.apply(alarms)
                }
            }
        }

        private func apply(_ alarms: [Alarm]) {
            let alarmsByID = Dictionary(alarms.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            for timer in timers where alarmTimerIDs.contains(timer.id) {
                guard let alarm = alarmsByID[timer.id] else {
                    // Stopped or cancelled outside the app.
                    alarmTimerIDs.remove(timer.id)
                    remove(timer.id)
                    continue
                }
                switch (alarm.state, timer.state) {
                case (.paused, .running):
                    pause(timer.id)
                case (.countdown, .paused):
                    resume(timer.id)
                case (.alerting, .running), (.alerting, .paused):
                    finish(timer.id)
                default:
                    break
                }
            }
        }
    #endif
}

/// Shows a cooking timer's notification also while the app is open.
private final class CookingTimerNotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
