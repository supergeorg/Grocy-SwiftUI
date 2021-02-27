//
//  OpenFoodFactsViewModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 15.02.21.
//

import Foundation
import Combine

class OpenFoodFactsViewModel: ObservableObject {
    @Published var offData: OpenFoodFactsResult?
    
    var cancellables = Set<AnyCancellable>()
    
    init(barcode: String) {
        if !barcode.isEmpty {
            self.fetchForBarcode(barcode: barcode)
                .sink(receiveCompletion: { result in
                    switch result {
                    case .failure(let error):
                        print("Handle error: fetch off \(error)")
                    case .finished:
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
            .mapError{ _ in APIError.serverError }
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
        request.timeoutInterval = 3
        return request
    }
}

