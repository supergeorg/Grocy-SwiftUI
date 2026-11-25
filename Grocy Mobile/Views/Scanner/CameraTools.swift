//
//  CameraTools.swift
//  Grocy Mobile (iOS)
//
//  Created by Georg Meissner on 24.07.21.
//

import AVFoundation
import Foundation

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
        let devices = AVCaptureDevice.DiscoverySession.init(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera],
            mediaType: AVMediaType.video,
            position: .front
        ).devices
        return devices.count > 0
    #else
        return false
    #endif
}

func toggleTorch(state: Bool) {
    #if os(iOS)
        guard let device = AVCaptureDevice.userPreferredCamera, device.hasTorch else { return }

        do {
            try device.lockForConfiguration()
            print(state)
            device.torchMode = state ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Torch unavailable")
        }
    #endif
}

/// The zoom that lets a barcode be held far enough away for the camera to focus on it (#204).
///
/// Newer Pro iPhones have a long minimum focus distance, so a barcode close enough to fill the frame is blurry.
/// Like Apple's barcode scanning guidance, this zooms in until a typical EAN-13 barcode (about 37 mm wide) fills half the frame
/// while it's held at the minimum focus distance. Returns `nil` when no zoom is needed or the camera doesn't say its focus distance.
func recommendedScannerZoomFactor() -> Double? {
    #if os(iOS)
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return nil }
        // In millimeters, or -1 when the camera doesn't know it.
        let minimumFocusDistance = Double(device.minimumFocusDistance)
        guard minimumFocusDistance > 0 else { return nil }
        let fieldOfView = Double(device.activeFormat.videoFieldOfView) * .pi / 180
        guard fieldOfView > 0 else { return nil }
        let codeWidth = 37.0
        let frameFill = 0.5
        let distanceForFilledFrame = (codeWidth / frameFill) / tan(fieldOfView / 2)
        guard distanceForFilledFrame < minimumFocusDistance else { return nil }
        return min(minimumFocusDistance / distanceForFilledFrame, 3)
    #else
        return nil
    #endif
}
