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
    func getPointFromRadius(radius: CGFloat, angle: CGFloat) -> CGPoint {
        return CGPointMake(x + radius * cos(angle), y + radius * sin(angle))
    }
}

public enum KRPieChartAnimationStyle {
    case SequentialCW
    case SequentialCCW
    case SimultaneousCW
    case SimultaneousCCW
}

public enum AnimationFunction {
    case Linear
    
    case EaseInSine
    case EaseOutSine
    case EaseInOutSine
    
    case EaseInQuad
    case EaseOutQuad
    case EaseInOutQuad
    
    case EaseInCubic
    case EaseOutCubic
    case EaseInOutCubic
    
    case EaseInQuart
    case EaseOutQuart
    case EaseInOutQuart
    
    case EaseInQuint
    case EaseOutQuint
    case EaseInOutQuint
    
    case EaseInExpo
    case EaseOutExpo
    case EaseInOutExpo
    
    case EaseInCirc
    case EaseOutCirc
    case EaseInOutCirc
    
    case EaseInBack
    case EaseOutBack
    case EaseInOutBack
    
    case EaseInElastic
    case EaseOutElastic
    case EaseInOutElastic
    
    case EaseInBounce
    case EaseOutBounce
    case EaseInOutBounce
}

private let LAYER_ID_SEGMENT = "KRPieSegment"

public class KRPieChart: UIView {
    public var innerRadius: CGFloat = 0.0
    
    public var insets = UIEdgeInsetsZero
    public var segmentBorderColor = UIColor.clearColor()
    public var segmentBorderWidth = CGFloat(0.0)
    
    private var _segmentLayers: [CALayer]!
    private let drawingQueue = dispatch_queue_create("com.krpiechart.drawing_queue", DISPATCH_QUEUE_SERIAL)
    
