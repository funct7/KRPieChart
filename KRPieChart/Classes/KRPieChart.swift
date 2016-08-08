//
//  KRPieChart.swift
//  Pods
//
//  Created by Joshua Park on 8/8/16.
//
//

import UIKit

extension CGPoint {
    func getPointFromRadius(radius: CGFloat, angle: CGFloat) -> CGPoint {
        return CGPointMake(x + radius * cos(angle), y + radius * sin(angle))
    }
}

public enum KRPieChartAnimationStyle {
    case Sequential
    case Simultaneous
}

private let LAYER_ID_SEGMENT = "KRPieSegment"

public class KRPieChart: UIView {
    public var innerRadius: CGFloat = 0.0
    
    public var insets = UIEdgeInsetsZero
    public var segmentBorderColor = UIColor.clearColor()
    public var segmentBorderWidth = CGFloat(0.0)
    public var animateClockWise: Bool = true
    
    public func setSegments(segments: [CGFloat], colors: [UIColor]) {
        assert(segments.count == colors.count, "The number of elements in `segments` and `colors` must be the same.")
        assert(round(segments.reduce(CGFloat(0.0), combine: +)*10.0) / 10.0 == CGFloat(1.0), "The sum of elements in `segments` must be 1.0: \(segments.reduce(CGFloat(0.0), combine: +))")
        
        if let sublayers = layer.sublayers {
            for layer in sublayers { if layer.name == LAYER_ID_SEGMENT { layer.removeFromSuperlayer() } }
        }
        
        let width = bounds.width - (insets.left + insets.right)
        let height = bounds.height - (insets.top + insets.bottom)
        
        assert(width == height, "Width and height don't match.\n1. Check bounds: \(bounds).\n2. Check insets: \(insets).\n3. Ensure that `bounds.width - (horizontal insets)` == `bounds.height - (vertical insets)`")
        
        let frame = CGRectMake(insets.left, insets.top, width, height)
        let radius = width / 2.0
        let center = CGPointMake(frame.midX, frame.midY)
        var startAngle: CGFloat = CGFloat(1.5 * M_PI)
        
        for i in 0 ..< segments.count {
            let layer = CAShapeLayer()
            layer.name = LAYER_ID_SEGMENT
            
            let endAngle = startAngle + segments[i] * CGFloat(M_PI * 2)
            let path = UIBezierPath()
            path.moveToPoint(center.getPointFromRadius(radius, angle: startAngle))
            path.addArcWithCenter(center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: animateClockWise)
            path.addLineToPoint(center.getPointFromRadius(innerRadius, angle: endAngle))
            path.addArcWithCenter(center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: !animateClockWise)
            path.addLineToPoint(center.getPointFromRadius(radius, angle: startAngle))
            
            layer.fillColor = colors[i].CGColor
            layer.strokeColor = segmentBorderColor.CGColor
            layer.lineWidth = segmentBorderWidth
            
            layer.path = path.CGPath
            
            self.layer.addSublayer(layer)
            startAngle = endAngle
        }
    }
    
    // TODO: Implement
    //    public func animateWithDuration(duration: Double, style: KRPieChartAnimationStyle, completion: (() -> Void)?) {
    //    }
}
