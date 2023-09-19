//
//  RemindersSync.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 22.11.22.
//

// This is the example from Apple (https://developer.apple.com/tutorials/app-dev-training/saving-reminders)

//Copyright © 2022 Apple Inc.
//
//Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


import Foundation
import EventKit
import SwiftUI

enum TodayError: LocalizedError {
    case accessDenied
    case accessRestricted
    case failedReadingCalendarItem
    case failedReadingReminders
    case reminderHasNoDueDate
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return NSLocalizedString("The app doesn't have permission to read reminders.", comment: "access denied error description")
        case .accessRestricted:
            return NSLocalizedString("This device doesn't allow access to reminders.", comment: "access restricted error description")
        case .failedReadingCalendarItem:
            return NSLocalizedString("Failed to read a calendar item.", comment: "failed reading calendar item error description")
        case .failedReadingReminders:
            return NSLocalizedString("Failed to read reminders.", comment: "failed reading reminders error description")
        case .reminderHasNoDueDate:
            return NSLocalizedString("A reminder has no due date.", comment: "reminder has no due date error description")
        case .unknown:
            return NSLocalizedString("An unknown error occurred.", comment: "unknown error description")
        }
    }
}

extension EKEventStore {
    func fetchReminders(matching predicate: NSPredicate) async throws -> [EKReminder] {
        try await withCheckedThrowingContinuation { continuation in
            fetchReminders(matching: predicate) { reminders in
                if let reminders = reminders {
                    continuation.resume(returning: reminders)
                } else {
                    continuation.resume(throwing: TodayError.failedReadingReminders)
                }
            }
        }
    }
}

extension EKReminder {
    func update(using reminder: Reminder, in store: EKEventStore) {
        title = reminder.title
        notes = reminder.notes
        isCompleted = reminder.isComplete
        calendar = store.defaultCalendarForNewReminders()
        if let dueDate = reminder.dueDate {
            alarms?.forEach { alarm in
                guard let absoluteDate = alarm.absoluteDate else { return }
                let comparison = Locale.current.calendar.compare(dueDate, to: absoluteDate, toGranularity: .minute)
                if comparison != .orderedSame {
                    removeAlarm(alarm)
                }
            }
            if !hasAlarms {
                addAlarm(EKAlarm(absoluteDate: dueDate))
            }
        }
    }
}

struct Reminder: Equatable, Identifiable {
    var id: String = UUID().uuidString
    var title: String
    var dueDate: Date? = nil
    var notes: String? = nil
    var isComplete: Bool = false
}

extension Reminder {
    init(with ekReminder: EKReminder) throws {
        id = ekReminder.calendarItemIdentifier
        title = ekReminder.title
        dueDate = ekReminder.alarms?.first?.absoluteDate
        notes = ekReminder.notes
        isComplete = ekReminder.isCompleted
    }
}

extension Array where Element == Reminder {
    func indexOfReminder(with id: Reminder.ID) -> Self.Index {
        guard let index = firstIndex(where: { $0.id == id }) else {
            fatalError()
        }
        return index
    }
}


class ReminderStore {
    static let shared = ReminderStore()
    
    @AppStorage("calendarIdentifier") private var calendarIdentifier: String = ""
    
    private let ekStore = EKEventStore()
    
    private var ekCalendar: EKCalendar? = nil
    
    @Published var isAvailable_: Bool = false
    
    var isAvailable: Bool {
        EKEventStore.authorizationStatus(for: .reminder) == .fullAccess && isCalendarSelected
    }
    
    private var isCalendarSelected: Bool = false
    
    func requestAccess() async throws {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        
        switch status {
        case .authorized:
            return
        case .restricted:
            throw TodayError.accessRestricted
        case .notDetermined:
            let accessGranted = try await ekStore.requestFullAccessToReminders()
            guard accessGranted else {
                throw TodayError.accessDenied
            }
        case .denied:
            throw TodayError.accessDenied
        case .fullAccess:
            return
        case .writeOnly:
            throw TodayError.accessDenied
        @unknown default:
            throw TodayError.unknown
        }
    }
    
    func initCalendar() {
        if let cal = ekStore.calendar(withIdentifier: calendarIdentifier) {
            ekCalendar = cal
            isCalendarSelected = true
            isAvailable_ = true
        } else {
            createCalendar()
        }
    }
    
    func bestPossibleEKSource() -> EKSource? {
        let defaultSource = ekStore.defaultCalendarForNewEvents?.source
        let iCloudSource = ekStore.sources.first(where: { $0.title == "iCloud" })
        let localSource = ekStore.sources.first(where: { $0.sourceType == .local })
        
        return defaultSource ?? iCloudSource ?? localSource
    }
    
    private func createCalendar() {
        let calendar = EKCalendar(for: .reminder, eventStore: ekStore)
        calendar.title = "Grocy Mobile"
        calendar.cgColor = Color.grocyBlue.cgColor
        guard let source = bestPossibleEKSource() else {
            return
        }
        calendar.source = source
        do {
            try ekStore.saveCalendar(calendar, commit: true)
            calendarIdentifier = calendar.calendarIdentifier
            ekCalendar = calendar
            isCalendarSelected = true
            isAvailable_ = true
        } catch {
            print(error)
        }
    }
    
    private func read(with id: Reminder.ID) throws -> EKReminder {
        guard let ekReminder = ekStore.calendarItem(withIdentifier: id) as? EKReminder else {
            throw TodayError.failedReadingCalendarItem
        }
        return ekReminder
    }
    
    func readAll() async throws -> [Reminder] {
        guard isAvailable else {
            throw TodayError.accessDenied
        }
        
        let predicate = ekStore.predicateForReminders(in: nil)
        let ekReminders = try await ekStore.fetchReminders(matching: predicate)
        let reminders: [Reminder] = try ekReminders.compactMap { ekReminder in
            do {
                return try Reminder(with: ekReminder)
            } catch TodayError.reminderHasNoDueDate {
                return nil
            }
        }
        return reminders
    }
    
    func remove(with id: Reminder.ID) throws {
        guard isAvailable else {
            throw TodayError.accessDenied
        }
        let ekReminder = try read(with: id)
        try ekStore.remove(ekReminder, commit: true)
    }
    
    @discardableResult
    func save(_ reminder: Reminder) throws -> Reminder.ID {
        guard isAvailable else {
            throw TodayError.accessDenied
        }
        let ekReminder: EKReminder
        do {
            ekReminder = try read(with: reminder.id)
        } catch {
            ekReminder = EKReminder(eventStore: ekStore)
        }
        ekReminder.update(using: reminder, in: ekStore)
        ekReminder.calendar = ekCalendar
        try ekStore.save(ekReminder, commit: true)
        return ekReminder.calendarItemIdentifier
    }
}
