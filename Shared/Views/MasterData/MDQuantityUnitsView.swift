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
            HStack(alignment: .center) {
                Text(quantityUnit.name)
                    .font(.title)
                if let namePlural = quantityUnit.namePlural {
                    Text("(\(namePlural))")
                        .font(.title3)
                }
            }
            .foregroundStyle(quantityUnit.active ? .primary : .secondary)
            if let description = quantityUnit.mdQuantityUnitDescription, !description.isEmpty {
                Text(description)
                    .font(.caption)
            }
        }
        .multilineTextAlignment(.leading)
    }
}

struct MDQuantityUnitsView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Environment(\.dismiss) var dismiss
    
    @State private var searchString: String = ""
    @State private var showAddQuantityUnit: Bool = false
    
    @State private var quantityUnitToDelete: MDQuantityUnit? = nil
    @State private var showDeleteAlert: Bool = false
    
    private let dataToUpdate: [ObjectEntities] = [.quantity_units]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private var filteredQuantityUnits: MDQuantityUnits {
        grocyVM.mdQuantityUnits
            .filter {
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            }
    }
    
    private func deleteItem(itemToDelete: MDQuantityUnit) {
        quantityUnitToDelete = itemToDelete
        showDeleteAlert.toggle()
    }
    private func deleteQuantityUnit(toDelID: Int) async {
        do {
            try await grocyVM.deleteMDObject(object: .quantity_units, id: toDelID)
            grocyVM.postLog("Deleting quantity unit was successful.", type: .info)
            await updateData()
        } catch {
            grocyVM.postLog("Deleting quantity unit failed. \(error)", type: .error)
        }
    }
    
    var body: some View {
        if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count == 0 {
#if os(macOS)
            NavigationView{
                bodyContent
                    .frame(minWidth: Constants.macOSNavWidth)
            }
#else
            bodyContent
#endif
        } else {
            ServerProblemView()
                .navigationTitle(LocalizedStringKey("str.md.quantityUnits"))
        }
    }
    
    var bodyContent: some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
#if os(macOS)
                    RefreshButton(updateData: { Task { await updateData() } })
#endif
                    Button(action: {
                        showAddQuantityUnit.toggle()
                    }, label: {Image(systemName: MySymbols.new)})
                }
            }
            .navigationTitle(LocalizedStringKey("str.md.quantityUnits"))
#if os(iOS)
            .sheet(isPresented: self.$showAddQuantityUnit, content: {
                NavigationView {
                    MDQuantityUnitFormView(isNewQuantityUnit: true, showAddQuantityUnit: $showAddQuantityUnit)
                } })
#endif
    }
    
    var content: some View {
        List {
            if grocyVM.mdQuantityUnits.isEmpty {
                ContentUnavailableView("str.md.quantityUnits.empty", systemImage: MySymbols.quantityUnit)
            } else if filteredQuantityUnits.isEmpty {
                ContentUnavailableView.search
            }
#if os(macOS)
            if showAddQuantityUnit {
                NavigationLink(destination: MDQuantityUnitFormView(isNewQuantityUnit: true, showAddQuantityUnit: $showAddQuantityUnit), isActive: $showAddQuantityUnit, label: {
                    NewMDRowLabel(title: "str.md.quantityUnit.new")
                })
            }
#endif
            ForEach(filteredQuantityUnits, id:\.id) { quantityUnit in
                NavigationLink(destination: MDQuantityUnitFormView(isNewQuantityUnit: false, quantityUnit: quantityUnit, showAddQuantityUnit: Binding.constant(false))) {
                    MDQuantityUnitRowView(quantityUnit: quantityUnit)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                    Button(role: .destructive,
                           action: { deleteItem(itemToDelete: quantityUnit) },
                           label: { Label(LocalizedStringKey("str.delete"), systemImage: MySymbols.delete) }
                    )
                })
            }
        }
        .task {
            Task {
                await updateData()
            }
        }
        .searchable(text: $searchString, prompt: "Search")
        .refreshable {
            await updateData()
        }
        .animation(.default, value: filteredQuantityUnits.count)
        .alert(LocalizedStringKey("str.md.quantityUnit.delete.confirm"), isPresented: $showDeleteAlert, actions: {
            Button("Cancel", role: .cancel) { }
            Button(LocalizedStringKey("str.delete"), role: .destructive) {
                if let toDelID = quantityUnitToDelete?.id {
                    Task {
                        await deleteQuantityUnit(toDelID: toDelID)
                    }
                }
            }
        }, message: { Text(quantityUnitToDelete?.name ?? "Name not found") })
    }
}

struct MDQuantityUnitsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MDQuantityUnitRowView(quantityUnit: MDQuantityUnit(id: 0, name: "QU NAME", namePlural: "QU NAME PLURAL", active: true, mdQuantityUnitDescription: "Description", rowCreatedTimestamp: ""))
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
