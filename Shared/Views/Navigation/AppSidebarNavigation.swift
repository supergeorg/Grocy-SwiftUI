//
//  SideBarView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 12.11.20.
//

import SwiftUI

extension AppSidebarNavigation {
    enum NavigationItem: String {
        case quickScan = "barcode.viewfinder"
        case stockOverview = "books.vertical"
        case shoppingList = "cart"
        case recipes = "list.bullet.below.rectangle"
        case mealPlan = "paperplane.fill"
        case choresOverview = "house"
        case tasks = "text.badge.checkmark"
        case batteriesOverview = "battery.25"
        case equipment = "latch.2.case"
        case calendar = "calendar"
        case purchase = "cart.badge.plus"
        case consume = "fork.knife"
        case transfer = "arrow.left.arrow.right"
        case inventory = "list.bullet"
        case choreTracking = "play.fill"
        case batteryTracking = "flame.fill"
        case userEntity = "questionmark.circle.fill"
        
        case masterData = "tablecells"
        case mdProducts = "p.circle.fill"
        case mdLocations = "mappin"
        case mdShoppingLocations = "cart.fill"
        case mdQuantityUnits = "scalemass.fill"
        case mdProductGroups = "square.stack.fill"
        case mdChores = "house.fill"
        case mdBatteries = "battery.100"
        case mdTaskCategories = "scale.3d"
        case mdUserFields = "bookmark.fill"
        case mdUserEntities = "bookmark"
        
        case settings = "gear"
        case userManagement = "person.3.fill"
    }
}

