//
//  AnimationCircleView.swift
//  Whoisspeaking
//
//  Created by RongWei Ji on 11/19/23.
//

import Foundation
import UIKit

class AnimatedCircleView: UIView {

    private let ringLayer = CAShapeLayer()

        override init(frame: CGRect) {
            super.init(frame: frame)
            setupRingLayer()
        }

        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            setupRingLayer()
        }

        private func setupRingLayer() {
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let radius = min(bounds.width, bounds.height) / 2 - 2 // Adjusted for a 4-point wide ring
            let lineWidth: CGFloat = 9
            let startAngle: CGFloat = 0
            let endAngle: CGFloat = CGFloat.pi * 2 * 7 / 8

            // Create the path for the ring
            let ringPath = UIBezierPath(arcCenter: center,
                                        radius: radius,
                                        startAngle: startAngle,
                                        endAngle: endAngle,
                                        clockwise: true)

            // Move the path to create a break
            ringPath.move(to: CGPoint(x: center.x + radius - lineWidth / 2, y: center.y))
            ringPath.addLine(to: CGPoint(x: center.x + radius + lineWidth / 2, y: center.y))

            // Apply the path to the layer
            ringLayer.path = ringPath.cgPath
            ringLayer.fillColor = UIColor.clear.cgColor
            ringLayer.strokeColor = UIColor.blue.cgColor
            ringLayer.lineWidth = lineWidth
            layer.addSublayer(ringLayer)

            // Set initial state
            stopAnimation()
        }

        func startAnimation() {
            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
            rotationAnimation.fromValue = 0
            rotationAnimation.toValue = CGFloat.pi * 2
            rotationAnimation.duration = 2
            rotationAnimation.repeatCount = .infinity
            layer.add(rotationAnimation, forKey: "rotateAnimation")
        }

        func stopAnimation() {
            layer.removeAnimation(forKey: "rotateAnimation")
        }
}
