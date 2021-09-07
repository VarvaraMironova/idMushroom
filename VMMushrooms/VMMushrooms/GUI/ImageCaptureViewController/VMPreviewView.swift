//
//  VMPreviewView.swift
//  VMMushrooms
//
//  Created by Varvara Myronova on 1/10/20.
//  Copyright © 2020 Varvara Myronova. All rights reserved.
//

import UIKit
import AVFoundation

class VMPreviewView: UIView {
    private var detectionOverlay : CALayer!
    
    var videoPreviewLayer        : AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        return layer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        detectionOverlay = CALayer()
        
        let rect = bounds
        detectionOverlay.bounds = rect.insetBy(dx: 20, dy: 20)
        detectionOverlay.position = CGPoint(x: rect.midX, y: rect.midY)
        detectionOverlay.borderColor = UIColor(red: 239.0/255.0,
                                               green: 83.0/255.0,
                                               blue: 80.0/255.0,alpha: 1.0).cgColor
        detectionOverlay.borderWidth = 4.0
        detectionOverlay.cornerRadius = 20
        videoPreviewLayer.addSublayer(detectionOverlay)
        
        hideDetectionOberlay()
    }
    
    public func showDetectionOberlay() {
        detectionOverlay.isHidden = false
    }
    
    public func hideDetectionOberlay() {
        detectionOverlay.isHidden = true
    }

}
