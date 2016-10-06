//
//  KRPieChart.swift
//  Pods
//
//  Created by Joshua Park on 8/8/16.
//
//

import UIKit
import KRTimingFunction

extension CGPoint {
    func getPointFrom(radius: CGFloat, angle: CGFloat) -> CGPoint {
        return CGPoint(x: x + radius * cos(angle), y: y + radius * sin(angle))
    }
}

public enum KRPieChartAnimationStyle {
    case sequentialCW
    case sequentialCCW
    case simultaneousCW
    case simultaneousCCW
}

public enum AnimationFunction {
    case linear
    
    case easeInSine
    case easeOutSine
    case easeInOutSine
    
    case easeInQuad
    case easeOutQuad
    case easeInOutQuad
    
    case easeInCubic
    case easeOutCubic
    case easeInOutCubic
    
    case easeInQuart
    case easeOutQuart
    case easeInOutQuart
    
    case easeInQuint
    case easeOutQuint
    case easeInOutQuint
    
    case easeInExpo
    case easeOutExpo
    case easeInOutExpo
    
    case easeInCirc
    case easeOutCirc
    case easeInOutCirc
    
    case easeInBack
    case easeOutBack
    case easeInOutBack
    
    case easeInElastic
    case easeOutElastic
    case easeInOutElastic
    
    case easeInBounce
    case easeOutBounce
    case easeInOutBounce
}

private let LAYER_ID_SEGMENT = "KRPieSegment"

open class KRPieChart: UIView {
    open var innerRadius: CGFloat = 0.0
    
    open var insets = UIEdgeInsets.zero
    open var segmentBorderColor = UIColor.clear
    open var segmentBorderWidth = CGFloat(0.0)
    
    fileprivate var _segmentLayers: [CALayer]!
    fileprivate let drawingQueue = DispatchQueue(label: "com.krpiechart.drawing_queue", attributes: [])
    
    open func setSegments(_ segments: [CGFloat], colors: [UIColor]) {
        self.drawingQueue.async {
            assert(segments.count == colors.count, "The number of elements in `segments` and `colors` must be the same.")
            assert(round(segments.reduce(CGFloat(0.0), +)*10.0) / 10.0 == CGFloat(1.0), "The sum of elements in `segments` must be 1.0: \(segments.reduce(CGFloat(0.0), +))")
            
            if let sublayers = self.layer.sublayers {
                for layer in sublayers { if layer.name == LAYER_ID_SEGMENT { layer.removeFromSuperlayer() } }
            }
            
            let width = self.bounds.width - (self.insets.left + self.insets.right)
            let height = self.bounds.height - (self.insets.top + self.insets.bottom)
            
            assert(width == height, "Width and height don't match.\n1. Check bounds: \(self.bounds).\n2. Check insets: \(self.insets).\n3. Ensure that `bounds.width - (horizontal insets)` == `bounds.height - (vertical insets)`")
            
            let frame = CGRect(x: self.insets.left, y: self.insets.top, width: width, height: height)
            let radius = width / 2.0 - (self.segmentBorderWidth / 2.0)
            let innerRadius = self.innerRadius + (self.segmentBorderWidth / 2.0)
            
            assert(radius > innerRadius, "Inner radius (\(innerRadius)) cannot be bigger than the outer radius (\(radius)).")
            
            self._segmentLayers = [CALayer]()
            
            let center = CGPoint(x: frame.midX, y: frame.midY)
            var startAngle = CGFloat(1.5 * M_PI)
            
            for i in 0 ..< segments.count {
                let segmentLayer = CALayer()
                segmentLayer.frame = frame
                segmentLayer.name = LAYER_ID_SEGMENT
                
                let endAngle = startAngle + segments[i] * CGFloat(M_PI * 2)
                let path = UIBezierPath()
                path.move(to: center.getPointFrom(radius: radius, angle: startAngle))
                path.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
                path.addLine(to: center.getPointFrom(radius: innerRadius, angle: endAngle))
                path.addArc(withCenter: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: false)
                path.addLine(to: center.getPointFrom(radius: radius, angle: startAngle))
                path.lineWidth = self.segmentBorderWidth
                
                let size = CGSize(width: width, height: height)
                UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
                let ctx = UIGraphicsGetCurrentContext()
                
                ctx?.addPath(path.cgPath)
                ctx?.setFillColor(colors[i].cgColor)
                ctx?.setLineWidth(self.segmentBorderWidth)
                ctx?.setStrokeColor(self.segmentBorderColor.cgColor)
                ctx?.drawPath(using: .fillStroke)
                
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                segmentLayer.contents = image?.cgImage
                
                self._segmentLayers.append(segmentLayer)
                startAngle = endAngle
            }
        }
    }
    
