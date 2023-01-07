//
//  CodeScanner.swift
//  https://github.com/twostraws/CodeScanner
//
//  Created by Paul Hudson on 14/12/2021.
//  Copyright © 2021 Paul Hudson. All rights reserved.
//

import AVFoundation
import SwiftUI
import UIKit

/// A SwiftUI view that is able to scan barcodes, QR codes, and more, and send back what was found.
/// To use, set `codeTypes` to be an array of things to scan for, e.g. `[.qr]`, and set `completion` to
/// a closure that will be called when scanning has finished. This will be sent the string that was detected or a `ScanError`.
/// For testing inside the simulator, set the `simulatedData` property to some test data you want to send back.
@available(macCatalyst 14.0, *)
public struct CodeScannerView: UIViewControllerRepresentable {
    /// An enum describing the ways CodeScannerView can hit scanning problems.
    public enum ScanError: Error {
        /// The camera could not be accessed.
        case badInput
        
        /// The camera was not capable of scanning the requested codes.
        case badOutput
        
        /// Initialization failed.
        case initError(_ error: Error)
        
        /// The camera permission is denied
        case permissionDenied
    }
    
    /// The result from a successful scan: the string that was scanned, and also the type of data that was found.
    /// The type is useful for times when you've asked to scan several different code types at the same time, because
    /// it will report the exact code type that was found.
    @available(macCatalyst 14.0, *)
    public struct ScanResult {
        /// The contents of the code.
        public let string: String
        
        /// The type of code that was matched.
        public let type: AVMetadataObject.ObjectType
    }
    
    /// The operating mode for CodeScannerView.
    public enum ScanMode {
        /// Scan exactly one code, then stop.
        case once
        
        /// Scan each code no more than once.
        case oncePerCode
        
        /// Keep scanning all codes until dismissed.
        case continuous
        
        /// Scan only when capture button is tapped.
        case manual
    }
    
    public let codeTypes: [AVMetadataObject.ObjectType]
    public let scanMode: ScanMode
    public let manualSelect: Bool
    public let scanInterval: Double
    public let showViewfinder: Bool
    public var simulatedData = ""
    public var shouldVibrateOnSuccess: Bool
    @Binding var isTorchOn: Bool
    public var isGalleryPresented: Binding<Bool>
    public var videoCaptureDevice: AVCaptureDevice?
    @Binding var isPaused: Bool
    @Binding var isFrontCamera: Bool
    public var completion: (Result<ScanResult, ScanError>) -> Void
    
    public init(
        codeTypes: [AVMetadataObject.ObjectType],
        scanMode: ScanMode = .once,
        manualSelect: Bool = false,
        scanInterval: Double = 2.0,
        showViewfinder: Bool = false,
        simulatedData: String = "",
        shouldVibrateOnSuccess: Bool = true,
        isTorchOn: Binding<Bool> = .constant(false),
        isGalleryPresented: Binding<Bool> = .constant(false),
        videoCaptureDevice: AVCaptureDevice? = AVCaptureDevice.default(for: .video),
        isPaused: Binding<Bool> = .constant(false),
        isFrontCamera: Binding<Bool> = .constant(false),
        completion: @escaping (Result<ScanResult, ScanError>) -> Void
    ) {
        self.codeTypes = codeTypes
        self.scanMode = scanMode
        self.manualSelect = manualSelect
        self.showViewfinder = showViewfinder
        self.scanInterval = scanInterval
        self.simulatedData = simulatedData
        self.shouldVibrateOnSuccess = shouldVibrateOnSuccess
        self._isTorchOn = isTorchOn
        self.isGalleryPresented = isGalleryPresented
        self.videoCaptureDevice = videoCaptureDevice
        self._isPaused = isPaused
        self._isFrontCamera = isFrontCamera
        self.completion = completion
    }
    
    public func makeUIViewController(context: Context) -> ScannerViewController {
        return ScannerViewController(showViewfinder: showViewfinder, parentView: self, isPaused: $isPaused)
    }
    
    public func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        uiViewController.parentView = self
        uiViewController.updateViewController(
            isTorchOn: isTorchOn,
            isFrontCamera: isFrontCamera,
            isGalleryPresented: isGalleryPresented.wrappedValue,
            isManualCapture: scanMode == .manual,
            isManualSelect: manualSelect
        )
    }
    
}

@available(macCatalyst 14.0, *)
extension CodeScannerView {
    
    public class ScannerViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVCaptureMetadataOutputObjectsDelegate {
        
        var parentView: CodeScannerView!
        @Binding var isPaused: Bool
        var codesFound = Set<String>()
        var didFinishScanning = false
        var lastTime = Date(timeIntervalSince1970: 0)
        private let showViewfinder: Bool
        
