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
    
    func makeIsPresented(quantityUnit: MDQuantityUnit) -> Binding<Bool> {
        return .init(get: {
            return self.shownEditPopover?.id == quantityUnit.id
        }, set: { _ in    })
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
    
    var body: some View {
        List(){
            #if os(iOS)
            if isSearching { SearchBar(text: $searchString, placeholder: "str.md.search") }
            #endif
            if grocyVM.mdQuantityUnits.isEmpty {
                Text("str.md.empty \("str.md.quantityUnits".localized)")
            } else if filteredQuantityUnits.isEmpty {
                Text("str.noSearchResult")
            }
            #if os(macOS)
            ForEach(filteredQuantityUnits, id:\.id) { quantityUnit in
                MDQuantityUnitRowView(quantityUnit: quantityUnit)
                    .onTapGesture {
                        shownEditPopover = quantityUnit
                    }
                    .popover(isPresented: makeIsPresented(quantityUnit: quantityUnit), arrowEdge: .trailing, content: {
                        MDQuantityUnitFormView(isNewQuantityUnit: false, quantityUnit: quantityUnit)
                            .padding()
                            .frame(maxWidth: 300, maxHeight: 250)
                    })
            }
            #else
            //            ForEach(filteredQuantityUnits, id:\.id) { quantityUnit in
            //                NavigationLink(destination: MDQuantityUnitFormView(isNewQuantityUnit: false, quantityUnit: quantityUnit)) {
            //                    MDQuantityUnitRowView(quantityUnit: quantityUnit)
            //                }
            //            }
            #endif
        }
        .animation(.default)
        .navigationTitle("str.md.quantityUnits".localized)
        .onAppear(perform: {
            grocyVM.getMDQuantityUnits()
        })
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack{
                    #if os(macOS)
                    if isSearching { SearchBar(text: $searchString, placeholder: "str.md.search".localized) }
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
                        showAddQuantityUnit.toggle()
                    }, label: {Image(systemName: "plus")})
                    .popover(isPresented: self.$showAddQuantityUnit, content: {
                        MDQuantityUnitFormView(isNewQuantityUnit: true)
                            .padding()
                            .frame(maxWidth: 300, maxHeight: 250)
                    })
                    #else
                    Button(action: {
                        showAddQuantityUnit.toggle()
                    }, label: {Image(systemName: "plus")})
                    .sheet(isPresented: self.$showAddQuantityUnit, content: {
                            NavigationView {
                                MDQuantityUnitFormView(isNewQuantityUnit: true)
                            } })
                    #endif
                }
            }
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
