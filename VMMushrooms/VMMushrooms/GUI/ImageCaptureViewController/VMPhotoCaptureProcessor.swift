//
//  VMPhotoCaptureProcessor.swift
//  VMMushrooms
//
//  Created by Varvara Myronova on 1/9/20.
//  Copyright © 2020 Varvara Myronova. All rights reserved.
//

import AVFoundation
import Photos
import UIKit

class VMPhotoCaptureProcessor: NSObject {
    var pixelBuffer : CVPixelBuffer?
    var photo       : UIImage?
    
    private(set) var requestedPhotoSettings: AVCapturePhotoSettings
        
        lazy var context = CIContext()
        
        private let completionHandler: (VMPhotoCaptureProcessor, Error?) -> Void
        private let photoProcessingHandler: (Bool) -> Void
        
        private var error : NSError?
        private var maxPhotoProcessingTime: CMTime?
        
        init(with requestedPhotoSettings: AVCapturePhotoSettings,
             willCapturePhotoAnimation: @escaping () -> Void,
             completionHandler: @escaping (VMPhotoCaptureProcessor, Error?) -> Void,
             photoProcessingHandler: @escaping (Bool) -> Void) {
            self.requestedPhotoSettings = requestedPhotoSettings
            self.completionHandler = completionHandler
            self.photoProcessingHandler = photoProcessingHandler
        }
        
        private func didFinish() {
            completionHandler(self, error)
        }
        
    }

    extension VMPhotoCaptureProcessor: AVCapturePhotoCaptureDelegate {
        /// - Tag: WillBeginCapture
        func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
            if #available(iOS 13.0, *) {
                maxPhotoProcessingTime = resolvedSettings.photoProcessingTimeRange.start + resolvedSettings.photoProcessingTimeRange.duration
            } else {
                maxPhotoProcessingTime = CMTime(seconds: 1, preferredTimescale: 1)
            }
        }
        
        /// - Tag: WillCapturePhoto
        func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
            //willCapturePhotoAnimation()
            
            guard let maxPhotoProcessingTime = maxPhotoProcessingTime else {
                return
            }
            
            // Show a spinner if processing time exceeds one second.
            let oneSecond = CMTime(seconds: 1, preferredTimescale: 1)
            if maxPhotoProcessingTime > oneSecond {
                photoProcessingHandler(true)
            }
        }
        
        /// - Tag: DidFinishProcessingPhoto
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            photoProcessingHandler(false)
            
            if let error = error {
                print("Error capturing photo: \(error)")
            } else {
                pixelBuffer = photo.pixelBuffer
                
                if let data = photo.fileDataRepresentation() {
                    self.photo = UIImage(data: data)
                }
            }
        }
        
        /// - Tag: DidFinishCapture
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?)
        {
            if let error = error {
                print("Error capturing photo: \(error)")
                didFinish()
                return
            }

            guard let _ = pixelBuffer else {
                print("No photo data resource")
                didFinish()
                return
            }
            
            guard let _ = photo else {
                print("No photo")
                didFinish()
                return
            }
            
            didFinish()
        }
    }
