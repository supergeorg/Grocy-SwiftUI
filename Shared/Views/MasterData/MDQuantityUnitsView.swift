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
    
    @State private var toastType: MDToastType?
    
    private func updateData() {
        grocyVM.requestData(objects: [.quantity_units])
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
        #if os(macOS)
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
                            .popover(isPresented: self.$showAddQuantityUnit, content: {
                                MDQuantityUnitFormView(isNewQuantityUnit: true, toastType: $toastType)
                            })
                        }
                    })
                    ToolbarItem(placement: .automatic, content: {
                        ToolbarSearchField(searchTerm: $searchString)
                    })
                })
                .frame(minWidth: Constants.macOSNavWidth)
        }
        .navigationTitle(LocalizedStringKey("str.md.quantityUnits"))
        #elseif os(iOS)
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
                        MDQuantityUnitFormView(isNewQuantityUnit: true, toastType: $toastType)
                    } })
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
                NavigationLink(destination: MDQuantityUnitFormView(isNewQuantityUnit: false, quantityUnit: quantityUnit, toastType: $toastType)) {
                    MDQuantityUnitRowView(quantityUnit: quantityUnit)
                }
            }
            .onDelete(perform: delete)
        }
        .onAppear(perform: { grocyVM.requestData(objects: [.quantity_units], ignoreCached: false) })
        .animation(.default)
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
