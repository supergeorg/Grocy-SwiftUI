//
//  MDLocationsView.swift
//  grocy-ios
//
//  Created by Georg Meissner on 13.10.20.
//

import SwiftUI
import URLImage

struct MDLocationRowView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    var location: MDLocation
    
    var body: some View {
        HStack{
            //            if let uf = location.userfields?.first(where: {$0.key == AppSpecificUserFields.locationPicture.rawValue }) {
            //                if let pictureURL = grocyVM.getPictureURL(groupName: "userfiles", fileName: uf.value) {
            //                    if let url = URL(string: pictureURL) {
            //                        URLImage(url: url) { image in
            //                            image
            //                                .resizable()
            //                                .aspectRatio(contentMode: .fit)
            //                                .background(Color.white)
            //                        }
            //                        .frame(width: 100, height: 100)
            //                    }
            //                }
            //            }
            VStack(alignment: .leading) {
                HStack{
                    Text(location.name)
                        .font(.largeTitle)
                    if location.isFreezer {// == 1 {
                        Image(systemName: "thermometer.snowflake")
                            .font(.title)
                    }
                }
                if let description = location.mdLocationDescription, !description.isEmpty {
                    Text(location.mdLocationDescription!)
                        .font(.caption)
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
    
    @State private var locationToDelete: MDLocation? = nil
    @State private var showDeleteAlert: Bool = false
    
    @State private var toastType: MDToastType?
    
    private let dataToUpdate: [ObjectEntities] = [.locations]
    
    private func updateData() {
        grocyVM.requestData(objects: dataToUpdate)
    }
    
    private var filteredLocations: MDLocations {
        grocyVM.mdLocations
            .filter {
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            }
    }
    
    private func delete(at offsets: IndexSet) {
        for offset in offsets {
            locationToDelete = filteredLocations[offset]
            showDeleteAlert.toggle()
        }
    }
    private func deleteLocation(toDelID: Int) {
        grocyVM.deleteMDObject(object: .locations, id: toDelID, completion: { result in
            switch result {
            case let .success(message):
                print("Deleting location successful. \(message)")
                updateData()
            case let .failure(error):
                print("Deleting location failed. \(error)")
                toastType = .failDelete
            }
        })
    }
    
    var body: some View {
        if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count == 0 {
            bodyContent
        } else {
            ServerOfflineView()
                .navigationTitle(LocalizedStringKey("str.md.locations"))
        }
    }
    
    #if os(macOS)
    var bodyContent: some View {
        NavigationView{
            content
                .toolbar(content: {
                    ToolbarItem(placement: .primaryAction, content: {
                        HStack{
                            Button(action: {
                                withAnimation {
                                    self.reloadRotationDeg += 360
                                }
                                updateData()
                            }, label: {
                                Image(systemName: MySymbols.reload)
                                    .rotationEffect(Angle.degrees(reloadRotationDeg))
                            })
                            Button(action: {
                                showAddLocation.toggle()
                            }, label: {Image(systemName: MySymbols.new)})
                        }
                    })
                    ToolbarItem(placement: .automatic, content: {
                        ToolbarSearchField(searchTerm: $searchString)
                    })
                })
                .frame(minWidth: Constants.macOSNavWidth)
        }
        .navigationTitle(LocalizedStringKey("str.md.locations"))
    }
    #elseif os(iOS)
    var bodyContent: some View {
        content
            .toolbar(content: {
                ToolbarItem(placement: .primaryAction) {
                    HStack{
                        Button(action: {
                            isSearching.toggle()
                        }, label: {Image(systemName: MySymbols.search)})
                        Button(action: {
                            withAnimation {
                                self.reloadRotationDeg += 360
                            }
                            updateData()
                        }, label: {
                            Image(systemName: MySymbols.reload)
                                .rotationEffect(Angle.degrees(reloadRotationDeg))
                        })
                        Button(action: {
                            showAddLocation.toggle()
                        }, label: {Image(systemName: MySymbols.new)})
                    }
                }
            })
            .navigationTitle(LocalizedStringKey("str.md.locations"))
            .sheet(isPresented: self.$showAddLocation, content: {
                    NavigationView {
                        MDLocationFormView(isNewLocation: true, showAddLocation: $showAddLocation, toastType: $toastType)
                    } })
    }
    #endif
    
    var content: some View {
        List(){
            #if os(iOS)
            if isSearching { SearchBar(text: $searchString, placeholder: "str.md.search") }
            #endif
            if grocyVM.mdLocations.isEmpty {
                Text(LocalizedStringKey("str.md.locations.empty"))
            } else if filteredLocations.isEmpty {
                Text(LocalizedStringKey("str.noSearchResult"))
            }
            #if os(macOS)
            if showAddLocation {
                NavigationLink(destination: MDLocationFormView(isNewLocation: true, showAddLocation: $showAddLocation, toastType: $toastType), isActive: $showAddLocation, label: {
                    NewMDRowLabel(title: "str.md.location.new")
                })
            }
            #endif
            ForEach(filteredLocations, id:\.id) {location in
                NavigationLink(destination: MDLocationFormView(isNewLocation: false, location: location, showAddLocation: Binding.constant(false), toastType: $toastType)) {
                    MDLocationRowView(location: location)
                }
            }
            .onDelete(perform: delete)
        }
        .onAppear(perform: { grocyVM.requestData(objects: dataToUpdate, ignoreCached: false) })
        .animation(.default, value: filteredLocations.count)
        .toast(item: $toastType, isSuccess: Binding.constant(toastType == .successAdd || toastType == .successEdit), content: { item in
            switch item {
            case .successAdd:
                Label(LocalizedStringKey("str.md.new.success"), systemImage: MySymbols.success)
            case .failAdd:
                Label(LocalizedStringKey("str.md.new.fail"), systemImage: MySymbols.failure)
            case .successEdit:
                Label(LocalizedStringKey("str.md.edit.success"), systemImage: MySymbols.success)
            case .failEdit:
                Label(LocalizedStringKey("str.md.edit.fail"), systemImage: MySymbols.failure)
            case .failDelete:
                Label(LocalizedStringKey("str.md.delete.fail"), systemImage: MySymbols.failure)
            }
        })
        .alert(isPresented: $showDeleteAlert) {
            Alert(title: Text("str.md.location.delete.confirm"), message: Text(locationToDelete?.name ?? "error"), primaryButton: .destructive(Text("str.delete")) {
                if let toDelID = locationToDelete?.id {
                    deleteLocation(toDelID: toDelID)
                }
            }, secondaryButton: .cancel())
        }
    }
}

struct MDLocationsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MDLocationRowView(location: MDLocation(id: 0, name: "Location", mdLocationDescription: "Location description", rowCreatedTimestamp: "", isFreezer: true))
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
