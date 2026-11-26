//
//  ConnectionProblem.swift
//  Grocy Mobile
//

import Foundation

/// Why the app can't use the server right now. Shown in a small status capsule until a request succeeds again.
nonisolated enum ConnectionProblem: Equatable, Sendable {
    /// The device has no network connection.
    case offline
    /// The device is online, but the server doesn't answer: it's down, the address is wrong, the request timed out,
    /// or the certificate isn't trusted.
    case serverUnreachable
    /// The server answers, but with an error, e.g. a proxy's error page, an invalid API key or an unexpected answer.
    case serverError

    /// The problem an error means, or nil for a cancelled request, which isn't a problem.
    init?(error: Error) {
        if isCancellation(error) { return nil }
        guard let urlError = error as? URLError else {
            self = .serverError
            return
        }
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff, .callIsActive:
            self = .offline
        default:
            self = .serverUnreachable
        }
    }
}
