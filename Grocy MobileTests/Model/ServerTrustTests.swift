//
//  ServerTrustTests.swift
//  Grocy Mobile
//

import Foundation
import Testing

@testable import Grocy_Mobile

@Suite("Server certificate trust (#195)")
struct ServerTrustTests {
    @Test("Fingerprints are SHA-256 as colon-separated uppercase hex")
    func fingerprintFormat() {
        // SHA-256("abc") from FIPS 180-2.
        #expect(
            CertificateFingerprint.sha256(of: Data("abc".utf8))
                == "BA:78:16:BF:8F:01:CF:EA:41:41:40:DE:5D:AE:22:23:B0:03:61:A3:96:17:7A:9C:B4:10:FF:61:F2:00:15:AD"
        )
    }

    @Test("Only the trusted certificate on the trusted host is accepted")
    func acceptsOnlyThePinnedCertificate() {
        let delegate = ServerTrustDelegate()
        delegate.setTrustedCertificate(fingerprint: "AA:BB", host: "Grocy.local")
        #expect(delegate.acceptsUntrustedCertificate(host: "grocy.local", fingerprint: "AA:BB", summary: nil))
        #expect(delegate.lastUntrustedCertificate == nil)
        #expect(!delegate.acceptsUntrustedCertificate(host: "grocy.local", fingerprint: "CC:DD", summary: "other"))
        #expect(delegate.lastUntrustedCertificate == UntrustedCertificate(host: "grocy.local", fingerprint: "CC:DD", summary: "other"))
        #expect(!delegate.acceptsUntrustedCertificate(host: "elsewhere.local", fingerprint: "AA:BB", summary: nil))
    }

    @Test("Without a trusted certificate, nothing untrusted is accepted, and the refused one is kept")
    func nothingTrusted() {
        let delegate = ServerTrustDelegate()
        #expect(!delegate.acceptsUntrustedCertificate(host: "grocy.local", fingerprint: "AA:BB", summary: "grocy.local"))
        #expect(delegate.lastUntrustedCertificate?.fingerprint == "AA:BB")
        delegate.setTrustedCertificate(fingerprint: nil, host: nil)
        #expect(delegate.lastUntrustedCertificate == nil)
    }
}