        private var isGalleryShowing: Bool = false {
            didSet {
                // Update binding
                if parentView.isGalleryPresented.wrappedValue != isGalleryShowing {
                    parentView.isGalleryPresented.wrappedValue = isGalleryShowing
                }
            }
        }
        
        public init(showViewfinder: Bool = false, parentView: CodeScannerView, isPaused: Binding<Bool>) {
            self.parentView = parentView
            self.showViewfinder = showViewfinder
            self._isPaused = isPaused
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            self.showViewfinder = false
            self._isPaused = .constant(false)
            super.init(coder: coder)
        }
        
        func openGallery() {
            isGalleryShowing = true
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            present(imagePicker, animated: true, completion: nil)
        }
        
        @objc func openGalleryFromButton(_ sender: UIButton) {
            openGallery()
        }
        
        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            isGalleryShowing = false
            
            if let qrcodeImg = info[.originalImage] as? UIImage {
                let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])!
                let ciImage = CIImage(image:qrcodeImg)!
                var qrCodeLink = ""
                
                let features = detector.features(in: ciImage)
                
                for feature in features as! [CIQRCodeFeature] {
                    qrCodeLink += feature.messageString!
                }
                
                if qrCodeLink == "" {
                    didFail(reason: .badOutput)
                } else {
                    let result = ScanResult(string: qrCodeLink, type: .qr)
                    found(result)
                }
            } else {
                print("Something went wrong")
            }
            
            dismiss(animated: true, completion: nil)
        }
        
        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            isGalleryShowing = false
            dismiss(animated: true, completion: nil)
        }
        