    public func setSegments(segments: [CGFloat], colors: [UIColor]) {
        dispatch_async(self.drawingQueue) {
            assert(segments.count == colors.count, "The number of elements in `segments` and `colors` must be the same.")
            assert(round(segments.reduce(CGFloat(0.0), combine: +)*10.0) / 10.0 == CGFloat(1.0), "The sum of elements in `segments` must be 1.0: \(segments.reduce(CGFloat(0.0), combine: +))")
            
            if let sublayers = self.layer.sublayers {
                for layer in sublayers { if layer.name == LAYER_ID_SEGMENT { layer.removeFromSuperlayer() } }
            }
            
            let width = self.bounds.width - (self.insets.left + self.insets.right)
            let height = self.bounds.height - (self.insets.top + self.insets.bottom)
            
            assert(width == height, "Width and height don't match.\n1. Check bounds: \(self.bounds).\n2. Check insets: \(self.insets).\n3. Ensure that `bounds.width - (horizontal insets)` == `bounds.height - (vertical insets)`")
            
            let frame = CGRectMake(self.insets.left, self.insets.top, width, height)
            let radius = width / 2.0 - (self.segmentBorderWidth / 2.0)
            let innerRadius = self.innerRadius + (self.segmentBorderWidth / 2.0)
            
            assert(radius > innerRadius, "Inner radius (\(innerRadius)) cannot be bigger than the outer radius (\(radius)).")
            
            self._segmentLayers = [CALayer]()
            
            let center = CGPointMake(frame.midX, frame.midY)
            var startAngle = CGFloat(1.5 * M_PI)
            
            for i in 0 ..< segments.count {
                let segmentLayer = CALayer()
                segmentLayer.frame = frame
                segmentLayer.name = LAYER_ID_SEGMENT
                
                let endAngle = startAngle + segments[i] * CGFloat(M_PI * 2)
                let path = UIBezierPath()
                path.moveToPoint(center.getPointFromRadius(radius, angle: startAngle))
                path.addArcWithCenter(center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
                path.addLineToPoint(center.getPointFromRadius(innerRadius, angle: endAngle))
                path.addArcWithCenter(center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: false)
                path.addLineToPoint(center.getPointFromRadius(radius, angle: startAngle))
                path.lineWidth = self.segmentBorderWidth
                
                let size = CGSizeMake(width, height)
                UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
                let ctx = UIGraphicsGetCurrentContext()
                
                CGContextAddPath(ctx, path.CGPath)
                CGContextSetFillColorWithColor(ctx, colors[i].CGColor)
                CGContextSetLineWidth(ctx, self.segmentBorderWidth)
                CGContextSetStrokeColorWithColor(ctx, self.segmentBorderColor.CGColor)
                CGContextDrawPath(ctx, .FillStroke)
                
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                segmentLayer.contents = image.CGImage
                
                self._segmentLayers.append(segmentLayer)
                startAngle = endAngle
            }
        }
    }
    
    public func displayChart() {
        dispatch_async(self.drawingQueue) {
            dispatch_async(dispatch_get_main_queue()) {
                for segmentLayer in self._segmentLayers { self.layer.addSublayer(segmentLayer) }
            }
        }
    }
    
    public func hideChart() {
        dispatch_async(self.drawingQueue) {
            dispatch_async(dispatch_get_main_queue()) {
                for segmentLayer in self._segmentLayers { segmentLayer.hidden = true }
            }
        }
    }
    
    public func removeChart() {
        dispatch_async(self.drawingQueue) {
            dispatch_async(dispatch_get_main_queue()) {
                for segmentLayer in self._segmentLayers { segmentLayer.removeFromSuperlayer() }
            }
        }
    }
    
    public func animateWithDuration(duration: Double, style: KRPieChartAnimationStyle, function: AnimationFunction = .EaseInOutCubic, completion: (() -> Void)?) {
        dispatch_async(self.drawingQueue) {
            switch style {
            case .SequentialCW, .SequentialCCW:
                var imageGraph: UIImage!
                var values = [CGImage]()
                let tempView = UIView(frame: self.bounds)
                for sublayer in self._segmentLayers { tempView.layer.addSublayer(sublayer) }
                
                UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0.0)
                var ctx = UIGraphicsGetCurrentContext()
                tempView.layer.renderInContext(ctx!)
                imageGraph = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0.0)
                ctx = UIGraphicsGetCurrentContext()
                
                let numberOfFrames = CGFloat(60.0 * duration)
                
                let center = CGPointMake(self.bounds.midX, self.bounds.midY)
                let radius = (self.bounds.width - (self.insets.left + self.insets.right)) / 2.0
                let startAngle = CGFloat(1.5 * M_PI)
                let startPoint = CGPointMake(center.x, 0.0)
                
                for i in 0 ... Int(numberOfFrames) {
                    CGContextSaveGState(ctx)
                    let relativeTime = getComputedTime(function, relativeTime: CGFloat(i) / numberOfFrames, duration: duration)
                    let endAngle = style == .SequentialCW ? startAngle + relativeTime * CGFloat(M_PI * 2) : startAngle - relativeTime * CGFloat(M_PI * 2)
                    
                    let path = UIBezierPath()
                    path.moveToPoint(startPoint)
                    path.addArcWithCenter(center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: style == .SequentialCW)
                    path.addLineToPoint(center)
                    path.addLineToPoint(startPoint)
                    path.closePath()
                    
                    CGContextAddPath(ctx, path.CGPath)
                    CGContextClip(ctx)
                    CGContextTranslateCTM(ctx, 0.0, self.bounds.height)
                    CGContextScaleCTM(ctx, 1.0, -1.0)
                    CGContextDrawImage(ctx, self.bounds, imageGraph.CGImage)
                    
                    guard let animImage = UIGraphicsGetImageFromCurrentImageContext().CGImage else {
                        print("Failed to get a image of pie chart. Check \(#file) \(#line)")
                        return
                    }
                    values.append(animImage)
                    CGContextRestoreGState(ctx)
                }
                
                UIGraphicsEndImageContext()
                
                dispatch_async(dispatch_get_main_queue()) {
                    CATransaction.begin()
                    CATransaction.setCompletionBlock({
                        self.displayChart()
                        self.layer.removeAnimationForKey("contents")
                        completion?()
                    })
                    
                    let anim = CAKeyframeAnimation(keyPath: "contents")
                    anim.duration = duration
                    anim.values = values
                    anim.fillMode = kCAFillModeForwards
                    anim.removedOnCompletion = false
                    
                    self.layer.addAnimation(anim, forKey: "contents")
                    
                    CATransaction.commit()
                }
            default: break
            }
        }
        
    }
}

