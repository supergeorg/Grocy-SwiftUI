//
//  CameraTools.swift
//  Grocy Mobile (iOS)
//
//  Created by Georg Meissner on 24.07.21.
//

import Foundation
import AVFoundation

func checkForTorch() -> Bool {
    guard let device = AVCaptureDevice.default(for: .video) else { return false }
    return device.hasTorch
}

func getFrontCameraAvailable() -> Bool {
    let devices = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera], mediaType: AVMediaType.video, position: .front).devices
    return devices.count > 0
}