    open func displayChart() {
        self.drawingQueue.async {
            DispatchQueue.main.async {
                for segmentLayer in self._segmentLayers { self.layer.addSublayer(segmentLayer) }
            }
        }
    }
    
    open func hideChart() {
        self.drawingQueue.async {
            DispatchQueue.main.async {
                for segmentLayer in self._segmentLayers { segmentLayer.isHidden = true }
            }
        }
    }
    
    open func removeChart() {
        self.drawingQueue.async {
            DispatchQueue.main.async {
                for segmentLayer in self._segmentLayers { segmentLayer.removeFromSuperlayer() }
            }
        }
    }
    
    open func animateWithDuration(_ duration: Double, style: KRPieChartAnimationStyle, function: AnimationFunction = .easeInOutCubic, completion: (() -> Void)?) {
        self.drawingQueue.async {
            switch style {
            case .sequentialCW, .sequentialCCW:
                var imageGraph: UIImage!
                var values = [CGImage]()
                let tempView = UIView(frame: self.bounds)
                for sublayer in self._segmentLayers { tempView.layer.addSublayer(sublayer) }
                
                UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0.0)
                var ctx = UIGraphicsGetCurrentContext()
                tempView.layer.render(in: ctx!)
                imageGraph = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0.0)
                ctx = UIGraphicsGetCurrentContext()
                
                let numberOfFrames = CGFloat(60.0 * duration)
                
                let center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
                let radius = (self.bounds.width - (self.insets.left + self.insets.right)) / 2.0
                let startAngle = CGFloat(1.5 * M_PI)
                let startPoint = CGPoint(x: center.x, y: 0.0)
                
                for i in 0 ... Int(numberOfFrames) {
                    ctx?.saveGState()
                    let relativeTime = getComputedTime(function, relativeTime: CGFloat(i) / numberOfFrames, duration: duration)
                    let endAngle = style == .sequentialCW ? startAngle + relativeTime * CGFloat(M_PI * 2) : startAngle - relativeTime * CGFloat(M_PI * 2)
                    
                    let path = UIBezierPath()
                    path.move(to: startPoint)
                    path.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: style == .sequentialCW)
                    path.addLine(to: center)
                    path.addLine(to: startPoint)
                    path.close()
                    
                    ctx?.addPath(path.cgPath)
                    ctx?.clip()
                    ctx?.translateBy(x: 0.0, y: self.bounds.height)
                    ctx?.scaleBy(x: 1.0, y: -1.0)
                    ctx?.draw(imageGraph.cgImage!, in: self.bounds)
                    
                    guard let animImage = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else {
                        print("Failed to get a image of pie chart. Check \(#file) \(#line)")
                        return
                    }
                    values.append(animImage)
                    ctx?.restoreGState()
                }
                
                UIGraphicsEndImageContext()
                
                let anim = CAKeyframeAnimation(keyPath: "contents")
                anim.duration = duration
                anim.values = values
                anim.fillMode = kCAFillModeForwards
                anim.isRemovedOnCompletion = false
                