#if targetEnvironment(simulator)
        override public func loadView() {
            view = UIView()
            view.isUserInteractionEnabled = true
            
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = 0
            label.text = "You're running in the simulator, which means the camera isn't available. Tap anywhere to send back some simulated data."
            label.textAlignment = .center
            
            let button = UIButton()
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle("Select a custom image", for: .normal)
            button.setTitleColor(UIColor.systemBlue, for: .normal)
            button.setTitleColor(UIColor.gray, for: .highlighted)
            button.addTarget(self, action: #selector(openGalleryFromButton), for: .touchUpInside)
            
            let stackView = UIStackView()
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .vertical
            stackView.spacing = 50
            stackView.addArrangedSubview(label)
            stackView.addArrangedSubview(button)
            
            view.addSubview(stackView)
            
            NSLayoutConstraint.activate([
                button.heightAnchor.constraint(equalToConstant: 50),
                stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
                stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }
        
        override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            // Send back their simulated data, as if it was one of the types they were scanning for
            found(ScanResult(
                string: parentView.simulatedData,
                type: parentView.codeTypes.first ?? .qr
            ))
        }
        
#else
        
        var captureSession: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer!
        var currentCamera: AVCaptureDevice?
        let backCamera: AVCaptureDevice? = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera], mediaType: AVMediaType.video, position: .back).devices.first
        let frontCamera: AVCaptureDevice? = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera], mediaType: AVMediaType.video, position: .front).devices.first
        let fallbackVideoCaptureDevice = AVCaptureDevice.default(for: .video)
        
        private lazy var viewFinder: UIImageView? = {
            let image = UIImage(systemName: "camera.viewfinder")
            let imageView = UIImageView(image: image)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            return imageView
        }()
        
        private lazy var manualCaptureButton: UIButton = {
            let button = UIButton(type: .system)
            let image = UIImage(systemName: "camera.circle")
            button.setBackgroundImage(image, for: .normal)
            button.addTarget(self, action: #selector(manualCapturePressed), for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }()
        
        private lazy var manualSelectButton: UIButton = {
            let button = UIButton(type: .system)
            let image = UIImage(systemName: "photo.on.rectangle")
            let background = UIImage(systemName: "capsule.fill")?.withTintColor(.systemBackground, renderingMode: .alwaysOriginal)
            button.setImage(image, for: .normal)
            button.setBackgroundImage(background, for: .normal)
            button.addTarget(self, action: #selector(openGalleryFromButton), for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }()
        
        override public func viewDidLoad() {
            super.viewDidLoad()
            self.addOrientationDidChangeObserver()
            self.setBackgroundColor()
            self.handleCameraPermission()
        }
        
        override public func viewWillLayoutSubviews() {
            previewLayer?.frame = view.layer.bounds
        }
        
        @objc func updateOrientation() {
            guard let orientation = view.window?.windowScene?.interfaceOrientation else { return }
            guard let connection = captureSession?.connections.last, connection.isVideoOrientationSupported else { return }
            connection.videoOrientation = AVCaptureVideoOrientation(rawValue: orientation.rawValue) ?? .portrait
        }
        
        override public func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            updateOrientation()
        }
        
        override public func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            setupSession()
        }
        
        private func setupSession() {
            guard let captureSession = captureSession else {
                return
            }
            
            if previewLayer == nil {
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            }
            
            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            addviewfinder()
            
            reset()
            
            if (captureSession.isRunning == false) {
                DispatchQueue.global(qos: .userInteractive).async {
                    self.captureSession?.startRunning()
                }
            }
        }
        
        private func handleCameraPermission() {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .restricted:
                break
            case .denied:
                self.didFail(reason: .permissionDenied)
            case .notDetermined:
                self.requestCameraAccess {
                    self.setupCaptureDevice()
                    DispatchQueue.main.async {
                        self.setupSession()
                    }
                }
            case .authorized:
                self.setupCaptureDevice()
                self.setupSession()
                
            default:
                break
            }
        }
        
        private func requestCameraAccess(completion: (() -> Void)?) {
            AVCaptureDevice.requestAccess(for: .video) { [weak self] status in
                guard status else {
                    self?.didFail(reason: .permissionDenied)
                    return
                }
                completion?()
            }
        }
        
        private func addOrientationDidChangeObserver() {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(updateOrientation),
                name: Notification.Name("UIDeviceOrientationDidChangeNotification"),
                object: nil
            )
        }
        
        private func setBackgroundColor(_ color: UIColor = .black) {
            view.backgroundColor = color
        }
        
        private func setupCaptureDevice() {
            captureSession = AVCaptureSession()
            
            guard let videoCaptureDevice = currentCamera ?? fallbackVideoCaptureDevice else {
                return
            }
            
            let videoInput: AVCaptureDeviceInput
            
            do {
                videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            } catch {
                didFail(reason: .initError(error))
                return
            }
            
            if (captureSession!.canAddInput(videoInput)) {
                captureSession!.addInput(videoInput)
            } else {
                didFail(reason: .badInput)
                return
            }
            
            let metadataOutput = AVCaptureMetadataOutput()
            
            if (captureSession!.canAddOutput(metadataOutput)) {
                captureSession!.addOutput(metadataOutput)
                
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = parentView.codeTypes
            } else {
                didFail(reason: .badOutput)
                return
            }
        }
        
        func updateCamera(camera: AVCaptureDevice?) {
            if camera != self.currentCamera {
                guard let camera = camera else { return }
                guard let videoInput = try? AVCaptureDeviceInput(device: camera) else { return }
                if let input = captureSession!.inputs.first {
                    self.captureSession!.removeInput(input)
                }
                if (captureSession!.canAddInput(videoInput)) {
                    captureSession!.addInput(videoInput)
                } else {
                    didFail(reason: .badInput)
                    return
                }
                self.currentCamera = camera
            }
        }
        
        private func addviewfinder() {
            guard showViewfinder, let imageView = viewFinder else { return }
            
            view.addSubview(imageView)
            
            NSLayoutConstraint.activate([
                imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 200),
                imageView.heightAnchor.constraint(equalToConstant: 200),
            ])
        }
        
        override public func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            
            if (captureSession?.isRunning == true) {
                DispatchQueue.global(qos: .userInteractive).async {
                    self.captureSession?.stopRunning()
                }
            }
            
            NotificationCenter.default.removeObserver(self)
        }
        
        override public var prefersStatusBarHidden: Bool {
            true
        }
        
        override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            .all
        }
        
        /** Touch the screen for autofocus */
        public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard touches.first?.view == view,
                  let touchPoint = touches.first,
                  let device = parentView.videoCaptureDevice ?? fallbackVideoCaptureDevice,
                  device.isFocusPointOfInterestSupported
            else { return }
            
            let videoView = view
            let screenSize = videoView!.bounds.size
            let xPoint = touchPoint.location(in: videoView).y / screenSize.height
            let yPoint = 1.0 - touchPoint.location(in: videoView).x / screenSize.width
            let focusPoint = CGPoint(x: xPoint, y: yPoint)
            
            do {
                try device.lockForConfiguration()
            } catch {
                return
            }
            
            // Focus to the correct point, make continiuous focus and exposure so the point stays sharp when moving the device closer
            device.focusPointOfInterest = focusPoint
            device.focusMode = .continuousAutoFocus
            device.exposurePointOfInterest = focusPoint
            device.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
            device.unlockForConfiguration()
        }
        
        @objc func manualCapturePressed(_ sender: Any?) {
            self.readyManualCapture()
        }
        
        func showManualCaptureButton(_ isManualCapture: Bool) {
            if manualCaptureButton.superview == nil {
                view.addSubview(manualCaptureButton)
                NSLayoutConstraint.activate([
                    manualCaptureButton.heightAnchor.constraint(equalToConstant: 60),
                    manualCaptureButton.widthAnchor.constraint(equalTo: manualCaptureButton.heightAnchor),
                    view.centerXAnchor.constraint(equalTo: manualCaptureButton.centerXAnchor),
                    view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: manualCaptureButton.bottomAnchor, constant: 32)
                ])
            }
            
            view.bringSubviewToFront(manualCaptureButton)
            manualCaptureButton.isHidden = !isManualCapture
        }
        
        func showManualSelectButton(_ isManualSelect: Bool) {
            if manualSelectButton.superview == nil {
                view.addSubview(manualSelectButton)
                NSLayoutConstraint.activate([
                    manualSelectButton.heightAnchor.constraint(equalToConstant: 50),
                    manualSelectButton.widthAnchor.constraint(equalToConstant: 60),
                    view.centerXAnchor.constraint(equalTo: manualSelectButton.centerXAnchor),
                    view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: manualSelectButton.bottomAnchor, constant: 32)
                ])
            }
            
            view.bringSubviewToFront(manualSelectButton)
            manualSelectButton.isHidden = !isManualSelect
        }
