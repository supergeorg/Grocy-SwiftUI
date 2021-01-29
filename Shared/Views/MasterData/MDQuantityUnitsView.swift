//
//  MDQuantityUnitsView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI

struct MDQuantityUnitRowView: View {
    var quantityUnit: MDQuantityUnit
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(quantityUnit.name) (\(quantityUnit.namePlural))")
                .font(.largeTitle)
            if quantityUnit.mdQuantityUnitDescription != nil {
                if !quantityUnit.mdQuantityUnitDescription!.isEmpty {
                    Text(quantityUnit.mdQuantityUnitDescription!)
                        .font(.caption)
                }
            }
        }
        .padding(10)
        .multilineTextAlignment(.leading)
    }
}

struct MDQuantityUnitsView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isSearching: Bool = false
    @State private var searchString: String = ""
    @State private var showAddQuantityUnit: Bool = false
    
    @State private var shownEditPopover: MDQuantityUnit? = nil
    
    @State private var reloadRotationDeg: Double = 0
    
    @State private var quantityUnitToDelete: MDQuantityUnit? = nil
    @State private var showDeleteAlert: Bool = false
    
    private func updateData() {
        grocyVM.getMDQuantityUnits()
    }
    
    private var filteredQuantityUnits: MDQuantityUnits {
        grocyVM.mdQuantityUnits
            .filter {
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            }
            .sorted {
                $0.name < $1.name
            }
    }
    
    private func delete(at offsets: IndexSet) {
        for offset in offsets {
            quantityUnitToDelete = filteredQuantityUnits[offset]
            showDeleteAlert.toggle()
        }
    }
    private func deleteQuantityUnit(toDelID: String) {
        grocyVM.deleteMDObject(object: .quantity_units, id: toDelID)
        updateData()
    }
    
    var body: some View {
        #if os(macOS)
        NavigationView {
            content
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        HStack{
                            if isSearching { SearchBarSwiftUI(text: $searchString, placeholder: "str.md.search") }
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
                            Button(action: {
                                showAddQuantityUnit.toggle()
                            }, label: {Image(systemName: "plus")})
                            .popover(isPresented: self.$showAddQuantityUnit, content: {
                                MDQuantityUnitFormView(isNewQuantityUnit: true)
                                    .padding()
                                    .frame(maxWidth: 300, maxHeight: 250)
                            })
                        }
                    }
                }
        }
        .navigationTitle(LocalizedStringKey("str.md.quantityUnits"))
        #elseif os(iOS)
        content
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack{
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
                        Button(action: {
                            showAddQuantityUnit.toggle()
                        }, label: {Image(systemName: "plus")})
                        .sheet(isPresented: self.$showAddQuantityUnit, content: {
                                NavigationView {
                                    MDQuantityUnitFormView(isNewQuantityUnit: true)
                                } })
                    }
                }
            }
            .animation(.default)
            .navigationTitle(LocalizedStringKey("str.md.quantityUnits"))
        #endif
    }
    
    var content: some View {
        List(){
            #if os(iOS)
            if isSearching { SearchBar(text: $searchString, placeholder: "str.md.search") }
            #endif
            if grocyVM.mdQuantityUnits.isEmpty {
                Text(LocalizedStringKey("str.md.quantityUnits.empty"))
            } else if filteredQuantityUnits.isEmpty {
                Text(LocalizedStringKey("str.noSearchResult"))
            }
            ForEach(filteredQuantityUnits, id:\.id) { quantityUnit in
                NavigationLink(destination: MDQuantityUnitFormView(isNewQuantityUnit: false, quantityUnit: quantityUnit)) {
                    MDQuantityUnitRowView(quantityUnit: quantityUnit)
                }
            }
            .onDelete(perform: delete)
        }
        .onAppear(perform: updateData)
        .alert(isPresented: $showDeleteAlert) {
            Alert(title: Text(LocalizedStringKey("str.md.quantityUnit.delete.confirm")),
                  message: Text(quantityUnitToDelete?.name ?? "error"),
                  primaryButton: .destructive(Text(LocalizedStringKey("str.delete")))
                    {
                        deleteQuantityUnit(toDelID: quantityUnitToDelete?.id ?? "")
                    },
                  secondaryButton: .cancel())
        }
    }
}

struct MDQuantityUnitsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MDQuantityUnitRowView(quantityUnit: MDQuantityUnit(id: "", name: "QU NAME", mdQuantityUnitDescription: "Description", rowCreatedTimestamp: "", namePlural: "QU NAME PLURAL", pluralForms: nil, userfields: nil))
            #if os(macOS)
            MDQuantityUnitsView()
            #else
            NavigationView() {
                MDQuantityUnitsView()
            }
            #endif
        }
    }
}
