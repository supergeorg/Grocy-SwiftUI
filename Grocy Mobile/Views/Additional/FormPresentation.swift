//
//  FormPresentation.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 28.11.26.
//

/// How the lists open their forms for new items: on iOS as a sheet, which needs a Cancel button; on the Mac pushed onto the
/// list's navigation, where the back button closes the form, so a Cancel button would be a second way to do the same.
enum FormPresentation {
    nonisolated static let createFormIsPushed: Bool = {
        #if os(macOS)
            true
        #else
            false
        #endif
    }()
}
