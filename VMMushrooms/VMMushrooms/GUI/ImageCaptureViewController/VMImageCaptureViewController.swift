///Users/varvaramyronova/Documents/projects/VMMushrooms/VMMushrooms/VMMushrooms/GUI/ImageCaptureViewController/VMImageCaptureRootView.swift
//  VMImageCaptureViewController.swift
//  VMMushrooms
//
//  Created by Varvara Myronova on 1/15/19.
//  Copyright © 2019 Varvara Myronova. All rights reserved.
//

import UIKit
import AVFoundation
import Vision
import Photos

class VMImageCaptureViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate
{
    
    weak private var rootView: VMImageCaptureRootView? {
        return viewIfLoaded as? VMImageCaptureRootView
    }
    
    //store captured photos for recognizing
    private var photos = [CVPixelBuffer]()
    
    //MARK:- capture pjotos session management
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    private let session = AVCaptureSession()
    
    private var isSessionRunning = false
    private var setupResult: SessionSetupResult = .success
    
    private let sessionQueue = DispatchQueue(label: "com.varvaraMironova.VMMushrooms.sessionQueue")
    
    //MARK:- capturing photos
    @objc dynamic var captureDeviceInput: AVCaptureDeviceInput!
    
    private let photoOutput = AVCapturePhotoOutput()
    private var inProgressPhotoCaptureDelegates = [Int64: VMPhotoCaptureProcessor]()
    
    var windowOrientation = UIApplication.shared.statusBarOrientation
    
    //MARK:- Vision
    private var analysisRequests = [VNRequest]()
    private let sequenceRequestHandler = VNSequenceRequestHandler()
    
    // Queue for dispatching vision classification and barcode requests
    private let visionQueue = DispatchQueue(label: "com.varvaraMironova.VMMushrooms.serialVisionQueue")
    
    //MARK:- Registration history
    private let maximumHistoryLength = 15
    private var transpositionHistoryPoints: [CGPoint] = [ ]
    private var previousPixelBuffer: CVPixelBuffer?
    
    private var detectionOverlay: CALayer! = nil
    
    // The current pixel buffer undergoing analysis. Run requests in a serial fashion, one after another.
    private var currentlyAnalyzedPixelBuffer: CVPixelBuffer?
    
    var resultViewShown = false
    
    //MARK:- View Life Cicle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let rootView = rootView, let previewView = rootView.previewView else { return }
        
        previewView.session = session
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // The user has previously granted access to the camera.
            break
            
