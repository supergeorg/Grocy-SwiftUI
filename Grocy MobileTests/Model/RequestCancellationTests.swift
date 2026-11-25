//
//  RequestCancellationTests.swift
//  Grocy Mobile
//

import Foundation
import Testing

@testable import Grocy_Mobile

@Suite("Request cancellation")
struct RequestCancellationTests {
    @Test("A cancelled task or URL request counts as a cancellation")
    func cancellations() {
        #expect(isCancellation(CancellationError()))
        #expect(isCancellation(URLError(.cancelled)))
    }

    @Test("Other errors still count as failures")
    func failures() {
        #expect(!isCancellation(URLError(.timedOut)))
        #expect(!isCancellation(URLError(.serverCertificateUntrusted)))
        #expect(!isCancellation(APIError.internalError))
    }
}
