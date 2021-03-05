//
//  SearchBarWrapped.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 30.12.20.
//

import SwiftUI

#if os(iOS)
struct SearchBar: UIViewRepresentable {
    
    @Binding var text: String
    var placeholder: String
    
    class Coordinator: NSObject, UISearchBarDelegate {
        
        @Binding var text: String
        
        init(text: Binding<String>) {
            _text = text
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
    }
    
    func makeCoordinator() -> SearchBar.Coordinator {
        return Coordinator(text: $text)
    }
    
    func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.placeholder = placeholder.localized
        searchBar.searchBarStyle = .minimal
        searchBar.autocapitalizationType = .none
        return searchBar
    }
    
    func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
        uiView.text = text
    }
}
#elseif os(macOS)
struct SearchBar: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    
    public typealias NSViewType = NSSearchField
    
    public func makeNSView(context: Context) -> NSViewType {
        let nsView = NSSearchField(string: placeholder.localized)
        
        nsView.delegate = context.coordinator
        nsView.target = context.coordinator
        
        nsView.bezelStyle = .roundedBezel
        nsView.cell?.sendsActionOnEndEditing = false
        nsView.isBordered = true
        nsView.isBezeled = true
        
        return nsView
    }
    
    public func updateNSView(_ nsView: NSSearchField, context: Context) {
        context.coordinator.searchBar = self
        
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }
    
    final public class Coordinator: NSObject, NSSearchFieldDelegate {
        var searchBar: SearchBar
        
        init(searchBar: SearchBar) {
            self.searchBar = searchBar
        }
        
        public func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else {
                return
            }
            searchBar.text = textField.stringValue
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(searchBar: self)
    }
}
#endif

#if os(macOS)
struct ToolbarSearchFieldNS: NSViewRepresentable {

    class Coordinator: NSObject, NSSearchFieldDelegate {
        var parent: ToolbarSearchFieldNS

        init(_ parent: ToolbarSearchFieldNS) {
            self.parent = parent
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let searchField = notification.object as? NSSearchField else {
                print("Unexpected control in update notification")
                return
            }
            self.parent.search = searchField.stringValue
        }

    }

    @Binding var search: String

    func makeNSView(context: Context) -> NSSearchField {
        NSSearchField(frame: .zero)
    }

    func updateNSView(_ searchField: NSSearchField, context: Context) {
        searchField.stringValue = search
        searchField.delegate = context.coordinator
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
}

struct ToolbarSearchField: View {
    @Binding var searchTerm: String
    var body: some View {
        ToolbarSearchFieldNS(search: $searchTerm)
            .frame(minWidth: 50, idealWidth: 200, maxWidth: .infinity)
    }
}
#endif

struct SearchBar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SearchBar(text: Binding.constant("text"), placeholder: "placeholder")
                .environment(\.colorScheme, .light)
            SearchBar(text: Binding.constant("text"), placeholder: "placeholder")
                .environment(\.colorScheme, .dark)
        }
    }
}
