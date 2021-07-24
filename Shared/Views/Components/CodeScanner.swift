//
//  CodeScannerView.swift
//
//  Created by Paul Hudson on 10/12/2019.
//  Copyright © 2019 Paul Hudson. All rights reserved.
//
import AVFoundation
import SwiftUI

/// A SwiftUI view that is able to scan barcodes, QR codes, and more, and send back what was found.
/// To use, set `codeTypes` to be an array of things to scan for, e.g. `[.qr]`, and set `completion` to
/// a closure that will be called when scanning has finished. This will be sent the string that was detected or a `ScanError`.
/// For testing inside the simulator, set the `simulatedData` property to some test data you want to send back.
public struct CodeScannerView: UIViewControllerRepresentable {
    public enum ScanError: Error {
        case badInput, badOutput
    }
    
    public enum ScanMode {
        case once, oncePerCode, continuous
    }

    public class ScannerCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: CodeScannerView
        @Binding var isPaused: Bool
        var codesFound: Set<String>
        var isFinishScanning = false
        var lastTime = Date(timeIntervalSince1970: 0)

        init(parent: CodeScannerView, isPaused: Binding<Bool>) {
            self.parent = parent
            self._isPaused = isPaused
            self.codesFound = Set<String>()
        }

        public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if isPaused { return }
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                guard isFinishScanning == false else { return }

