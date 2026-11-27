//
//  ServerConnectionTests.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 27.11.26.
//

import Foundation
import Testing

@testable import Grocy_Mobile

@MainActor
@Suite("Server connection status")
struct ServerConnectionTests {
    @Test("A request that can't reach the server shows the problem, the next one that works clears it")
    func unreachableThenBack() {
        let connection = ServerConnection()
        #expect(connection.problem == nil)
        connection.report(error: URLError(.cannotConnectToHost))
        #expect(connection.problem == .unreachable)
        let now = Date()
        connection.reportSuccess(at: now)
        #expect(connection.problem == nil)
        #expect(connection.lastContact == now)
    }

    @Test("A cancelled request isn't a problem")
    func cancellation() {
        let connection = ServerConnection()
        connection.report(error: URLError(.cancelled))
        connection.report(error: CancellationError())
        #expect(connection.problem == nil)
    }

    @Test("An error answer from the server is shown with its message")
    func serverError() {
        let connection = ServerConnection()
        connection.report(error: APIError.errorString(description: "Invalid API key"))
        #expect(connection.problem == .serverError(message: "Invalid API key"))
    }

    @Test("Without network that is shown, and the server's state is known again when the network comes back")
    func network() {
        let connection = ServerConnection()
        connection.report(error: URLError(.timedOut))
        connection.networkChanged(isAvailable: false)
        #expect(connection.problem == .noNetwork)
        connection.networkChanged(isAvailable: true)
        #expect(connection.problem == .unreachable)
        connection.reset()
        #expect(connection.problem == nil)
        #expect(connection.lastContact == nil)
    }

    @Test(
        "Errors that mean the server didn't answer",
        arguments: [
            (URLError(.notConnectedToInternet) as Error, true),
            (URLError(.timedOut), true),
            (APIError.serverError(errorMessage: "HTTP 502"), true),
            (APIError.timeout, true),
            (APIError.errorString(description: "Invalid API key"), false),
            (APIError.decodingError(error: APIError.invalidResponse), false),
            (URLError(.cancelled), false),
        ]
    )
    func connectionProblems(error: Error, isConnectionProblem: Bool) {
        #expect(ServerConnection.isConnectionProblem(error) == isConnectionProblem)
    }
}
