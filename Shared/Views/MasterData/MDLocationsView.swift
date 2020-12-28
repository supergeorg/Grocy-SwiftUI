//
//  MDLocationsView.swift
//  grocy-ios
//
//  Created by Georg Meissner on 13.10.20.
//

import SwiftUI

struct MDLocationRowView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    var location: MDLocation
    
    var body: some View {
        HStack{
            if let uf = location.userfields?.first(where: {$0.key == AppSpecificUserFields.locationPicture.rawValue }) {
                if let pictureURL = grocyVM.getPictureURL(groupName: "userfiles", fileName: uf.value) {
                    RemoteImageView(withURL: pictureURL)
                        .frame(width: 100, height: 100)
                }
            }
            VStack(alignment: .leading) {
                HStack{
                    Text(location.name)
                        .font(.largeTitle)
                    if Bool(location.isFreezer) ?? false {
                        Image(systemName: "thermometer.snowflake")
                            .font(.title)
                    }
                }
                if location.mdLocationDescription != nil {
                    if !location.mdLocationDescription!.isEmpty {
                        Text(location.mdLocationDescription!)
                            .font(.caption)
                    }
                }
            }
            .padding(10)
            .multilineTextAlignment(.leading)
        }
    }
}

struct MDLocationsView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isSearching: Bool = false
    @State private var searchString: String = ""
    @State private var showAddLocation: Bool = false
    
    @State private var shownEditPopover: MDLocation? = nil
    
    @State private var reloadRotationDeg: Double = 0
    
    func makeIsPresented(location: MDLocation) -> Binding<Bool> {
        return .init(get: {
            return self.shownEditPopover?.id == location.id
        }, set: { _ in    })
    }
    
    private var filteredLocations: MDLocations {
        grocyVM.mdLocations
            .filter {
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            }
            .sorted {
                $0.name < $1.name
            }
    }
    
    var body: some View {
        List(){
            #if os(iOS)
            if isSearching { SearchBar(text: $searchString, placeholder: "str.md.search") }
            #endif
            if grocyVM.mdLocations.isEmpty {
                Text(LocalizedStringKey("str.md.empty \("str.md.locations".localized)"))
            } else if filteredLocations.isEmpty {
                Text(LocalizedStringKey("str.noSearchResult"))
            }
            #if os(macOS)
            ForEach(filteredLocations, id:\.id) {location in
                MDLocationRowView(location: location)
                    .onTapGesture {
                        shownEditPopover = location
                    }
                    .popover(isPresented: makeIsPresented(location: location), arrowEdge: .trailing, content: {
                        MDLocationFormView(isNewLocation: false, location: location)
                            .padding()
                            .frame(maxWidth: 300, maxHeight: 250)
                    })
            }
            #else
            ForEach(filteredLocations, id:\.id) {location in
                NavigationLink(destination: MDLocationFormView(isNewLocation: false, location: location)) {
                    MDLocationRowView(location: location)
                }
            }
            #endif
        }
        .animation(.default)
        .navigationTitle(LocalizedStringKey("str.md.locations"))
        .onAppear(perform: {
            grocyVM.getMDLocations()
        })
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack{
                    #if os(macOS)
                    if isSearching { SearchBar(text: $searchString, placeholder: "str.md.search") }
                    #endif
                    Button(action: {
                        isSearching.toggle()
                    }, label: {Image(systemName: "magnifyingglass")})
                    Button(action: {
                        withAnimation {
                            self.reloadRotationDeg += 360
                        }
                        grocyVM.getMDLocations()
                    }, label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .rotationEffect(Angle.degrees(reloadRotationDeg))
                    })
                    #if os(macOS)
                    Button(action: {
                        showAddLocation.toggle()
                    }, label: {Image(systemName: "plus")})
                    .popover(isPresented: self.$showAddLocation, content: {
                        MDLocationFormView(isNewLocation: true)
                            .padding()
                            .frame(maxWidth: 300, maxHeight: 250)
                    })
                    #else
                    Button(action: {
                        showAddLocation.toggle()
                    }, label: {Image(systemName: "plus")})
                    .sheet(isPresented: self.$showAddLocation, content: {
                            NavigationView {
                                MDLocationFormView(isNewLocation: true)
                            } })
                    #endif
                }
            }
        }
    }
}

struct MDLocationsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MDLocationRowView(location: MDLocation(id: "0", name: "Location", mdLocationDescription: "Location description", rowCreatedTimestamp: "", isFreezer: "0", userfields: nil))
            #if os(macOS)
            MDLocationsView()
            #else
            NavigationView() {
                MDLocationsView()
            }
            #endif
        }
    }
}
