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
            if let description = quantityUnit.mdQuantityUnitDescription, !description.isEmpty {
                Text(quantityUnit.mdQuantityUnitDescription!)
                    .font(.caption)
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
    
    @State private var toastType: MDToastType?
    
    private let dataToUpdate: [ObjectEntities] = [.quantity_units]
    
    private func updateData() {
        grocyVM.requestData(objects: dataToUpdate)
    }
    
    private var filteredQuantityUnits: MDQuantityUnits {
        grocyVM.mdQuantityUnits
            .filter {
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            }
    }
    
    private func delete(at offsets: IndexSet) {
        for offset in offsets {
            quantityUnitToDelete = filteredQuantityUnits[offset]
            showDeleteAlert.toggle()
        }
    }
    private func deleteQuantityUnit(toDelID: Int) {
        grocyVM.deleteMDObject(object: .quantity_units, id: toDelID, completion: { result in
            switch result {
            case let .success(message):
                print(message)
                updateData()
            case let .failure(error):
                print("\(error)")
                toastType = .failDelete
            }
        })
    }
    
    var body: some View {
        if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count == 0 {
            bodyContent
        } else {
            ServerOfflineView()
                .navigationTitle(LocalizedStringKey("str.md.quantityUnits"))
        }
    }
    
    #if os(macOS)
    var bodyContent: some View {
        NavigationView {
            content
                .toolbar(content: {
                    ToolbarItem(placement: .primaryAction, content: {
                        HStack{
                            if isSearching { SearchBarSwiftUI(text: $searchString, placeholder: "str.md.search") }
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
                                showAddQuantityUnit.toggle()
                            }, label: {Image(systemName: MySymbols.new)})
                        }
                    })
                    ToolbarItem(placement: .automatic, content: {
                        ToolbarSearchField(searchTerm: $searchString)
                    })
                })
                .frame(minWidth: Constants.macOSNavWidth)
        }
        .navigationTitle(LocalizedStringKey("str.md.quantityUnits"))
    }
    #elseif os(iOS)
    var bodyContent: some View {
        content
            .toolbar {
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
                            showAddQuantityUnit.toggle()
                        }, label: {Image(systemName: MySymbols.new)})
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("str.md.quantityUnits"))
            .sheet(isPresented: self.$showAddQuantityUnit, content: {
                    NavigationView {
                        MDQuantityUnitFormView(isNewQuantityUnit: true, showAddQuantityUnit: $showAddQuantityUnit, toastType: $toastType)
                    } })
    }
    #endif
    
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
            #if os(macOS)
            if showAddQuantityUnit {
                NavigationLink(destination: MDQuantityUnitFormView(isNewQuantityUnit: true, showAddQuantityUnit: $showAddQuantityUnit, toastType: $toastType), isActive: $showAddQuantityUnit, label: {
                    NewMDRowLabel(title: "str.md.quantityUnit.new")
                })
            }
            #endif
            ForEach(filteredQuantityUnits, id:\.id) { quantityUnit in
                NavigationLink(destination: MDQuantityUnitFormView(isNewQuantityUnit: false, quantityUnit: quantityUnit, showAddQuantityUnit: Binding.constant(false), toastType: $toastType)) {
                    MDQuantityUnitRowView(quantityUnit: quantityUnit)
                }
            }
            .onDelete(perform: delete)
        }
        .onAppear(perform: { grocyVM.requestData(objects: dataToUpdate, ignoreCached: false) })
        .animation(.default, value: filteredQuantityUnits.count)
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
            Alert(title: Text(LocalizedStringKey("str.md.quantityUnit.delete.confirm")),
                  message: Text(quantityUnitToDelete?.name ?? "error"),
                  primaryButton: .destructive(Text(LocalizedStringKey("str.delete")))
                  {
                    if let toDelID = quantityUnitToDelete?.id {
                        deleteQuantityUnit(toDelID: toDelID)
                    }
                  },
                  secondaryButton: .cancel())
        }
    }
}

struct MDQuantityUnitsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MDQuantityUnitRowView(quantityUnit: MDQuantityUnit(id: 0, name: "QU NAME", namePlural: "QU NAME PLURAL", mdQuantityUnitDescription: "Description", rowCreatedTimestamp: ""))
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
