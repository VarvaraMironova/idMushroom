//
//  UIView+CuttCorner.swift
//  VMAnimationTest1
//
//  Created by Varvara Myronova on 10/1/19.
//  Copyright © 2019 Varvara Myronova. All rights reserved.
//

import UIKit

extension UIView {
    
    public enum Corner: Int {
        case TopRight
        case TopLeft
        case Top
        case BottomRight
        case BottomLeft
        case Bottom
        case All
    }
    
    public func roundCorner(corner: Corner, radius: CGFloat = 20.0) {
        var path: UIBezierPath?
        let size = CGSize(width: radius,
                          height: radius)
        
        switch corner {
        case .TopLeft:
            path = UIBezierPath(roundedRect: self.bounds,
                                byRoundingCorners: [UIRectCorner.topLeft],
                                cornerRadii: size)
            
        case .TopRight:
            path = UIBezierPath(roundedRect: self.bounds,
                                byRoundingCorners: [UIRectCorner.topRight],
                                cornerRadii: size)
        
        case .Top:
            path = UIBezierPath(roundedRect: self.bounds,
                                byRoundingCorners: [UIRectCorner.topRight, UIRectCorner.topLeft],
                                cornerRadii: size)
            
        case .BottomLeft:
            path = UIBezierPath(roundedRect: self.bounds,
                                byRoundingCorners: [UIRectCorner.bottomLeft],
                                cornerRadii: size)
            
        case .BottomRight:
            path = UIBezierPath(roundedRect: self.bounds,
                                byRoundingCorners: [UIRectCorner.bottomRight],
                                cornerRadii: size)
            
        case .Bottom:
            path = UIBezierPath(roundedRect: self.bounds,
                                byRoundingCorners: [UIRectCorner.bottomRight, UIRectCorner.bottomLeft],
                                cornerRadii: size)
            
        case .All:
            path = UIBezierPath(roundedRect: self.bounds,
                                byRoundingCorners: [UIRectCorner.allCorners],
                                cornerRadii: size)
        }
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path?.cgPath
        self.layer.mask = maskLayer
    }
    
    public func cutCorner(corner: Corner, length: CGFloat = 20.0) {
        let maskLayer = CAShapeLayer()
        var path: CGPath?
        
        switch corner {
        case .All:
            path = self.anglePathWithCornerSizes(topLeft: length,
                                                 topRight: length,
                                                 bottomLeft: length,
                                                 bottomRight: length)
        case .TopRight:
            path = self.anglePathWithCornerSizes(topLeft: 0.0,
                                                 topRight: length,
                                                 bottomLeft: 0.0,
                                                 bottomRight: 0.0)
        case .TopLeft:
            path = self.anglePathWithCornerSizes(topLeft: length,
                                                 topRight: 0.0,
                                                 bottomLeft: 0.0,
                                                 bottomRight: 0.0)
        case .Top:
            path = self.anglePathWithCornerSizes(topLeft: length,
                                                 topRight: length,
                                                 bottomLeft: 0.0,
                                                 bottomRight: 0.0)
            
        case .BottomRight:
            path = self.anglePathWithCornerSizes(topLeft: 0.0,
                                                 topRight: 0.0,
                                                 bottomLeft: 0.0,
                                                 bottomRight: length)
        case .BottomLeft:
            path = self.anglePathWithCornerSizes(topLeft: 0.0,
                                                 topRight: 0.0,
                                                 bottomLeft: length,
                                                 bottomRight: 0.0)
        
        case .Bottom:
            path = self.anglePathWithCornerSizes(topLeft: 0.0,
                                                 topRight: 0.0,
                                                 bottomLeft: length,
                                                 bottomRight: length)
        }
        
        maskLayer.path = path
        self.layer.mask = maskLayer
    }
    
    private func anglePathWithCornerSizes(topLeft tl: CGFloat,
                                          topRight tr: CGFloat,
                                          bottomLeft bl: CGFloat,
                                          bottomRight br: CGFloat) -> CGPath
    {
        var points = [CGPoint]()
        let rect = self.bounds
        let rectSize = rect.size
        let height = rectSize.height
        let width = rectSize.width
        let origin = rect.origin
        let X = origin.x
        let Y = origin.y
        
        points.append(CGPoint(x: X + tl, y: Y))
        points.append(CGPoint(x: X + width - tr, y: Y))
        points.append(CGPoint(x: X + width, y: Y + tr))
        points.append(CGPoint(x: X + width, y: Y + height - br))
        points.append(CGPoint(x: X + width - br, y: Y + height))
        points.append(CGPoint(x: X + bl, y: Y + height))
        points.append(CGPoint(x: X, y: Y + height - bl))
        points.append(CGPoint(x: X, y: Y + tl))
        
        let path = CGMutablePath()
        path.move(to: points.first!)
        
        for point in points {
            if point != points.first {
                path.addLine(to: point)
            }
        }
        
        path.addLine(to: points.first!)
        
        return path
    }
    
    public func drawShadow(opacity: Float = 0.5, shadowOffset: CGSize = CGSize(width: 10.0, height: 10.0)) {
        let layer = self.layer as CALayer
        layer.shadowPath =
            UIBezierPath(roundedRect: self.bounds,
                         cornerRadius: layer.cornerRadius).cgPath
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = shadowOffset
        layer.shadowRadius = 1
        layer.masksToBounds = false
    }
}
