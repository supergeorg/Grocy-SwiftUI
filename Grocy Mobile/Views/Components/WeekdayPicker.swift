//
//  WeekdayPicker.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 10.12.25.
//
import SwiftUI

enum Weekday: Int, CaseIterable, Identifiable {
    case monday = 1
    case tuesday, wednesday, thursday, friday, saturday, sunday

    var id: Int { rawValue }

    var localizedName: LocalizedStringKey {
        switch self {
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        case .sunday: return "Sunday"
        }
    }

    var rawStringValue: String {
        switch self {
        case .monday: return "monday"
        case .tuesday: return "tuesday"
        case .wednesday: return "wednesday"
        case .thursday: return "thursday"
        case .friday: return "friday"
        case .saturday: return "saturday"
        case .sunday: return "sunday"
        }
    }
}

struct WeekdayPicker: View {
    @Binding var selection: String?

    private var selectedWeekdays: Set<Weekday> {
        guard let selection else { return [] }
        let components = selection.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        return Set(Weekday.allCases.filter { components.contains($0.rawStringValue) })
    }

    private func toggleWeekday(_ weekday: Weekday) {
        var selected = selectedWeekdays
        if selected.contains(weekday) {
            selected.remove(weekday)
        } else {
            selected.insert(weekday)
        }

        selection =
            selected
            .sorted { $0.rawValue < $1.rawValue }
            .map { $0.rawStringValue }
            .joined(separator: ",")
    }

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(Weekday.allCases) { weekday in
                WeekdaySelectButton(
                    weekday: weekday,
                    isSelected: selectedWeekdays.contains(weekday)
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        toggleWeekday(weekday)
                    }
                }
            }
        }
    }
}

struct WeekdaySelectButton: View {
    let weekday: Weekday
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        // A real button (not a tap gesture), so VoiceOver announces it, with the selection as a trait.
        let button = Button(action: action) {
            Text(weekday.localizedName)
                .font(.subheadline.weight(.medium))
                .fontDesign(.rounded)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])

        if isSelected {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.glass)
        }
    }
}

#Preview {
    @Previewable @State var weekdays: String? = "monday,friday"

    Form {
        Text(weekdays ?? "")
        WeekdayPicker(selection: $weekdays)
    }
}