        case .notDetermined:
            /*
             The user has not yet been presented with the option to grant
             video access. Suspend the session queue to delay session
             setup until the access request has completed.
             */
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [unowned self] (granted) in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                
                self.sessionQueue.resume()
            })
            
            break
            
        default:
            // The user has previously denied access.
            setupResult = .notAuthorized
            
            break
        }
        
        sessionQueue.async {
            self.setupAVCaptureSession()
        }
        
        visionQueue.async {
            self.setupVision()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sessionQueue.async {[unowned self] in
            switch self.setupResult {
            case .success:
                // Only setup observers and start the session if setup succeeded.
                self.subscribeNotifications()
                self.startCaptureSession()
                self.isSessionRunning = self.session.isRunning
                
            case .notAuthorized:
                DispatchQueue.main.async {
                    let changePrivacySetting = "AVCam doesn't have permission to use the camera, please change privacy settings"
                    let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
                                                            style: .`default`,
                                                            handler: { _ in
                                                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                                          options: [:],
                                                                                          completionHandler: nil)
                    }))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
                
            case .configurationFailed:
                DispatchQueue.main.async {
                    let alertMsg = "Alert message when something goes wrong during capture session configuration"
                    let message = NSLocalizedString("Unable to capture media", comment: alertMsg)
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        resultViewShown = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
                self.unsubscribeNotifications()
                self.isSessionRunning = self.session.isRunning
            }
        }
        
        super.viewWillDisappear(animated)
    }
    
    //MARK:- Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let productVC = segue.destination as? VMProductViewController, segue.identifier == "showProductSegue" {
            if let productID = sender as? String {
                productVC.mushroomModel = VMMushroomModel(identifier: productID)
            }
        }
    }
    
    //MARK:- Interface Handlers
    @IBAction func onTakePhotoButton(_ sender: Any) {
        guard let rootView = rootView, let previewView = rootView.previewView
        else { return }
        
        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection?.videoOrientation
        
        sessionQueue.async {
            if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
            }
            
            let photoSettings = AVCapturePhotoSettings(format: [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)])
            
            if self.captureDeviceInput.device.isFlashAvailable {
                photoSettings.flashMode = .auto
            }
            
            let photoCaptureProcessor = VMPhotoCaptureProcessor(with: photoSettings, willCapturePhotoAnimation: {
                // Flash the screen to signal that AVCam took a photo.
                DispatchQueue.main.async {
                    previewView.videoPreviewLayer.opacity = 0
                    
                    UIView.animate(withDuration: 0.25) {
                        previewView.videoPreviewLayer.opacity = 1
                    }
                }
            }, completionHandler: { [unowned self](photoCaptureProcessor, error) in
                // When the capture is complete, remove a reference to the photo capture delegate so it can be deallocated.
                #warning("Handle error!")
                self.sessionQueue.async {
                    if let pixelBuffer = photoCaptureProcessor.pixelBuffer {
                        if let image = photoCaptureProcessor.photo {
                            self.currentlyAnalyzedPixelBuffer = pixelBuffer
                            self.analyzeCurrentImage()
                            
                            DispatchQueue.main.async {
                                rootView.fill(image: image)
                            }
                        }
                    }
                    
                    self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = nil
                }
            }, photoProcessingHandler: { animate in
                // Animates a spinner while photo is processing
                if animate {
                    rootView.showLoadingView()
                } else {
                    rootView.hideLoadingView()
                }
            }
            )
            
            // The photo output holds a weak reference to the photo capture delegate and stores it in an array to maintain a strong reference.
            self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = photoCaptureProcessor
            self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
        }
    }
    
    @objc func onRemovePhoto(_ sender: UIButton) {
        let index = sender.tag - 1
        
        if let rootView = rootView, let collectionView = rootView.photosCollectionView, index >= 0, index < photos.count {
            photos.remove(at: index)
            
            collectionView.reloadData()
        }
    }
    
    //MARK:- UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VMRecognizingPhotosCell",
        for: indexPath) as! VMRecognizingPhotosCell
        let index = indexPath.row
        
        if (photos.count > index) {
//            let image = photos[index]
//            
//            cell.fill(image: image, deleteTarget: self, action: #selector(onRemovePhoto(_:)), tag: index+1)
        }
        
        return cell
    }
    
    //MARK:- UICollectionViewDelegate
    
    //MARK:- Private
    func setupAVCaptureSession() {
        if setupResult != .success {
            return
        }
        
        session.beginConfiguration()
        session.sessionPreset = .vga640x480
        
        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            // Choose the back dual camera, if available, otherwise default to a wide angle camera.
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                // If a rear dual camera is not available, default to the rear wide angle camera.
                defaultVideoDevice = backCameraDevice
            }
            
            guard let videoDevice = defaultVideoDevice else
            {
                print("Default video device is unavailable.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                
                return
            }
            
            try videoDevice.lockForConfiguration()
            videoDevice.focusMode = .continuousAutoFocus
            videoDevice.unlockForConfiguration()
            
            guard let rootView = rootView, let previewView = rootView.previewView else
            {
                return
            }
            
            let captureDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(captureDeviceInput) {
                session.addInput(captureDeviceInput)
                self.captureDeviceInput = captureDeviceInput
                
                DispatchQueue.main.async {
                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    
                    if self.windowOrientation != .unknown {
                        if let videoOrientation = AVCaptureVideoOrientation(rawValue: self.windowOrientation.rawValue) {
                            initialVideoOrientation = videoOrientation
                        }
                    }
                    
                    previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
                }
            } else {
                print("Couldn't add video device input to the session.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        } catch {
            print("Couldn't create video device input: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            
            return
        }
        
        // Add the photo output.
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        } else {
            print("Could not add photo output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            
            return
        }
        
        let captureConnection = photoOutput.connection(with: .video)
        captureConnection?.isEnabled = true
        
        session.commitConfiguration()
    }
    
    @discardableResult
    func setupVision() -> NSError? {
        // Setup Vision parts.
        let error: NSError! = nil
        
        // Setup barcode detection.
        let barcodeDetection = VNDetectBarcodesRequest(completionHandler: { [unowned self](request, error) in
            if let results = request.results as? [VNBarcodeObservation] {
                if let mainBarcode = results.first {
                    if let payloadString = mainBarcode.payloadStringValue {
                        self.showProductInfo(payloadString)
                    }
                }
            }
        })
        
        analysisRequests = ([barcodeDetection])
        
        // Setup a classification request.
        guard let modelURL = Bundle.main.url(forResource: "mushroomClassifier16", withExtension: "mlmodelc") else {
            return NSError(domain: "VisionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "The model file is missing."])
        }
        
        guard let objectRecognition = createClassificationRequest(modelURL: modelURL) else {
            return NSError(domain: "VMMimageCaptureViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "The classification request failed."])
        }
        
        analysisRequests.append(objectRecognition)
        
        return error
    }
    
    private func createClassificationRequest(modelURL: URL) -> VNCoreMLRequest? {
        do {
            let objectClassifier = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let classificationRequest = VNCoreMLRequest(model: objectClassifier, completionHandler: { [unowned self](request, error) in
                var title = "There is no mushroom on the photo"
                
                if let results = request.results as? [VNClassificationObservation],
                   let firstResult = results.first {
                    print("\(firstResult.identifier) : \(firstResult.confidence)")
                    if firstResult.confidence > 0.85 {
                        self.showProductInfo(firstResult.identifier)
                        
                        return
                    }
                    
                    #warning("mock for debugging the next view. Unkomment")
                    self.showProductInfo("gyromitra_esculenta")
                    return
                    //title = "Cannot recognize the mushroom"
                }
                
                // show alert
                DispatchQueue.main.async {[weak self] in
                    guard let strongSelf = self else { return }
                    let alert = UIAlertController(title: title,
                                                  message: "",
                                                  preferredStyle: .alert)
                    let action = UIAlertAction(title: "Continue",
                                               style: .default) { (action) in
                        guard let rootView = strongSelf.rootView else { return }
                        rootView.clearImage(animated: true)
                    }
                    
                    alert.addAction(action)
                    strongSelf.present(alert, animated: true)
                }
            })
            
            return classificationRequest
            
        } catch let error as NSError {
            print("Model failed to load: \(error).")
            return nil
        }
    }
    
    private func startCaptureSession() {
        session.startRunning()
    }
    
    private func showDetectionOverlay(_ visible: Bool) {
        guard let rootView = rootView, let previewView = rootView.previewView
        else { return }
        
        DispatchQueue.main.async(execute: {
            visible ? previewView.showDetectionOberlay() : previewView.hideDetectionOberlay()
        })
    }
    
    private func analyzeCurrentImage() {
        // Most computer vision tasks are not rotation-agnostic, so it is important to pass in the orientation of the image with respect to device.
        let orientation = exifOrientationFromDeviceOrientation()
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: currentlyAnalyzedPixelBuffer!, orientation: orientation)
        visionQueue.async {
            do {
                // Release the pixel buffer when done, allowing the next buffer to be processed.
                defer {
                    self.currentlyAnalyzedPixelBuffer = nil
                }
                
                try requestHandler.perform(self.analysisRequests)
            } catch {
                print("Error: Vision request failed with error \"\(error)\"")
            }
        }
    }
    
    private func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation
        
        switch curDeviceOrientation {
        case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, Home button on the top
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, Home button on the right
            exifOrientation = .upMirrored
        case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, Home button on the left
            exifOrientation = .down
        case UIDeviceOrientation.portrait:            // Device oriented vertically, Home button on the bottom
            exifOrientation = .up
        default:
            exifOrientation = .up
        }
        
        return exifOrientation
    }
    
    fileprivate func showProductInfo(_ identifier: String) {
        // Perform all UI updates on the main queue.
        DispatchQueue.main.async(execute: {
            if self.resultViewShown {
                return
            }
            
            guard let rootView = self.rootView else { return }
            rootView.clearImage(animated: false)
            
            self.resultViewShown = true
            self.performSegue(withIdentifier: "showProductSegue", sender: identifier)
        })
    }
    
    private func subscribeNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionWasInterrupted),
                                               name: .AVCaptureSessionWasInterrupted,
                                               object: session)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionInterruptionEnded),
                                               name: .AVCaptureSessionInterruptionEnded,
                                               object: session)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionRuntimeError(notification:)),
                                               name: .AVCaptureSessionRuntimeError,
                                               object: session)
    }
    
    private func unsubscribeNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .AVCaptureSessionInterruptionEnded,
                                                  object: session)
        NotificationCenter.default.removeObserver(self,
                                                  name: .AVCaptureSessionWasInterrupted,
                                                  object: session)
        NotificationCenter.default.removeObserver(self,
                                                  name: .AVCaptureSessionRuntimeError,
                                                  object: session)
    }
    
    @objc
    private func sessionWasInterrupted(notification: NSNotification) {
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
            let reasonIntegerValue = userInfoValue.integerValue,
            let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue)
        {
            print("Capture session was interrupted with reason \(reason)")
            
            var showResumeButton = false
            if reason == .audioDeviceInUseByAnotherClient || reason == .videoDeviceInUseByAnotherClient {
                showResumeButton = true
            } else if reason == .videoDeviceNotAvailableWithMultipleForegroundApps {
                // Fade-in a label to inform the user that the camera is unavailable.
            }
            
            if showResumeButton {
                // Fade-in a button to enable the user to try to resume the session running.
            }
        }
    }
    
    @objc
    private func sessionInterruptionEnded(notification: NSNotification) {
        print("Capture session interruption ended")
        
        sessionQueue.async {
            self.session.startRunning()
            self.isSessionRunning = self.session.isRunning
            if !self.session.isRunning {
                DispatchQueue.main.async {
                    let message = NSLocalizedString("Unable to resume", comment: "Alert message when unable to resume the session running")
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil)
                    alertController.addAction(cancelAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            } else {
                DispatchQueue.main.async {
                    //update rootView if needed
                }
            }
        }
    }
    
    @objc
    func sessionRuntimeError(notification: NSNotification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }
        
        print("Capture session runtime error: \(error)")
        // If media services were reset, and the last start succeeded, restart the session.
        if error.code == .mediaServicesWereReset {
            sessionQueue.async {
                if self.isSessionRunning {
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                } else {
                    DispatchQueue.main.async {
                        //update rootView if needed
                    }
                }
            }
        } else {
            //update rootView if needed
        }
    }
    
    fileprivate func resetTranspositionHistory() {
        transpositionHistoryPoints.removeAll()
    }
    
    fileprivate func recordTransposition(_ point: CGPoint) {
        transpositionHistoryPoints.append(point)
        
        if transpositionHistoryPoints.count > maximumHistoryLength {
            transpositionHistoryPoints.removeFirst()
        }
    }
    
    fileprivate func sceneStabilityAchieved() -> Bool {
        // Determine if we have enough evidence of stability.
        if transpositionHistoryPoints.count == maximumHistoryLength {
            // Calculate the moving average.
            var movingAverage: CGPoint = CGPoint.zero
            
            for currentPoint in transpositionHistoryPoints {
                movingAverage.x += currentPoint.x
                movingAverage.y += currentPoint.y
            }
            
            let distance = abs(movingAverage.x) + abs(movingAverage.y)
            
            if distance < 20 {
                return true
            }
        }
        return false
    }
    
    //MARK:- AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ captureOutput: AVCaptureOutput, didDrop didDropSampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
    {
        print("The capture output dropped a frame.")
    }
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection)
    {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        guard previousPixelBuffer != nil else {
            previousPixelBuffer = pixelBuffer
            self.resetTranspositionHistory()
            
            return
        }
        
        if resultViewShown {
            return
        }
        
        let registrationRequest = VNTranslationalImageRegistrationRequest(targetedCVPixelBuffer: pixelBuffer)
        do {
            try sequenceRequestHandler.perform([ registrationRequest ], on: previousPixelBuffer!)
        } catch let error as NSError {
            print("Failed to process request: \(error.localizedDescription).")
            return
        }
        
        previousPixelBuffer = pixelBuffer
        
        if let results = registrationRequest.results {
            if let alignmentObservation = results.first as? VNImageTranslationAlignmentObservation {
                let alignmentTransform = alignmentObservation.alignmentTransform
                self.recordTransposition(CGPoint(x: alignmentTransform.tx, y: alignmentTransform.ty))
            }
        }
        
        if self.sceneStabilityAchieved() {
            showDetectionOverlay(true)
            if currentlyAnalyzedPixelBuffer == nil {
                // Retain the image buffer for Vision processing.
                currentlyAnalyzedPixelBuffer = pixelBuffer
                analyzeCurrentImage()
            }
        } else {
            showDetectionOverlay(false)
        }
    }
}