#endif
        
        func updateViewController(isTorchOn: Bool, isFrontCamera: Bool, isGalleryPresented: Bool, isManualCapture: Bool, isManualSelect: Bool) {
            
            if let device = AVCaptureDevice.default(for: .video) {
                if device.hasTorch {
                    do {
                        if device.torchMode != (isTorchOn ? .on : .off) {
                            try device.lockForConfiguration()
                            device.torchMode = isTorchOn ? .on : .off
                            device.unlockForConfiguration()
                        }
                    } catch {
                        print("Torch could not be used")
                    }
                } else {
                    print("Torch is not available")
                }
            }
            
#if !targetEnvironment(simulator)
            updateCamera(camera: isFrontCamera ? frontCamera : backCamera)
#endif
            
            if isGalleryPresented && !isGalleryShowing {
                openGallery()
            }
            
#if !targetEnvironment(simulator)
            showManualCaptureButton(isManualCapture)
            showManualSelectButton(isManualSelect)
#endif
        }
        
        public func reset() {
            codesFound.removeAll()
            didFinishScanning = false
            lastTime = Date(timeIntervalSince1970: 0)
        }
        
        public func readyManualCapture() {
            guard parentView.scanMode == .manual else { return }
            self.reset()
            lastTime = Date()
        }
        
        public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if isPaused { return }
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                guard didFinishScanning == false else { return }
                let result = ScanResult(string: stringValue, type: readableObject.type)
                
                switch parentView.scanMode {
                case .once:
                    found(result)
                    // make sure we only trigger scan once per use
                    didFinishScanning = true
                    
                case .manual:
                    if !didFinishScanning, isWithinManualCaptureInterval() {
                        found(result)
                        didFinishScanning = true
                    }
                    
                case .oncePerCode:
                    if !codesFound.contains(stringValue) {
                        codesFound.insert(stringValue)
                        found(result)
                    }
                    
                case .continuous:
                    if isPastScanInterval() {
                        found(result)
                    }
                }
            }
        }
        
        func isPastScanInterval() -> Bool {
            Date().timeIntervalSince(lastTime) >= parentView.scanInterval
        }
        
        func isWithinManualCaptureInterval() -> Bool {
            Date().timeIntervalSince(lastTime) <= 0.5
        }
        
        func found(_ result: ScanResult) {
            lastTime = Date()
            
            if parentView.shouldVibrateOnSuccess {
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            }
            
            // UPC-A is a subset of EAN-13, but with 12 places and a leading zero
            // Since the US has EAN-13 country code 00 but have another system,
            // this should not break anything (I hope)
            if result.type == .ean13 && result.string.hasPrefix("0") {
                var editedString = result.string
                editedString.remove(at: result.string.startIndex)
                let resultUPCA = ScanResult(string: editedString, type: result.type)
                parentView.completion(.success(resultUPCA))
            } else {
                parentView.completion(.success(result))
            }
        }
        
        func didFail(reason: ScanError) {
            parentView.completion(.failure(reason))
        }
        
    }
}

@available(macCatalyst 14.0, *)
struct CodeScannerView_Previews: PreviewProvider {
    static var previews: some View {
        CodeScannerView(codeTypes: [.qr]) { result in
            // do nothing
        }
    }
}
