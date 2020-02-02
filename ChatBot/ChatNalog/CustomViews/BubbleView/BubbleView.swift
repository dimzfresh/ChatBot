//
//  BubbleView.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 21/12/2019.
//  Copyright © 2019 kvantsoft. All rights reserved.
//

import UIKit

@IBDesignable
final class BubbleView: UIView {
    
    @IBInspectable
    var isOutgoing: Bool = true
    
    init(frame: CGRect, isOutgoing: Bool) {
        self.isOutgoing = isOutgoing
        super.init(frame: frame)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override func draw(_ rect: CGRect) {
        drawBubble(rect: rect)
    }
}

private extension BubbleView {
    func setup() {
        contentMode = .redraw
    }
    
    var outgoingColor: UIColor {
        return #colorLiteral(red: 0.6274509804, green: 0.368627451, blue: 0.7921568627, alpha: 1)
    }
    
    var incomingColor: UIColor {
        return #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    }
    
    func drawBubble(rect: CGRect) {
        let color = isOutgoing ? outgoingColor : incomingColor
        
        let rounding: CGFloat = 12.0
        
        let viewFrame = CGRect(x: 0.0, y: 8.0, width: rect.width, height: rect.height - 8.0)
        
        var corners: UIRectCorner {
            if isOutgoing {
                return [.bottomLeft, .bottomRight, .topLeft]
            } else {
                return [.bottomLeft, .bottomRight, .topRight]
            }
        }
        
        let cornerRadii = CGSize(width: rounding, height: rounding)
        let viewPath = UIBezierPath(roundedRect: viewFrame, byRoundingCorners: corners, cornerRadii: cornerRadii)
        
        color.setStroke()
        color.setFill()
        
        viewPath.stroke()
        viewPath.fill()
        
        var tailPath: UIBezierPath {
            if isOutgoing {
                let point = CGPoint(x: rect.maxX, y: rect.minY)
                return outgoingTailPath(from: point)
            } else {
                let point = CGPoint(x: rect.minX, y: rect.minY)
                return incomingTailPath(from: point)
            }
        }
        
        color.setFill()
        tailPath.fill()
    }
    
    func outgoingTailPath(from point: CGPoint) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: point)
        path.addQuadCurve(to: CGPoint(x: point.x - 24.0, y: point.y + 8.0), controlPoint: CGPoint(x: point.x, y: point.y + 8.0))
        path.addLine(to: CGPoint(x: point.x, y: point.y + 8.0))
        
        path.close()
        path.usesEvenOddFillRule = true
        
        return path
    }
    
    func incomingTailPath(from point: CGPoint) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: point)
        path.addQuadCurve(to: CGPoint(x: point.x + 24.0, y: point.y + 8.0), controlPoint: CGPoint(x: point.x, y: point.y + 8.0))
        path.addLine(to: CGPoint(x: point.x, y: point.y + 8.0))
        
        path.close()
        path.usesEvenOddFillRule = true
                
        return path
    }
}
