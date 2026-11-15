//
//  Grocy_WidgetBundle.swift
//  Grocy Widget
//
//  Created by Georg Meißner on 06.12.25.
//

import SwiftUI
import WidgetKit

@main
struct Grocy_WidgetBundle: WidgetBundle {
    var body: some Widget {
        Grocy_Widget()
        ShoppingListWidget()
        ChoresWidget()
        TasksWidget()
    }
}
