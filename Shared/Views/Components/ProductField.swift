//
//  ProductField.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.01.21.
//

import SwiftUI
import SwiftData

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
    var description: String
    
    @State private var searchTerm: String = ""
#if os(iOS)
    @State private var isTorchOn = false
    @State private var isFrontCamera = false
    @State private var isShowingScanner: Bool = false
    func handleScan(result: Result<CodeScannerView.ScanResult, CodeScannerView.ScanError>) {
        self.isShowingScanner = false
        switch result {
        case .success(let code):
            searchTerm = code.string
        case .failure(let error):
            print("Scanning for product failed. \(error)")
//            await grocyVM.postLog("Scanning for product failed. \(error)", type: .error)
        }
    }
#endif
    
    private func getBarcodes(pID: Int) -> [String] {
        mdProductBarcodes.filter{$0.productID == pID}.map{$0.barcode}
    }
    
    private var filteredProducts: MDProducts {
        mdProducts.filter {
            searchTerm.isEmpty ? true : ($0.name.localizedCaseInsensitiveContains(searchTerm) || getBarcodes(pID: $0.id).contains(searchTerm))
        }
        .filter {
            $0.noOwnStock != true
        }
        .filter({
            $0.active
        })
        .sorted(by: {
            $0.name.lowercased() < $1.name.lowercased()
        })
    }
    
#if os(iOS)
    var body: some View {
        pickerView
            .pickerStyle(.navigationLink)
    }
    var pickerView: some View {
        Picker(selection: $productID,
               label: Label(LocalizedStringKey(description), systemImage: MySymbols.product).foregroundStyle(.primary),
               content: {
            HStack {
                SearchBar(text: $searchTerm)
                Button(action: {
                    isShowingScanner.toggle()
                }, label: {
                    Image(systemName: MySymbols.barcodeScan)
                })
                .sheet(isPresented: $isShowingScanner) {
                    CodeScannerView(
                        codeTypes: getSavedCodeTypes().map{$0.type},
                        scanMode: .once,
                        simulatedData: "5901234123457",
                        isFrontCamera: $isFrontCamera,
                        completion: self.handleScan
                    )
                    .overlay(
                        HStack{
                            Button(action: {
                                isTorchOn.toggle()
                            }, label: {
                                Image(systemName: isTorchOn ? "bolt.circle" : "bolt.slash.circle")
                                    .font(.title)
                            })
                            .disabled(!checkForTorch() || isFrontCamera)
                            .padding()
                            if getFrontCameraAvailable() {
                                Button(action: {
                                    isFrontCamera.toggle()
                                }, label: {
                                    Image(systemName: MySymbols.changeCamera)
                                        .font(.title)
                                })
                                .disabled(isTorchOn)
                                .padding()
                            }
                        }
                        , alignment: .topTrailing)
                }
            }
            Text("").tag(nil as Int?)
            ForEach(filteredProducts, id: \.id) { productElement in
                Text(productElement.name).tag(productElement.id as Int?)
            }
        }
        )
    }
#elseif os(macOS)
    var body: some View {
        Picker(selection: $productID, label: Label(LocalizedStringKey(description), systemImage: MySymbols.product), content: {
            Text("").tag(nil as Int?)
            ForEach(filteredProducts, id: \.id) { productElement in
                Text(productElement.name).tag(productElement.id as Int?)
            }
        })
    }
#endif
}

struct ProductField_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView{
            Form{
                ProductField(productID: Binding.constant(1), description: "Product")
            }
        }
    }
}
