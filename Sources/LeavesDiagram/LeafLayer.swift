//  Created by Danila Gusev on 09/10/22.
//  Copyright © 2022 josshad. All rights reserved.

import Foundation
import QuartzCore
import UIKit

final class LeafLayer: CALayer {
    private enum Const {
        static let cornerRadius: CGFloat = 5
        static let cornerCoef: CGFloat = 0.4
    }
    var color: UIColor
    var strokeColor: UIColor
    @NSManaged var startAngle: CGFloat
    @NSManaged var endAngle: CGFloat
    @objc var radius: CGFloat

    init(color: UIColor, strokeColor: UIColor? = nil, startAngle: CGFloat, endAngle: CGFloat, radius: CGFloat) {
        self.color = color
        self.radius = radius
        self.strokeColor = strokeColor ?? color
        super.init()
        self.startAngle = startAngle
        self.endAngle = endAngle
        contentsScale = UIScreen.main.scale
        shouldRasterize = true
        rasterizationScale = contentsScale
        drawsAsynchronously = true
    }

    override init(layer: Any) {
        guard let layer = layer as? LeafLayer else {
            color = .clear
            strokeColor = .clear
            radius = 0
            super.init(layer: layer)
            return
        }
        color = layer.color
        strokeColor = layer.strokeColor
        radius = layer.radius
        super.init(layer: layer)
        startAngle = layer.startAngle
        endAngle = layer.endAngle
        contentsScale = UIScreen.main.scale
        shouldRasterize = true
        rasterizationScale = contentsScale
        drawsAsynchronously = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override class func needsDisplay(forKey key: String) -> Bool {
        if key == #keyPath(LeafLayer.endAngle) ||
            key == #keyPath(LeafLayer.startAngle) ||
            key == #keyPath(LeafLayer.radius) {
            return true
        }
        return super.needsDisplay(forKey: key)
    }

    override func draw(in ctx: CGContext) {
        guard radius > Const.cornerRadius else {
            return
        }

        ctx.setFillColor(color.cgColor)
        ctx.setStrokeColor(strokeColor.cgColor)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let midAngle = (endAngle + startAngle) / 2
        var cornerRadius = Const.cornerRadius

        if endAngle - startAngle >= CGFloat2PI {
            cornerRadius = 0
        } else if endAngle - startAngle < CGFloatPI_2 {
            let d = max(0, floor(sin(endAngle - startAngle) * radius * Const.cornerCoef))
            cornerRadius = min(cornerRadius, d)
        }

        let dAngle = deltaAngle(radius, cornerRadius)
        guard !CGFloatEqual(cos(dAngle), 0) else { return }

        let tooSmallAngle = dAngle * 2 >= endAngle - startAngle
        let guidingRadius = radius/cos(dAngle)

        let firstPoint = CGPoint(x: center.x + guidingRadius * sin(startAngle), y: center.y - guidingRadius * cos(startAngle))
        let secondPoint = CGPoint(x: center.x + guidingRadius * sin(endAngle), y: center.y - guidingRadius * cos(endAngle))
        let middlePoint = CGPoint(x: center.x + radius * sin(midAngle), y: center.y - radius * cos(midAngle))

        let t2Point = CGPoint(x: center.x + radius * sin(startAngle + dAngle), y: center.y - radius * cos(startAngle + dAngle))
        ctx.move(to: center)
        ctx.addArc(tangent1End: firstPoint, tangent2End: t2Point, radius: cornerRadius)

        if tooSmallAngle {
            ctx.move(to: middlePoint)
        } else {
            let sAngle = startAngle + dAngle - CGFloatPI_2
            let eAngle = endAngle - dAngle - CGFloatPI_2
            ctx.addArc(center: center, radius: radius, startAngle: sAngle, endAngle: eAngle, clockwise: false)
        }
        ctx.addArc(tangent1End: secondPoint, tangent2End: center, radius: cornerRadius)
        ctx.addLine(to: center)
        ctx.closePath()
        ctx.drawPath(using: .fillStroke)
    }
}

private func deltaAngle(_ r: CGFloat, _ cornerRadius: CGFloat) -> CGFloat {
    guard r > cornerRadius else {
        return 0
    }
    if CGFloatEqual(r, cornerRadius) {
        return 0
    }

    return atan(cornerRadius/(r - cornerRadius))
}
