//
//  MDLocationFormView.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 16.11.20.
//

import SwiftUI

struct MDLocationFormView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String = ""
    @State private var mdLocationDescription: String = ""
    @State private var isFreezer: Bool = false
    
    @State private var showFreezerInfo: Bool = false
    
    @State private var showDeleteAlert: Bool = false
    
    var isNewLocation: Bool
    var location: MDLocation?
    
    @State var isNameCorrect: Bool = false
    private func checkNameCorrect() -> Bool {
        let foundLocation = grocyVM.mdLocations.first(where: {$0.name == name})
        return isNewLocation ? !(name.isEmpty || foundLocation != nil) : !(name.isEmpty || (foundLocation != nil && foundLocation!.id != location!.id))
    }
    
    private func resetForm() {
        if isNewLocation {
            self.name = ""
            self.mdLocationDescription = ""
            self.isFreezer = false
        } else {
            self.name = location!.name
            self.mdLocationDescription = location!.mdLocationDescription ?? ""
            self.isFreezer = Bool(location!.isFreezer) ?? false
        }
        isNameCorrect = checkNameCorrect()
    }
    
    private func saveLocation() {
        if isNewLocation {
            grocyVM.postMDObject(object: .locations, content: MDLocationPOST(id: grocyVM.findNextID(.locations), name: name, mdLocationDescription: mdLocationDescription, rowCreatedTimestamp: Date().iso8601withFractionalSeconds, isFreezer: String(isFreezer), userfields: nil))
        } else {
            grocyVM.putMDObjectWithID(object: .locations, id: location!.id, content: MDLocationPOST(id: Int(location!.id)!, name: name, mdLocationDescription: mdLocationDescription, rowCreatedTimestamp: location!.rowCreatedTimestamp, isFreezer: String(isFreezer), userfields: nil))
        }
        grocyVM.getMDLocations()
    }
    
    private func deleteLocation() {
        grocyVM.deleteMDObject(object: .locations, id: location!.id)
        grocyVM.getMDLocations()
    }
    
    var body: some View {
        Form {
            Section(header: Text("str.md.location.info")){
                MyTextField(textToEdit: $name, description: "str.md.location.name", isCorrect: $isNameCorrect, leadingIcon: "tag", isEditing: true, errorMessage: "str.md.location.name.required")
                    .onChange(of: name, perform: { value in
                        isNameCorrect = checkNameCorrect()
                    })
                MyTextField(textToEdit: $mdLocationDescription, description: "str.md.description", isCorrect: Binding.constant(true), leadingIcon: "text.justifyleft", isEditing: true)
            }
            Section(header: Text("str.md.location.freezer")){
                HStack(alignment: .center) {
                    Image(systemName: "thermometer.snowflake")
                    Toggle("str.md.location.isFreezing", isOn: $isFreezer)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    #if os(macOS)
                    Button(action: {showFreezerInfo.toggle()}, label: {
                        Image(systemName: "info.circle")
                    })
                    .popover(isPresented: $showFreezerInfo, arrowEdge: .top, content: {
                        Text("str.md.location.isFreezing.description")
                            .padding()
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: 300, maxHeight: 150)
                    })
                    #else
                    Button(action: {showFreezerInfo.toggle()}, label: {
                        Image(systemName: "info.circle")
                    })
                    #endif
                }
                #if os(iOS)
                if showFreezerInfo {
                    Text("str.md.location.isFreezing.description")
                        .font(.caption)
                }
                #endif
            }
            #if os(macOS)
            HStack{
                Button("str.cancel") {
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("str.save") {
                    saveLocation()
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.defaultAction)
            }
            #endif
            if !isNewLocation {
                Button(action: {
                    showDeleteAlert.toggle()
                }, label: {
                    Label("str.md.delete \("str.md.location".localized)", systemImage: "trash")
                        .foregroundColor(.red)
                })
                .keyboardShortcut(.delete)
                .alert(isPresented: $showDeleteAlert) {
                    Alert(title: Text("str.md.location.delete.confirm"), message: Text(""), primaryButton: .destructive(Text("str.delete")) {
                        deleteLocation()
                        #if os(macOS)
                        NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                        #else
                        presentationMode.wrappedValue.dismiss()
                        #endif
                    }, secondaryButton: .cancel())
                }
            }
        }
        .navigationTitle(isNewLocation ? "str.md.location.new" : "str.md.location.edit")
        .animation(.default)
        .onAppear(perform: {
            resetForm()
        })
        .toolbar(content: {
            #if os(iOS)
            ToolbarItem(placement: .cancellationAction) {
                if isNewLocation {
                    Button("str.cancel") {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("str.md.save \("str.md.location".localized)") {
                    saveLocation()
                    presentationMode.wrappedValue.dismiss()
                }.disabled(!isNameCorrect)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                // Back not shown without it
                if !isNewLocation{
                    Text("")
                }
            }
            #endif
        })
    }
}

struct MDLocationFormView_Previews: PreviewProvider {
    static var previews: some View {
        #if os(macOS)
        Group {
            MDLocationFormView(isNewLocation: true)
            MDLocationFormView(isNewLocation: false, location: MDLocation(id: "1", name: "Loc", mdLocationDescription: "descr", rowCreatedTimestamp: "", isFreezer: "1", userfields: nil))
        }
        #else
        Group {
            NavigationView {
                MDLocationFormView(isNewLocation: true)
            }
            NavigationView {
                MDLocationFormView(isNewLocation: false, location: MDLocation(id: "1", name: "Loc", mdLocationDescription: "descr", rowCreatedTimestamp: "", isFreezer: "1", userfields: nil))
            }
        }
        #endif
    }
}
