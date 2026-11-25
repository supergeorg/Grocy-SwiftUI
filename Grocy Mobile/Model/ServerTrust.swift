//
//  ServerTrust.swift
//  Grocy Mobile
//
//  Trust for servers with a self-signed or otherwise untrusted certificate (#195).
//

import CryptoKit
import Foundation
import Security
import Synchronization

/// A server certificate the system doesn't trust, as the server presented it.
nonisolated struct UntrustedCertificate: Equatable, Sendable {
    let host: String
    /// The SHA-256 fingerprint of the server's own (leaf) certificate, like `AB:CD:…`.
    let fingerprint: String
    /// The certificate's subject, usually its common name.
    let summary: String?
}

nonisolated enum CertificateFingerprint {
    /// SHA-256 over the certificate's DER data, as uppercase hex pairs separated by colons, like browsers and `openssl x509 -fingerprint -sha256` show it.
    static func sha256(of certificateData: Data) -> String {
        SHA256.hash(data: certificateData)
            .map { byte in
                let hex = String(byte, radix: 16, uppercase: true)
                return byte < 0x10 ? "0" + hex : hex
            }
            .joined(separator: ":")
    }
}

/// Lets the Grocy session trust one certificate the person accepted for their server, by its fingerprint.
///
/// Certificates the system trusts are handled as usual. An untrusted certificate is accepted only when the server's host
/// and the SHA-256 fingerprint of its certificate both match what the person trusted. Otherwise the connection fails as before,
/// and the presented certificate is kept so the login can show its fingerprint.
nonisolated final class ServerTrustDelegate: NSObject, URLSessionDelegate, Sendable {
    private struct State {
        var trustedFingerprint: String?
        var trustedHost: String?
        var lastUntrustedCertificate: UntrustedCertificate?
    }

    private let state = Mutex(State())

    /// The certificate to trust for `host`, or nil to trust only what the system trusts.
    func setTrustedCertificate(fingerprint: String?, host: String?) {
        state.withLock {
            $0.trustedFingerprint = fingerprint
            $0.trustedHost = host?.lowercased()
            $0.lastUntrustedCertificate = nil
        }
    }

    /// The last certificate that was refused, if any.
    var lastUntrustedCertificate: UntrustedCertificate? {
        state.withLock { $0.lastUntrustedCertificate }
    }

    /// Decides for a certificate the system doesn't trust. True when the person trusted exactly this one for this host.
    func acceptsUntrustedCertificate(host: String, fingerprint: String, summary: String?) -> Bool {
        let host = host.lowercased()
        return state.withLock {
            if let trustedFingerprint = $0.trustedFingerprint, trustedFingerprint == fingerprint, $0.trustedHost == host {
                return true
            }
            $0.lastUntrustedCertificate = UntrustedCertificate(host: host, fingerprint: fingerprint, summary: summary)
            return false
        }
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            let trust = challenge.protectionSpace.serverTrust
        else {
            return (.performDefaultHandling, nil)
        }
        // The system's own evaluation first: a valid certificate needs nothing from the person.
        if SecTrustEvaluateWithError(trust, nil) {
            return (.performDefaultHandling, nil)
        }
        guard let leaf = (SecTrustCopyCertificateChain(trust) as? [SecCertificate])?.first else {
            return (.performDefaultHandling, nil)
        }
        let fingerprint = CertificateFingerprint.sha256(of: SecCertificateCopyData(leaf) as Data)
        let summary = SecCertificateCopySubjectSummary(leaf) as String?
        if acceptsUntrustedCertificate(host: challenge.protectionSpace.host, fingerprint: fingerprint, summary: summary) {
            return (.useCredential, URLCredential(trust: trust))
        }
        return (.performDefaultHandling, nil)
    }
}
