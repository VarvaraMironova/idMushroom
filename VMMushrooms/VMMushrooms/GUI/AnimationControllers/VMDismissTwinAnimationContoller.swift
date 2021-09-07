//
//  VMTwinDismissAnimationContoller.swift
//  VMMushrooms
//
//  Created by Varvara Myronova on 12/19/19.
//  Copyright © 2019 Varvara Myronova. All rights reserved.
//

import UIKit

class VMDismissTwinAnimationContoller: NSObject, UIViewControllerAnimatedTransitioning {
    private let originFrame     : CGRect
    private let animationView   : UIView
    private let finalFrame      : CGRect
    
    let interactionController: VMSwipeInteractionController?
    
    init(originFrame: CGRect, finalFrame: CGRect, animationView: UIView, interactionController: VMSwipeInteractionController?) {
        self.originFrame = originFrame
        self.animationView = animationView
        self.finalFrame = finalFrame
        self.interactionController = interactionController
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
      return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to),
            let snapshotView = animationView.snapshotView(afterScreenUpdates: false)
            else {
                return
        }
        
        snapshotView.layer.masksToBounds = true
        snapshotView.frame = originFrame
        
        let containerView = transitionContext.containerView
        containerView.insertSubview(toVC.view, at: 0)
        containerView.addSubview(snapshotView)
        fromVC.view.isHidden = true
        
        AnimationHelper.perspectiveTransform(for: containerView)
        let duration = transitionDuration(using: transitionContext)
        
        UIView.animate(
            withDuration: duration,
            animations: {
                snapshotView.frame = self.finalFrame
                //self.snapshotView.layoutIfNeeded()
        }) { (finished) in
            fromVC.view.isHidden = false
            snapshotView.removeFromSuperview()
            
            if transitionContext.transitionWasCancelled {
              toVC.view.removeFromSuperview()
            }
            
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}