struct AppSidebarNavigation: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @State private var firstAppear: Bool = true
    
    @State var toastType: ToastType?
    
    @AppStorage("devMode") private var devMode: Bool = false
    
    //    #if os(iOS)
    //    @State private var selection: NavigationItem? = NavigationItem.quickScan
    //    #else
    @State private var selection: NavigationItem? = NavigationItem.stockOverview
    //    #endif
    
    private func toggleSidebar() {
        #if os(macOS)
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
        #endif
    }
    
    var body: some View {
        NavigationView {
            List(selection: $selection) {
                #if os(macOS)
                Image("grocy-logo")
                    .resizable()
                    .frame(width: 240/2.5, height: 92/2.5)
                Divider()
                #endif
                Group {
                    #if os(iOS)
                    NavigationLink(destination: QuickScanModeView(), tag: NavigationItem.quickScan, selection: $selection) {
                        Label(LocalizedStringKey("str.nav.quickScan"), systemImage: NavigationItem.quickScan.rawValue)
                    }
                    .tag(NavigationItem.quickScan)
                    #endif
                    
                    NavigationLink(destination: StockView(), tag: NavigationItem.stockOverview, selection: $selection) {
                        Label(LocalizedStringKey("str.nav.stockOverview"), systemImage: NavigationItem.stockOverview.rawValue)
                    }
                    .tag(NavigationItem.stockOverview)
                    
                    NavigationLink(destination: ShoppingListView(), tag: NavigationItem.shoppingList, selection: $selection) {
                        Label(LocalizedStringKey("str.nav.shoppingList"), systemImage: NavigationItem.shoppingList.rawValue)
                    }
                    .tag(NavigationItem.shoppingList)
                    
                    Divider()
                }
                
                //                                Group {
                //                                    NavigationLink(destination: EmptyView(), tag: NavigationItem.recipes, selection: $selection) {
                //                                        Label("str.nav.recipes", systemImage: NavigationItem.recipes.rawValue)
                //                                    }
                //                                    .tag(NavigationItem.recipes)
                //
                //                                    NavigationLink(destination: EmptyView(), tag: NavigationItem.mealPlan, selection: $selection) {
                //                                        Label("str.nav.mealPlan", systemImage: NavigationItem.mealPlan.rawValue)
                //                                    }
                //                                    .tag(NavigationItem.mealPlan)
                //                                    Divider()
                //                                }
                
                //                Group {
                //                    NavigationLink(destination: EmptyView(), tag: NavigationItem.choresOverview, selection: $selection) {
                //                        Label("str.nav.choresOverview", systemImage: NavigationItem.choresOverview.rawValue)
                //                    }
                //                    .tag(NavigationItem.choresOverview)
                //
                //                    NavigationLink(destination: EmptyView(), tag: NavigationItem.tasks, selection: $selection) {
                //                        Label("str.nav.tasks", systemImage: NavigationItem.tasks.rawValue)
                //                    }
                //                    .tag(NavigationItem.tasks)
                //
                //                    NavigationLink(destination: EmptyView(), tag: NavigationItem.batteriesOverview, selection: $selection) {
                //                        Label("str.nav.batteriesOverview", systemImage: NavigationItem.batteriesOverview.rawValue)
                //                    }
                //                    .tag(NavigationItem.batteriesOverview)
                //
                //                    NavigationLink(destination: EmptyView(), tag: NavigationItem.equipment, selection: $selection) {
                //                        Label("str.nav.equipment", systemImage: NavigationItem.equipment.rawValue)
                //                    }
                //                    .tag(NavigationItem.equipment)
                //                    Divider()
                //                }
                
                //                Group {
                //                    NavigationLink(destination: EmptyView(), tag: NavigationItem.calendar, selection: $selection) {
                //                        Label("str.nav.calendar", systemImage: NavigationItem.calendar.rawValue)
                //                    }
                //                    .tag(NavigationItem.calendar)
                //                    Divider()
                //                }
                
                Group {
                    NavigationLink(destination: PurchaseProductView(toastType: $toastType), tag: NavigationItem.purchase, selection: $selection) {
                        Label(LocalizedStringKey("str.nav.purchase"), systemImage: NavigationItem.purchase.rawValue)
                    }
                    .tag(NavigationItem.purchase)
                    
                    NavigationLink(destination: ConsumeProductView(toastType: $toastType), tag: NavigationItem.consume, selection: $selection) {
                        Label(LocalizedStringKey("str.nav.consume"), systemImage: NavigationItem.consume.rawValue)
                    }
                    .tag(NavigationItem.consume)
                    
                    NavigationLink(destination: TransferProductView(), tag: NavigationItem.transfer, selection: $selection) {
                        Label(LocalizedStringKey("str.nav.transfer"), systemImage: NavigationItem.transfer.rawValue)
                    }
                    .tag(NavigationItem.transfer)
                    
                    NavigationLink(destination: InventoryProductView(), tag: NavigationItem.inventory, selection: $selection) {
                        Label(LocalizedStringKey("str.nav.inventory"), systemImage: NavigationItem.inventory.rawValue)
                    }
                    .tag(NavigationItem.inventory)
                    
                    //                    NavigationLink(destination: EmptyView(), tag: NavigationItem.choreTracking, selection: $selection) {
                    //                        Label("str.nav.choreTracking", systemImage: NavigationItem.choreTracking.rawValue)
                    //                    }
                    //                    .tag(NavigationItem.choreTracking)
                    //
                    //                    NavigationLink(destination: EmptyView(), tag: NavigationItem.batteryTracking, selection: $selection) {
                    //                        Label("str.nav.batteryTracking", systemImage: NavigationItem.batteryTracking.rawValue)
                    //                    }
                    //                    .tag(NavigationItem.batteryTracking)
                    Divider()
                }
                
                //                if grocyVM.mdUserEntities.count > 0 {
                //                Group {
                //                    ForEach(grocyVM.mdUserEntities, id:\.id) {userEntity in
                //                        NavigationLink(destination: UserEntityView(userEntity: userEntity), tag: NavigationItem.userEntity(userEntity.name), selection: $selection) {
                //                            Label(userEntity.name, systemImage: getSFSymbolForFA(faName: userEntity.iconCSSClass ?? ""))
                //                        }
                //                        .tag(NavigationItem.userEntity(userEntity.name))
                //                    }
                //                    Divider()
                //                }
                //                }
                
                Group {
                    Section(header: Label(LocalizedStringKey("str.nav.md"), systemImage: NavigationItem.masterData.rawValue)) {
                        NavigationLink(destination: MDProductsView(), tag: NavigationItem.mdProducts, selection: $selection) {
                            Label(LocalizedStringKey("str.nav.md.products"), systemImage: NavigationItem.mdProducts.rawValue)
                        }
                        .tag(NavigationItem.mdProducts)
                        
                        NavigationLink(destination: MDLocationsView(), tag: NavigationItem.mdLocations, selection: $selection) {
                            Label(LocalizedStringKey("str.nav.md.locations"), systemImage: NavigationItem.mdLocations.rawValue)
                        }
                        .tag(NavigationItem.mdLocations)
                        
                        NavigationLink(destination: MDShoppingLocationsView(), tag: NavigationItem.mdShoppingLocations, selection: $selection) {
                            Label(LocalizedStringKey("str.nav.md.shoppingLocations"), systemImage: NavigationItem.mdShoppingLocations.rawValue)
                        }
                        .tag(NavigationItem.mdShoppingLocations)
                        
                        NavigationLink(destination: MDQuantityUnitsView(), tag: NavigationItem.mdQuantityUnits, selection: $selection) {
                            Label(LocalizedStringKey("str.nav.md.quantityUnits"), systemImage: NavigationItem.mdQuantityUnits.rawValue)
                        }
                        .tag(NavigationItem.mdQuantityUnits)
                        
                        NavigationLink(destination: MDProductGroupsView(), tag: NavigationItem.mdProductGroups, selection: $selection) {
                            Label(LocalizedStringKey("str.nav.md.productGroups"), systemImage: NavigationItem.mdProductGroups.rawValue)
                        }
                        .tag(NavigationItem.mdProductGroups)
                        
                        if devMode {
                            NavigationLink(destination: MDChoresView(), tag: NavigationItem.mdChores, selection: $selection) {
                                Label("str.nav.md.chores", systemImage: NavigationItem.mdChores.rawValue)
                            }
                            .tag(NavigationItem.mdChores)
                            
                            NavigationLink(destination: MDBatteriesView(), tag: NavigationItem.mdBatteries, selection: $selection) {
                                Label("str.nav.md.batteries", systemImage: NavigationItem.mdBatteries.rawValue)
                            }
                            .tag(NavigationItem.mdBatteries)
                        }
                        
                        NavigationLink(destination: MDTaskCategoriesView(), tag: NavigationItem.mdTaskCategories, selection: $selection) {
                            Label("str.nav.md.taskCategories", systemImage: NavigationItem.mdTaskCategories.rawValue)
                        }
                        .tag(NavigationItem.mdTaskCategories)
                        
                        if devMode {
                            
                            NavigationLink(destination: MDUserFieldsView(), tag: NavigationItem.mdUserFields, selection: $selection) {
                                Label(LocalizedStringKey("str.nav.md.userFields"), systemImage: NavigationItem.mdUserFields.rawValue)
                            }
                            .tag(NavigationItem.mdUserFields)
                            
                            NavigationLink(destination: MDUserEntitiesView(), tag: NavigationItem.mdUserEntities, selection: $selection) {
                                Label(LocalizedStringKey("str.nav.md.userEntities"), systemImage: NavigationItem.mdUserEntities.rawValue)
                            }
                            .tag(NavigationItem.mdUserEntities)
                        }
                    }
                    Divider()
                }
                
                #if os(iOS)
                NavigationLink(destination: SettingsView(), tag: NavigationItem.settings, selection: $selection) {
                    Label(LocalizedStringKey("str.nav.settings"), systemImage: NavigationItem.settings.rawValue)
                }
                #endif
                
                NavigationLink(destination: UserManagementView(), tag: NavigationItem.userManagement, selection: $selection) {
                    Label(LocalizedStringKey("str.nav.userManagement"), systemImage: NavigationItem.userManagement.rawValue)
                }
                .tag(NavigationItem.userManagement)
            }
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .navigation) {
                    Button(action: toggleSidebar, label: {
                        Image(systemName: "sidebar.left")
                    })
                }
                #endif
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Grocy")
            //            .onAppear(perform: {
            //                if firstAppear {
            //                    grocyVM.getMDUserEntities()
            //                    firstAppear = false
            //                }
            //            })
            #if os(iOS)
            // A quick and dirty hack for non-showing view.
            if firstAppear {
                if UIDevice.current.orientation.isPortrait && UIDevice.current.userInterfaceIdiom == .pad {
                    VStack{
                        Image(systemName: "arrow.left")
                            .font(.system(size: 100))
                        Text("Please select a sidebar entry from the left or rotate the device to landscape.")
                    }
                }
            }
            #endif
        }
    }
}

struct AppSidebarNavigation_Previews: PreviewProvider {
    static var previews: some View {
        AppSidebarNavigation()
    }
}
