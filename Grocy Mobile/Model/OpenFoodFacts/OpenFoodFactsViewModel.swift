//
//  OpenFoodFactsViewModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 15.02.21.
//

import SwiftUI
import Foundation
internal import Combine

class OpenFoodFactsViewModel: ObservableObject {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Published var offData: OpenFoodFactsResult?
    @Published var errorMessage: String? = nil
    
    @Published var searchedBarcode: String? = nil
    
    var cancellables = Set<AnyCancellable>()
    
    private var timeoutInterval: Double = 60.0
    
    init(barcode: String = "", timeoutInterval: Double = 60.0) {
        updateBarcode(barcode: barcode)
        self.timeoutInterval = timeoutInterval
    }
    
    func updateBarcode(barcode: String) {
        if !barcode.isEmpty {
            searchedBarcode = barcode
            self.fetchForBarcode(barcode: barcode)
                .sink(receiveCompletion: { result in
                    switch result {
                    case .failure(let error):
                        self.errorMessage = "Handle error: fetch off \(error)"
                    case .finished:
                        self.errorMessage = nil
                        break
                    }
                }, receiveValue: { (offResult) in
                    DispatchQueue.main.async { self.offData = offResult }
                })
                .store(in: &cancellables)
        }
    }
    
    func fetchForBarcode(barcode: String) -> AnyPublisher<OpenFoodFactsResult, APIError> {
        let urlRequest = request(barcode: barcode)
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .mapError{ error in
                APIError.serverError(error: error) }
            .flatMap({ result -> AnyPublisher<OpenFoodFactsResult, APIError> in
                guard let urlResponse = result.response as? HTTPURLResponse, (200...299).contains(urlResponse.statusCode) else {
                    return Just(result.data)
                    // decode if it is an error message
                        .decode(type: ErrorMessage.self, decoder: JSONDecoder())
                    // neither valid response nor error message
                        .mapError { error in APIError.decodingError(error: error) }
                    // display error message
                        .tryMap { throw APIError.errorString(description: $0.errorMessage) }
                        .mapError { $0 as! APIError }
                        .eraseToAnyPublisher()
                }
                
                return Just(result.data)
                    .decode(type: OpenFoodFactsResult.self, decoder: JSONDecoder())
                    .mapError{ error in APIError.decodingError(error: error) }
                    .eraseToAnyPublisher()
            })
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private func request(barcode: String) -> URLRequest {
        let path = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        
        guard let url = URL(string: path)
        else { preconditionFailure("Bad URL") }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["Content-Type": "application/json",
                                       "Accept": "application/json",
                                       "APP": "Grocy-SwiftUI"]
        request.timeoutInterval = self.timeoutInterval
        return request
    }
}