                DispatchQueue.main.async {
                    CATransaction.begin()
                    CATransaction.setCompletionBlock({
                        for segmentLayer in self._segmentLayers { self.layer.addSublayer(segmentLayer) }
                        self.layer.removeAnimation(forKey: "contents")
                        completion?()
                    })
                    
                    self.layer.add(anim, forKey: "contents")
                    
                    CATransaction.commit()
                }
            default: break
            }
        }
        
    }
}

private func getComputedTime(_ function: AnimationFunction, relativeTime: CGFloat, duration: Double) -> CGFloat {
    switch function {
    case .linear:
        return CGFloat(TimingFunction.Linear(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .easeInQuad:
        return CGFloat(TimingFunction.EaseInQuad(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .easeOutQuad:
        return CGFloat(TimingFunction.EaseOutQuad(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .easeInOutQuad:
        return CGFloat(TimingFunction.EaseInOutQuad(rt: Double(relativeTime), b: 0.0, c: 1.0))
        
    case .easeInCubic:
        return CGFloat(TimingFunction.EaseInCubic(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .easeOutCubic:
        return CGFloat(TimingFunction.EaseOutCubic(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .easeInOutCubic:
        return CGFloat(TimingFunction.EaseInOutCubic(rt: Double(relativeTime), b: 0.0, c: 1.0))
        
    case .easeInQuart:
        return CGFloat(TimingFunction.EaseInQuart(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .easeOutQuart:
        return CGFloat(TimingFunction.EaseOutQuart(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .easeInOutQuart:
        return CGFloat(TimingFunction.EaseInOutQuart(rt: Double(relativeTime), b: 0.0, c: 1.0))
        
    case .easeInQuint:
        return CGFloat(TimingFunction.EaseInQuint(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .easeOutQuint:
        return CGFloat(TimingFunction.EaseOutQuint(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .easeInOutQuint:
        return CGFloat(TimingFunction.EaseInOutQuint(rt: Double(relativeTime), b: 0.0, c: 1.0))
        
    case .easeInSine:
        return CGFloat(TimingFunction.EaseInSine(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .easeOutSine:
        return CGFloat(TimingFunction.EaseOutSine(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .easeInOutSine:
        return CGFloat(TimingFunction.EaseInOutSine(rt: Double(relativeTime), b: 0.0, c: 1.0))
        
    case .easeInExpo:
        return CGFloat(TimingFunction.EaseInExpo(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .easeOutExpo:
        return CGFloat(TimingFunction.EaseOutExpo(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .easeInOutExpo:
        return CGFloat(TimingFunction.EaseInOutExpo(rt: Double(relativeTime), b: 0.0, c: 1.0))
        
    case .easeInCirc:
        return CGFloat(TimingFunction.EaseInCirc(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .easeOutCirc:
        return CGFloat(TimingFunction.EaseOutCirc(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .easeInOutCirc:
        return CGFloat(TimingFunction.EaseInOutCirc(rt: Double(relativeTime), b: 0.0, c: 1.0))
        
    case .easeInElastic:
        return CGFloat(TimingFunction.EaseInElastic(rt: Double(relativeTime), b: 0.0, c: 1.0, d: duration))
    case .easeOutElastic:
        return CGFloat(TimingFunction.EaseOutElastic(rt: Double(relativeTime), b: 0.0, c: 1.0, d: duration))
    case .easeInOutElastic:
        return CGFloat(TimingFunction.EaseInOutElastic(rt: Double(relativeTime), b: 0.0, c: 1.0, d: duration))
        
    case .easeInBack:
        return CGFloat(TimingFunction.EaseInBack(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .easeOutBack:
        return CGFloat(TimingFunction.EaseOutBack(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .easeInOutBack:
        return CGFloat(TimingFunction.EaseInOutBack(rt: Double(relativeTime), b: 0.0, c: 1.0))
        
    case .easeInBounce:
        return CGFloat(TimingFunction.EaseInBounce(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .easeOutBounce:
        return CGFloat(TimingFunction.EaseOutBounce(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .easeInOutBounce:
        return CGFloat(TimingFunction.EaseInOutBounce(rt: Double(relativeTime), b: 0.0, c: 1.0))
    }
}
