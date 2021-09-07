//
//  VMSwipeInteractionController.swift
//  VMMushrooms
//
//  Created by Varvara Myronova on 1/9/20.
//  Copyright © 2020 Varvara Myronova. All rights reserved.
//

import UIKit

class VMSwipeInteractionController: UIPercentDrivenInteractiveTransition {
    var interactionInProgress = false

    private var shouldCompleteTransition = false
    private weak var viewController: UIViewController!

    init(viewController: UIViewController) {
      super.init()
        
      self.viewController = viewController
      prepareGestureRecognizer(in: viewController.view)
    }
    
    private func prepareGestureRecognizer(in view: UIView) {
      let gesture = UIPanGestureRecognizer(target: self,
                                           action: #selector(handleGesture(_:)))
        
      view.addGestureRecognizer(gesture)
    }
    
    @objc func handleGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view!.superview!)
        var progress = (translation.y / 200)
        progress = CGFloat(fminf(fmaxf(Float(progress), 0.0), 1.0))
        
        switch gestureRecognizer.state {
        
        case .began:
            interactionInProgress = true
            viewController.dismiss(animated: true, completion: nil)
            break
          
        case .changed:
            shouldCompleteTransition = progress > 0.5
            update(progress)
            break
          
        case .cancelled:
            interactionInProgress = false
            cancel()
            break
          
        case .ended:
            interactionInProgress = false
            
            if shouldCompleteTransition {
                finish()
            } else {
                cancel()
            }
            break
            
        default:
            break
        }
    }
}