                switch self.parent.scanMode {
                case .once:
                    found(code: stringValue)
                    // make sure we only trigger scan once per use
                    isFinishScanning = true
                case .oncePerCode:
                    if !codesFound.contains(stringValue) {
                        codesFound.insert(stringValue)
                        found(code: stringValue)
                    }
                case .continuous:
                    if isPastScanInterval() {
                        found(code: stringValue)
                    }
                }
            }
        }

        func isPastScanInterval() -> Bool {
            return Date().timeIntervalSince(lastTime) >= self.parent.scanInterval
        }
        
        func found(code: String) {
            lastTime = Date()
            parent.completion(.success(code))
        }

        func didFail(reason: ScanError) {
            parent.completion(.failure(reason))
        }
    }

    #if targetEnvironment(simulator)
    public class ScannerViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate{
        var delegate: ScannerCoordinator?

        public init() {
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override public func loadView() {
            view = UIView()
            view.isUserInteractionEnabled = true
            let label = UILabel()
            label.numberOfLines = 0

            label.text = "You're running in the simulator, which means the camera isn't available. Tap anywhere to send back some simulated data."
            label.textAlignment = .center
            let button = UIButton()
            button.setTitle("Or tap here to select a custom image", for: .normal)
            button.setTitleColor(UIColor.systemBlue, for: .normal)
            button.setTitleColor(UIColor.gray, for: .highlighted)
            button.addTarget(self, action: #selector(self.openGallery), for: .touchUpInside)

            let stackView = UIStackView()
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
            guard let simulatedData = delegate?.parent.simulatedData else {
                print("Simulated Data Not Provided!")
                return
            }

            delegate?.found(code: simulatedData)
        }

        @objc func openGallery(_ sender: UIButton){
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            self.present(imagePicker, animated: true, completion: nil)
        }

        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
            if let qrcodeImg = info[.originalImage] as? UIImage {
                let detector:CIDetector=CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])!
                let ciImage:CIImage=CIImage(image:qrcodeImg)!
                var qrCodeLink=""

                let features=detector.features(in: ciImage)
                for feature in features as! [CIQRCodeFeature] {
                    qrCodeLink += feature.messageString!
                }

                if qrCodeLink=="" {
                    delegate?.didFail(reason: .badOutput)
                }else{
                    delegate?.found(code: qrCodeLink)
                }
            }
            else{
                print("Something went wrong")
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
    #else
    public class ScannerViewController: UIViewController {
        var captureSession: AVCaptureSession!
        var previewLayer: AVCaptureVideoPreviewLayer!
        var delegate: ScannerCoordinator?
        var currentCamera: AVCaptureDevice?
        let backCamera: AVCaptureDevice? = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera], mediaType: AVMediaType.video, position: .back).devices.first
        let frontCamera: AVCaptureDevice? = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera], mediaType: AVMediaType.video, position: .front).devices.first
        var videoCaptureDevice: AVCaptureDevice? = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera], mediaType: AVMediaType.video, position: .back).devices.first

        public init() {
            super.init(nibName: nil, bundle: nil)
        }

        public required init?(coder: NSCoder) {
            super.init(coder: coder)
        }

        override public func viewDidLoad() {
            super.viewDidLoad()


            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(updateOrientation),
                                                   name: Notification.Name("UIDeviceOrientationDidChangeNotification"),
                                                   object: nil)

            view.backgroundColor = UIColor.black
            captureSession = AVCaptureSession()

            guard let videoCaptureDevice = videoCaptureDevice else {
                return
            }

            guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else { return }

            if (captureSession.canAddInput(videoInput)) {
                captureSession.addInput(videoInput)
            } else {
                delegate?.didFail(reason: .badInput)
                return
            }

            self.currentCamera = videoCaptureDevice
            
            let metadataOutput = AVCaptureMetadataOutput()

            if (captureSession.canAddOutput(metadataOutput)) {
                captureSession.addOutput(metadataOutput)

                metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = delegate?.parent.codeTypes
            } else {
                delegate?.didFail(reason: .badOutput)
                return
            }
        }
        
        func updateCamera(camera: AVCaptureDevice?) {
            if camera != self.currentCamera {
                guard let camera = camera else { return }
                guard let videoInput = try? AVCaptureDeviceInput(device: camera) else { return }
                if let input = captureSession.inputs.first {
                    self.captureSession.removeInput(input)
                }
                if (captureSession.canAddInput(videoInput)) {
                    captureSession.addInput(videoInput)
                } else {
                    delegate?.didFail(reason: .badInput)
                    return
                }
                self.currentCamera = camera
            }
        }

        override public func viewWillLayoutSubviews() {
            previewLayer?.frame = view.layer.bounds
        }

        @objc func updateOrientation() {
            guard let orientation = view.window?.windowScene?.interfaceOrientation else { return }
            guard let connection = captureSession.connections.last, connection.isVideoOrientationSupported else { return }
            connection.videoOrientation = AVCaptureVideoOrientation(rawValue: orientation.rawValue) ?? .portrait
        }

        override public func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            updateOrientation()
        }

        override public func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            if previewLayer == nil {
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            }
            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)

            if (captureSession?.isRunning == false) {
                captureSession.startRunning()
            }
        }

        override public func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)

            if (captureSession?.isRunning == true) {
                captureSession.stopRunning()
            }

            NotificationCenter.default.removeObserver(self)
        }

        override public var prefersStatusBarHidden: Bool {
            return true
        }

        override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            return .all
        }
    }
    #endif

    public let codeTypes: [AVMetadataObject.ObjectType]
    public let scanMode: ScanMode
    public let scanInterval: Double
    public let showViewfinder: Bool
    public var simulatedData = ""
    public var completion: (Result<String, ScanError>) -> Void
    @Binding var isPaused: Bool
    @Binding var isFrontCamera: Bool

    public init(codeTypes: [AVMetadataObject.ObjectType], scanMode: ScanMode = .once, showViewfinder: Bool = false, scanInterval: Double = 2.0, simulatedData: String = "", isPaused: Binding<Bool> = Binding.constant(false), isFrontCamera: Binding<Bool> = Binding.constant(false), completion: @escaping (Result<String, ScanError>) -> Void) {
        self.codeTypes = codeTypes
        self.scanMode = scanMode
        self.showViewfinder = showViewfinder
        self.scanInterval = scanInterval
        self.simulatedData = simulatedData
        self.completion = completion
        self._isPaused = isPaused
        self._isFrontCamera = isFrontCamera
    }

    public func makeCoordinator() -> ScannerCoordinator {
        return ScannerCoordinator(parent: self, isPaused: $isPaused)
    }

    public func makeUIViewController(context: Context) -> ScannerViewController {
        let viewController = ScannerViewController()
        viewController.delegate = context.coordinator
        return viewController
    }

    public func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        #if !targetEnvironment(simulator)
        uiViewController.updateCamera(camera: isFrontCamera ? uiViewController.frontCamera : uiViewController.backCamera)
        #endif
    }
}

struct CodeScannerView_Previews: PreviewProvider {
    static var previews: some View {
        CodeScannerView(codeTypes: [.qr]) { result in
            // do nothing
        }
    }
}
