//
//  ProductField.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.01.21.
//

import SwiftData
import SwiftUI

struct ProductField: View {
    #if os(iOS)
        struct SearchBar: UIViewRepresentable {
            // This is needed, since the .searchable modifier destroys the list layout.

            @Binding var text: String

            func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
                let searchBar = UISearchBar(frame: .zero)
                searchBar.delegate = context.coordinator

                searchBar.placeholder = "Search"
                searchBar.autocapitalizationType = .none
                searchBar.searchBarStyle = .minimal
                return searchBar
            }

            func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
                uiView.text = text
            }

            func makeCoordinator() -> SearchBar.Coordinator {
                return Coordinator(text: $text)
            }

            class Coordinator: NSObject, UISearchBarDelegate {

                @Binding var text: String

                init(text: Binding<String>) {
                    _text = text
                }

                func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
                    text = searchText
                }
            }
        }
    #endif

    @Environment(GrocyViewModel.self) private var grocyVM

    @Query(sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(sort: \MDProductBarcode.id, order: .forward) var mdProductBarcodes: MDProductBarcodes

    @Binding var productID: Int?
    var description: LocalizedStringKey
    var descriptionInfo: LocalizedStringKey?
    var icon: String = MySymbols.product
    /// Hides products with "Disable own stock", like Grocy's web purchase, inventory and transfer pages (#230).
    var excludeNoOwnStock: Bool = false
    /// Set to a scanned product Grocycode, before the product is selected, so a form can use its stock entry.
    var scannedGrocyCode: Binding<GrocyCode?>? = nil

    @State private var searchTerm: String = ""
    #if os(iOS)
        @State private var isShowingScanner: Bool = false
    #endif

    private func getBarcodes(pID: Int) -> [String] {
        mdProductBarcodes.filter { $0.productID == pID }.map { $0.barcode }
    }

    private var filteredProducts: MDProducts {
        mdProducts.filter {
            searchTerm.isEmpty ? true : ($0.name.localizedCaseInsensitiveContains(searchTerm) || getBarcodes(pID: $0.id).contains(searchTerm))
        }
        .filter {
            !(excludeNoOwnStock && $0.noOwnStock)
        }
        .filter({
            $0.active
        })
        .sorted(by: {
            $0.name.lowercased() < $1.name.lowercased()
        })
    }

    #if os(iOS)
        /// A product Grocycode selects its product. Any other code searches the names and barcodes.
        private func handleScan(_ value: String) {
            if let grocyCode = GrocyCode(string: value), grocyCode.entityType == .product,
                filteredProducts.contains(where: { $0.id == grocyCode.entityID })
            {
                searchTerm = ""
                scannedGrocyCode?.wrappedValue = grocyCode
                productID = grocyCode.entityID
            } else {
                searchTerm = value
            }
        }

        var body: some View {
            pickerView
                .pickerStyle(.navigationLink)
        }
        var pickerView: some View {
            Picker(
                selection: $productID,
                label: HStack {
                    Label(description, systemImage: icon).foregroundStyle(.primary)
                    if let descriptionInfo {
                        FieldDescription(description: descriptionInfo)
                    }
                },
                content: {
                    HStack {
                        SearchBar(text: $searchTerm)
                        Button(
                            action: {
                                isShowingScanner.toggle()
                            },
                            label: {
                                Image(systemName: MySymbols.barcodeScan)
                            }
                        )
                        .sheet(isPresented: $isShowingScanner) {
                            CodeScannerSheetView { result in
                                handleScan(result.value)
                            }
                        }
                    }
                    Text("").tag(nil as Int?)
                    ForEach(filteredProducts, id: \.id) { productElement in
                        Text(productElement.name).tag(productElement.id)
                    }
                }
            )
        }
    #elseif os(macOS)
        var body: some View {
            Picker(
                selection: $productID,
                label: Label(description, systemImage: MySymbols.product),
                content: {
                    Text("").tag(nil as Int?)
                    ForEach(filteredProducts, id: \.id) { productElement in
                        Text(productElement.name).tag(productElement.id)
                    }
                }
            )
            .frame(maxWidth: .infinity)
        }
    #endif
}

#Preview(traits: .previewData) {
    @Previewable @State var productID: Int? = -1

    NavigationStack {
        Form {
            ProductField(productID: $productID, description: "Product")
        }
    }
}
