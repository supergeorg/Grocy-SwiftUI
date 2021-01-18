//
//  MDShoppingLocationsView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI
import URLImage

struct MDShoppingLocationRowView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    var shoppingLocation: MDShoppingLocation
    
    var body: some View {
        HStack{
            if let uf = shoppingLocation.userfields?.first(where: {$0.key == AppSpecificUserFields.storeLogo.rawValue }) {
                if let pictureURL = grocyVM.getPictureURL(groupName: "userfiles", fileName: uf.value) {
                    if let url = URL(string: pictureURL) {
                        URLImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .background(Color.white)
                        }
                        .frame(width: 100, height: 100)
                    }
                }
            }
            VStack(alignment: .leading) {
                Text(shoppingLocation.name)
                    .font(.largeTitle)
                if shoppingLocation.mdShoppingLocationDescription != nil {
                    if !shoppingLocation.mdShoppingLocationDescription!.isEmpty {
                        Text(shoppingLocation.mdShoppingLocationDescription!)
                            .font(.caption)
                    }
                }
            }
            .padding(10)
            .multilineTextAlignment(.leading)
        }
    }
}

struct MDShoppingLocationsView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isSearching: Bool = false
    @State private var searchString: String = ""
    @State private var showAddShoppingLocation: Bool = false
    
    @State private var shownEditPopover: MDShoppingLocation? = nil
    
    @State private var reloadRotationDeg: Double = 0
    
    @State private var shoppingLocationToDelete: MDShoppingLocation? = nil
    @State private var showDeleteAlert: Bool = false
    
    private var filteredShoppingLocations: MDShoppingLocations {
        grocyVM.mdShoppingLocations
            .filter {
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            }
            .sorted {
                $0.name < $1.name
            }
    }
    
    private func delete(at offsets: IndexSet) {
        for offset in offsets {
            shoppingLocationToDelete = filteredShoppingLocations[offset]
            showDeleteAlert.toggle()
        }
    }
    private func deleteShoppingLocation(toDelID: String) {
        grocyVM.deleteMDObject(object: .shopping_locations, id: toDelID)
        updateData()
    }
    
    private func updateData() {
        grocyVM.getMDShoppingLocations()
    }
    
    var body: some View {
        #if os(macOS)
        NavigationView{
            content
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        HStack{
                            if isSearching { SearchBar(text: $searchString, placeholder: "str.md.search".localized) }
                            Button(action: {
                                isSearching.toggle()
                            }, label: {Image(systemName: "magnifyingglass")})
                            Button(action: {
                                withAnimation {
                                    self.reloadRotationDeg += 360
                                }
                                updateData()
                            }, label: {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .rotationEffect(Angle.degrees(reloadRotationDeg))
                            })
                            Button(action: {
                                showAddShoppingLocation.toggle()
                            }, label: {Image(systemName: "plus")})
                            .popover(isPresented: self.$showAddShoppingLocation, content: {
                                MDShoppingLocationFormView(isNewShoppingLocation: true)
                                    .padding()
                                    .frame(maxWidth: 300, maxHeight: 250)
                            })
                        }
                    }
                }
        }
        #elseif os(iOS)
        content
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack{
                        Button(action: {
                            isSearching.toggle()
                        }, label: {Image(systemName: "magnifyingglass")})
                        Button(action: {
                            updateData()
                        }, label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        })
                        Button(action: {
                            showAddShoppingLocation.toggle()
                        }, label: {Image(systemName: "plus")})
                        .sheet(isPresented: self.$showAddShoppingLocation, content: {
                                NavigationView {
                                    MDShoppingLocationFormView(isNewShoppingLocation: true)
                                } })
                    }
                }
            }
            .animation(.default)
        #endif
    }
    
    var content: some View {
        List(){
            #if os(iOS)
            if isSearching { SearchBar(text: $searchString, placeholder: "str.md.search") }
            #endif
            if grocyVM.mdShoppingLocations.isEmpty {
                Text(LocalizedStringKey("str.md.empty \("str.md.shoppingLocations".localized)"))
            } else if filteredShoppingLocations.isEmpty {
                Text(LocalizedStringKey("str.noSearchResult"))
            }
            ForEach(filteredShoppingLocations, id:\.id) { shoppingLocation in
                NavigationLink(destination: MDShoppingLocationFormView(isNewShoppingLocation: false, shoppingLocation: shoppingLocation)) {
                    MDShoppingLocationRowView(shoppingLocation: shoppingLocation)
                }
            }
            .onDelete(perform: delete)
        }
        .navigationTitle(LocalizedStringKey("str.md.shoppingLocations"))
        .onAppear(perform: {
            updateData()
        })
        .alert(isPresented: $showDeleteAlert) {
            Alert(title: Text(LocalizedStringKey("str.md.shoppingLocation.delete.confirm")),
                  message: Text(shoppingLocationToDelete?.name ?? "error"),
                  primaryButton: .destructive(Text(LocalizedStringKey("str.delete")))
                    {
                        deleteShoppingLocation(toDelID: shoppingLocationToDelete?.id ?? "")
                    },
                  secondaryButton: .cancel())
        }
    }
}

struct MDShoppingLocationsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MDShoppingLocationRowView(shoppingLocation: MDShoppingLocation(id: "0", name: "Location", mdShoppingLocationDescription: "Description", rowCreatedTimestamp: "", userfields: nil))
            #if os(macOS)
            MDShoppingLocationsView()
            #else
            NavigationView() {
                MDShoppingLocationsView()
            }
            #endif
        }
    }
}