private func getComputedTime(function: AnimationFunction, relativeTime: CGFloat, duration: Double) -> CGFloat {
    switch function {
    case .Linear:
        return CGFloat(TimingFunction.Linear(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .EaseInQuad:
        return CGFloat(TimingFunction.EaseInQuad(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .EaseOutQuad:
        return CGFloat(TimingFunction.EaseOutQuad(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .EaseInOutQuad:
        return CGFloat(TimingFunction.EaseInOutQuad(rt: Double(relativeTime), b: 0.0, c: 1.0))
        
    case .EaseInCubic:
        return CGFloat(TimingFunction.EaseInCubic(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .EaseOutCubic:
        return CGFloat(TimingFunction.EaseOutCubic(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .EaseInOutCubic:
        return CGFloat(TimingFunction.EaseInOutCubic(rt: Double(relativeTime), b: 0.0, c: 1.0))
        
    case .EaseInQuart:
        return CGFloat(TimingFunction.EaseInQuart(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .EaseOutQuart:
        return CGFloat(TimingFunction.EaseOutQuart(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .EaseInOutQuart:
        return CGFloat(TimingFunction.EaseInOutQuart(rt: Double(relativeTime), b: 0.0, c: 1.0))
        
    case .EaseInQuint:
        return CGFloat(TimingFunction.EaseInQuint(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .EaseOutQuint:
        return CGFloat(TimingFunction.EaseOutQuint(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .EaseInOutQuint:
        return CGFloat(TimingFunction.EaseInOutQuint(rt: Double(relativeTime), b: 0.0, c: 1.0))
        
    case .EaseInSine:
        return CGFloat(TimingFunction.EaseInSine(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .EaseOutSine:
        return CGFloat(TimingFunction.EaseOutSine(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .EaseInOutSine:
        return CGFloat(TimingFunction.EaseInOutSine(rt: Double(relativeTime), b: 0.0, c: 1.0))
        
    case .EaseInExpo:
        return CGFloat(TimingFunction.EaseInExpo(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .EaseOutExpo:
        return CGFloat(TimingFunction.EaseOutExpo(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .EaseInOutExpo:
        return CGFloat(TimingFunction.EaseInOutExpo(rt: Double(relativeTime), b: 0.0, c: 1.0))
        
    case .EaseInCirc:
        return CGFloat(TimingFunction.EaseInCirc(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .EaseOutCirc:
        return CGFloat(TimingFunction.EaseOutCirc(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .EaseInOutCirc:
        return CGFloat(TimingFunction.EaseInOutCirc(rt: Double(relativeTime), b: 0.0, c: 1.0))
        
    case .EaseInElastic:
        return CGFloat(TimingFunction.EaseInElastic(rt: Double(relativeTime), b: 0.0, c: 1.0, d: duration))
    case .EaseOutElastic:
        return CGFloat(TimingFunction.EaseOutElastic(rt: Double(relativeTime), b: 0.0, c: 1.0, d: duration))
    case .EaseInOutElastic:
        return CGFloat(TimingFunction.EaseInOutElastic(rt: Double(relativeTime), b: 0.0, c: 1.0, d: duration))
        
    case .EaseInBack:
        return CGFloat(TimingFunction.EaseInBack(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .EaseOutBack:
        return CGFloat(TimingFunction.EaseOutBack(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .EaseInOutBack:
        return CGFloat(TimingFunction.EaseInOutBack(rt: Double(relativeTime), b: 0.0, c: 1.0))
        
    case .EaseInBounce:
        return CGFloat(TimingFunction.EaseInBounce(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .EaseOutBounce:
        return CGFloat(TimingFunction.EaseOutBounce(rt: Double(relativeTime), b: 0.0, c: 1.0))
    case .EaseInOutBounce:
        return CGFloat(TimingFunction.EaseInOutBounce(rt: Double(relativeTime), b: 0.0, c: 1.0))
    }
}