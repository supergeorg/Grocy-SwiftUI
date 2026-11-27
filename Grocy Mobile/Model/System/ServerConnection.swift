//
//  ServerConnection.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 27.11.26.
//

import Foundation

/// Whether the Grocy server can be reached, so the app can tell when it only shows the data saved on the device.
///
/// Fed by the data requests (`GrocyViewModel.requestData`) and by the device's network state (`NWPathMonitor`).
/// The app doesn't check the server in advance: a request that fails tells it, and the next one that works clears it.
@Observable
final class ServerConnection {
    enum Problem: Equatable {
        /// The device has no network connection.
        case noNetwork
        /// The server doesn't answer: it's off, the address can't be reached from this network, or it took too long.
        case unreachable
        /// The server answers, but with an error, e.g. for an API key that isn't valid anymore.
        case serverError(message: String)
    }

    /// The problem to show, or nil when the last request to the server worked.
    private(set) var problem: Problem?
    /// The last time the server answered.
    private(set) var lastContact: Date?
    /// A check started by the person (or automatically) is running.
    var isChecking: Bool = false

    private var isNetworkAvailable: Bool = true
    /// The result of the last request, kept while the network is gone, so it's known again when the network comes back.
    private var serverProblem: Problem?

    func reportSuccess(at date: Date = .now) {
        serverProblem = nil
        lastContact = date
        updateProblem()
    }

    /// A cancelled request isn't a problem: the view that started it went away.
    func report(error: Error) {
        guard !isCancellation(error) else { return }
        if Self.isConnectionProblem(error) {
            serverProblem = .unreachable
        } else if let apiError = error as? APIError {
            serverProblem = .serverError(message: apiError.displayMessage)
        } else {
            serverProblem = .serverError(message: error.localizedDescription)
        }
        updateProblem()
    }

    func networkChanged(isAvailable: Bool) {
        isNetworkAvailable = isAvailable
        updateProblem()
    }

    /// After logging out or switching servers: nothing is known about the new server yet.
    func reset() {
        serverProblem = nil
        lastContact = nil
        isChecking = false
        updateProblem()
    }

    private func updateProblem() {
        problem = isNetworkAvailable ? serverProblem : .noNetwork
    }

    /// True for errors that mean the server didn't answer (as opposed to answering with an error).
    nonisolated static func isConnectionProblem(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .cancelled:
                return false
            case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed,
                .internationalRoamingOff, .dataNotAllowed, .callIsActive, .secureConnectionFailed, .cannotLoadFromNetwork,
                .resourceUnavailable, .badServerResponse:
                return true
            default:
                return false
            }
        }
        if let apiError = error as? APIError {
            switch apiError {
            case .timeout, .serverError, .hassError:
                return true
            case .unsuccessful(let underlying):
                return isConnectionProblem(underlying)
            default:
                return false
            }
        }
        return false
    }
}
