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

open class KRPieChart: UIView {
    
    public enum AnimationStyle {
        case sequentialCW
        case sequentialCCW
        // TODO: Implement
        //    case simultaneousCW
        //    case simultaneousCCW
    }
    
    private static let animationKey = "contents"
    private static let layerID = "com.krpiechart.pie_segment"
    
    open var innerRadius: CGFloat = 0.0
    
    open var insets = UIEdgeInsets.zero
    open var segmentBorderColor = UIColor.clear
    open var segmentBorderWidth = CGFloat(0.0)
    
    public private(set) var segmentLayers = [CALayer]()
    
    private let drawingQueue = DispatchQueue(label: "com.krpiechart.drawing_queue",
                                             attributes: [])
    private var isDrawing = false
    
    // MARK: - Interface
    
    open func setSegments(_ segments: [CGFloat],
                          colors: [UIColor])
    {
        assert(segments.count == colors.count,
               "The number of elements in `segments` and `colors` must be the same.")
        assert(round(segments.reduce(CGFloat(0.0), +)*10.0) / 10.0 == CGFloat(1.0),
               "The sum of elements in `segments` must be 1.0: \(segments.reduce(CGFloat(0.0), +))")
        
        if let sublayers = self.layer.sublayers {
            for layer in sublayers {
                if layer.name == KRPieChart.layerID { layer.removeFromSuperlayer() }
            }
        }
        
        let bounds = self.bounds
        let width = self.bounds.width - (self.insets.left + self.insets.right)
        let height = self.bounds.height - (self.insets.top + self.insets.bottom)
        
        self.isDrawing = true
        
        self.drawingQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            
            assert(width == height,
                   """
                Width and height don't match.
                1. Check bounds: \(bounds).
                2. Check insets: \(weakSelf.insets).
                3. Ensure that `bounds.width - (horizontal insets)` == `bounds.height - (vertical insets)`
                """)
            
            let frame = CGRect(x: weakSelf.insets.left,
                               y: weakSelf.insets.top,
                               width: width,
                               height: height)
            let radius = width * 0.5 - (weakSelf.segmentBorderWidth * 0.5)
            let innerRadius = weakSelf.innerRadius + (weakSelf.segmentBorderWidth * 0.5)
            
            assert(radius > innerRadius,
                   "Inner radius (\(innerRadius)) cannot be bigger than the outer radius (\(radius)).")
            
            weakSelf.segmentLayers.removeAll()
            
            let center = CGPoint(x: frame.midX, y: frame.midY)
            var startAngle = 1.5 * CGFloat.pi
            
            for i in 0 ..< segments.count {
                let segmentLayer = CALayer()
                segmentLayer.frame = frame
                segmentLayer.name = KRPieChart.layerID
                
                let endAngle = startAngle + segments[i] * CGFloat.pi * 2
                let path = UIBezierPath()
                path.move(to: center.getPointFrom(radius: radius, angle: startAngle))
                path.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
                path.addLine(to: center.getPointFrom(radius: innerRadius, angle: endAngle))
                path.addArc(withCenter: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: false)
                path.addLine(to: center.getPointFrom(radius: radius, angle: startAngle))
                path.lineWidth = weakSelf.segmentBorderWidth
                
                let size = CGSize(width: width, height: height)
                UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
                let ctx = UIGraphicsGetCurrentContext()
                
                ctx?.addPath(path.cgPath)
                ctx?.setFillColor(colors[i].cgColor)
                ctx?.setLineWidth(weakSelf.segmentBorderWidth)
                ctx?.setStrokeColor(weakSelf.segmentBorderColor.cgColor)
                ctx?.drawPath(using: .fillStroke)
                
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                segmentLayer.contents = image?.cgImage
                
                weakSelf.segmentLayers.append(segmentLayer)
                startAngle = endAngle
            }
            
            weakSelf.isDrawing = false
        }
    }
    
    open func displayChart() {
        self.callWhenSafe {
            for segmentLayer in self.segmentLayers { self.layer.addSublayer(segmentLayer) }
            self.removeAnimation()
        }
    }
    
    open func hideChart() {
        self.callWhenSafe {
            self.removeAnimation()
            for segmentLayer in self.segmentLayers { segmentLayer.isHidden = true }
        }
    }
    
    open func removeChart() {
        self.callWhenSafe {
            self.removeAnimation()
            for segmentLayer in self.segmentLayers { segmentLayer.removeFromSuperlayer() }
        }
    }
    
    open func animateWithDuration(_ duration: Double,
                                  style: AnimationStyle,
                                  function: FunctionType = .easeInOutCubic,
                                  completion: (() -> Void)?)
    {
        
        let bounds = self.bounds
        
        self.drawingQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            
            switch style {
            case .sequentialCW, .sequentialCCW:
                var imageGraph: UIImage!
                var values = [CGImage]()
                let tempView = UIView(frame: bounds)
                for sublayer in weakSelf.segmentLayers { tempView.layer.addSublayer(sublayer) }
                
                UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
                var ctx = UIGraphicsGetCurrentContext()
                tempView.layer.render(in: ctx!)
                imageGraph = UIGraphicsGetImageFromCurrentImageContext()

                UIGraphicsEndImageContext()
                
                let numberOfFrames = CGFloat(60.0 * duration)
                
                let center = CGPoint(x: bounds.midX,
                                     y: bounds.midY)
                let radius = (bounds.width - (weakSelf.insets.left + weakSelf.insets.right)) * 0.5
                let startAngle = 1.5 * CGFloat.pi
                let startPoint = CGPoint(x: center.x, y: 0.0)
                
                UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
                ctx = UIGraphicsGetCurrentContext()
                
                for i in 0 ... Int(numberOfFrames) {
                    ctx?.saveGState()
                    
                    let relativeTime = TimingFunction.value(using: function,
                                                            rt: CGFloat(i) / numberOfFrames,
                                                            b: 0.0,
                                                            c: 1.0,
                                                            d: CGFloat(duration))
                    let endAngle = style == .sequentialCW ?
                        startAngle + relativeTime * (CGFloat.pi * 2) :
                        startAngle - relativeTime * (CGFloat.pi * 2)
                    
                    let path = UIBezierPath()
                    path.move(to: startPoint)
                    path.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: style == .sequentialCW)
                    path.addLine(to: center)
                    path.addLine(to: startPoint)
                    path.close()
                    
                    ctx?.addPath(path.cgPath)
                    ctx?.clip()
                    imageGraph.draw(in: bounds)
                    
                    guard let animImage = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else {
                        print("Failed to get a image of pie chart. Check \(#file) \(#line)")
                        return
                    }

                    values.append(animImage)
                    ctx?.clear(bounds)
                    ctx?.restoreGState()
                }
                
                let anim = CAKeyframeAnimation(keyPath: KRPieChart.animationKey)
                anim.duration = duration
                anim.values = values
                anim.fillMode = kCAFillModeForwards
                anim.isRemovedOnCompletion = false
                
                DispatchQueue.main.async { [weak weakSelf] in
                    guard let weakSelf = weakSelf else { return }
                    
                    CATransaction.begin()
                    CATransaction.setCompletionBlock({
                        weakSelf.displayChart()
                        completion?()
                    })
                    
                    weakSelf.layer.add(anim, forKey: KRPieChart.animationKey)
                    
                    CATransaction.commit()
                }
            }
        }
    }
    
    public func callWhenSafe(_ block: @escaping () -> Void) {
        if self.isDrawing {
            self.drawingQueue.async {
                DispatchQueue.main.async { block() }
            }
        } else {
            DispatchQueue.main.async { block() }
        }
        
    }
    
    // MARK: - Private
    
    private func removeAnimation() {
        self.layer.removeAnimation(forKey: KRPieChart.animationKey)
    }
    
}
