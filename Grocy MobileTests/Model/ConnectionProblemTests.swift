//
//  ConnectionProblemTests.swift
//  Grocy Mobile
//

import Foundation
import Testing

@testable import Grocy_Mobile

/// The status capsule names the problem from the error of a failed request.
@MainActor
@Suite("Connection problems")
struct ConnectionProblemTests {
    @Test("No network is offline")
    func offline() {
        #expect(ConnectionProblem(error: URLError(.notConnectedToInternet)) == .offline)
        #expect(ConnectionProblem(error: URLError(.networkConnectionLost)) == .offline)
    }

    @Test("A server that doesn't answer is unreachable")
    func unreachable() {
        #expect(ConnectionProblem(error: URLError(.timedOut)) == .serverUnreachable)
        #expect(ConnectionProblem(error: URLError(.cannotConnectToHost)) == .serverUnreachable)
        #expect(ConnectionProblem(error: URLError(.cannotFindHost)) == .serverUnreachable)
        #expect(ConnectionProblem(error: URLError(.serverCertificateUntrusted)) == .serverUnreachable)
    }

    @Test("A proxy saying Grocy doesn't answer (502–504) is unreachable, not an error answer")
    func gatewayError() {
        #expect(ConnectionProblem(error: APIError.serverUnavailable(statusCode: 502)) == .serverUnreachable)
        #expect(ConnectionProblem(error: APIError.serverUnavailable(statusCode: 504)) == .serverUnreachable)
    }

    @Test("An error answer is a server error")
    func serverError() {
        #expect(ConnectionProblem(error: APIError.errorString(description: "Invalid API key")) == .serverError)
        #expect(ConnectionProblem(error: APIError.internalError) == .serverError)
    }

    @Test("A cancelled request isn't a problem")
    func cancelled() {
        #expect(ConnectionProblem(error: URLError(.cancelled)) == nil)
        #expect(ConnectionProblem(error: CancellationError()) == nil)
    }
}
