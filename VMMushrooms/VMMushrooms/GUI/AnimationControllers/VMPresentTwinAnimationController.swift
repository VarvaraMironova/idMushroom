//
//  VMPresentTwinAnimationController.swift
//  VMMushrooms
//
//  Created by Varvara Myronova on 12/18/19.
//  Copyright © 2019 Varvara Myronova. All rights reserved.
//

import UIKit

class VMPresentTwinAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    private let originFrame: CGRect
    private let finalFrame: CGRect
    private let animationView: VMTwinModelCollectionViewCell

    init(originFrame: CGRect, finalFrame: CGRect, animationView: VMTwinModelCollectionViewCell) {
        self.originFrame = originFrame
        self.animationView = animationView
        self.finalFrame = finalFrame
    }
    
    //MARK: UIViewControllerAnimatedTransitioning delegate
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    {
      return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
    {
        guard let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to),
            let snapshotView = animationView.snapshotView(afterScreenUpdates: true)
            else {
                return
        }
        
        let containerView = transitionContext.containerView
        
        snapshotView.frame = originFrame
        snapshotView.layer.masksToBounds = true
        
        containerView.addSubview(toVC.view)
        containerView.addSubview(snapshotView)
        toVC.view.isHidden = true
        
        AnimationHelper.perspectiveTransform(for: containerView)
        let duration = transitionDuration(using: transitionContext)
        
        UIView.animate(
            withDuration: duration,
            animations: {
                snapshotView.frame = self.finalFrame
                //self.snapshotView.layoutIfNeeded()
        }) { (finished) in
            if finished {
                toVC.view.isHidden = false
                snapshotView.removeFromSuperview()
                fromVC.view.layer.transform = CATransform3DIdentity
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
}
