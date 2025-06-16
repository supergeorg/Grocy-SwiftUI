//
//  CameraTools.swift
//  Grocy Mobile (iOS)
//
//  Created by Georg Meissner on 24.07.21.
//

import Foundation
import AVFoundation

func checkForTorch() -> Bool {
#if os(iOS)
    guard let device = AVCaptureDevice.default(for: .video) else { return false }
    return device.hasTorch
#else
    return false
#endif
}

func getFrontCameraAvailable() -> Bool {
#if os(iOS)
    let devices = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera], mediaType: AVMediaType.video, position: .front).devices
    return devices.count > 0
#else
    return false
#endif
}
