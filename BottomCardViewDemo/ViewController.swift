//
//  ViewController.swift
//  BottomCardViewDemo
//
//  Created by Prashant on 16/11/18.
//  Copyright © 2018 Prashant. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    var cardViewController:CardViewController!
    
    var cardHeight:CGFloat  {
        return self.view.frame.height * 0.6
    }
    var cardHandleAreaHeight:CGFloat = 65
    
    enum CardState {
        case expanded
        case collpased
    }

    var cardVisible = false
    var nextState:CardState {
        return cardVisible ? .collpased : .expanded
    }
    
    
    // Animation
    var animations:[UIViewPropertyAnimator] = []
    var currentAnimationProgress:CGFloat = 0
    var animationProgressWhenIntrupped:CGFloat = 0
    
    
    // visual effects
    
    var visualEffectView: UIVisualEffectView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCardView()
    }

    func setupCardView() {
        visualEffectView = UIVisualEffectView(frame: self.view.bounds)
        self.view.addSubview(visualEffectView)

        cardViewController = CardViewController(nibName:"CardViewController",bundle:nil)
        self.addChild(cardViewController)
        self.view.addSubview(cardViewController.view)
        cardViewController.view.frame = CGRect(x:0,y:self.view.frame.height - cardHandleAreaHeight,width:self.view.frame.width,height:cardHeight)
        cardViewController.view.clipsToBounds = true
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panned(recognizer:)))
        cardViewController.handlerArea.addGestureRecognizer(panGestureRecognizer)
        
        
        
    }
    
    
    
    @objc func panned(recognizer:UIPanGestureRecognizer) {
        
        switch recognizer.state {
        case .began:
            startIntractiveAnimation(state: nextState, duration: 0.9)
        case .changed:
            let translation =  recognizer.translation(in: self.cardViewController.handlerArea)
            let fractionCompleted = translation.y / cardHeight
            let fraction = cardVisible ? fractionCompleted : -fractionCompleted
            updateIntractiveAnimation(animationProgress: fraction)
        case .ended:

            continueAnimation(finalVelocity: recognizer.velocity(in: self.cardViewController.handlerArea))
        default:
            break
        }
        
    }
    
    func createAnimation(state:CardState,duration:TimeInterval) {
        
        guard animations.isEmpty else {
            print("Animation not empty")
            return
            
        }
        
        print("array count",self.animations.count)

        let cardMoveUpAnimation = UIViewPropertyAnimator.init(duration: duration, dampingRatio: 1.0) { [weak self] in
            guard let `self` = self else  {return}
            switch state {
            case .collpased:
                self.cardViewController.view.frame.origin.y = self.view.frame.height - self.cardHandleAreaHeight
            case .expanded:
                self.cardViewController.view.frame.origin.y = self.view.frame.height - self.cardHeight
            }
        }
        cardMoveUpAnimation.addCompletion { [weak self] _ in
            
            self?.cardVisible =  state ==  .collpased ? false : true
            self?.animations.removeAll()
        }
        cardMoveUpAnimation.startAnimation()
        animations.append(cardMoveUpAnimation)
        
        let cornerRadiusAnimation = UIViewPropertyAnimator(duration: duration, curve: .linear) { [weak self] in
            switch state {
            case .expanded:
                self?.cardViewController.view.layer.cornerRadius = 12
            case .collpased:
                self?.cardViewController.view.layer.cornerRadius = 0
            }
        }
        cornerRadiusAnimation.startAnimation()
        animations.append(cornerRadiusAnimation)
        
        let visualEffectAnimation = UIViewPropertyAnimator.init(duration: duration, curve: .linear) { [weak self ] in
            switch state {
            case .expanded:
                self?.visualEffectView.effect = UIBlurEffect(style: .dark)
                
            case .collpased:
                self?.visualEffectView.effect =  nil
            }
        }
        visualEffectAnimation.startAnimation()
        animations.append(visualEffectAnimation)
        
        
        
    }
    
    func startIntractiveAnimation(state:CardState,duration:TimeInterval) {
        if animations.isEmpty {
            createAnimation(state: state, duration: duration)
            // Create Animations
        }
        // Here we are pause the animation and get fraction Complete value and store it. so when use change the animation we can update animation.fractionComplete in next method
        for animation in animations {
            animation.pauseAnimation()
            animationProgressWhenIntrupped = animation.fractionComplete
        }
    }
    
    func updateIntractiveAnimation(animationProgress:CGFloat)  {
        for animation in animations {
       //     print(animationProgress + animationProgressWhenIntrupped)
            animation.fractionComplete = animationProgress + animationProgressWhenIntrupped
           // print(animation.fractionComplete)
        }
    }
    
    func continueAnimation (finalVelocity:CGPoint) {
        print(cardVisible == (finalVelocity.y < 0))
        
        
        if cardVisible == (finalVelocity.y < 0) {
            var completedFraction:CGFloat = 0
            for animation in animations {
                completedFraction = animation.fractionComplete
                animation.stopAnimation(true)

            }
            animations.removeAll()
            self.cardVisible =  !self.cardVisible
            self.createAnimation(state: nextState, duration: TimeInterval(completedFraction * 0.9))
            
        } else {
            for animation in animations {
                animation.continueAnimation(withTimingParameters: nil, durationFactor: 0)
                
            }
        }
    }
    
    
    

}

