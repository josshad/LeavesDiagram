import Foundation
import QuartzCore
import UIKit

final class LeafLayer: CALayer {
    private enum Const {
        static let cornerRadius: CGFloat = 5
        static let cornerCoef: CGFloat = 0.4
    }
    var color: UIColor
    @NSManaged var startAngle: CGFloat
    @NSManaged var endAngle: CGFloat
    @objc var radius: CGFloat

    init(color: UIColor, startAngle: CGFloat, endAngle: CGFloat, radius: CGFloat) {
        self.color = color
        self.radius = radius
        super.init()
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.contentsScale = UIScreen.main.scale
    }

    override init(layer: Any) {
        guard let layer = layer as? LeafLayer else {
            self.color = .clear
            self.radius = 0
            super.init(layer: layer)
            return
        }
        self.color = layer.color
        self.radius = layer.radius
        super.init(layer: layer)
        self.startAngle = layer.startAngle
        self.endAngle = layer.endAngle
        self.contentsScale = UIScreen.main.scale
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

        ctx.setShouldAntialias(true)
        ctx.setFillColor(color.cgColor)

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let midAngle = (endAngle + startAngle) / 2
        var cornerRadius = Const.cornerRadius

        if endAngle - startAngle >= 2 * CGFloat.pi {
            cornerRadius = 0
        } else if endAngle - startAngle < CGFloat.pi / 2 {
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

        if tooSmallAngle {
            ctx.move(to: middlePoint)
        } else {
            let sAngle = midAngle - (CGFloat.pi / 2)
            let eAngle = startAngle + dAngle - (CGFloat.pi / 2)
            ctx.move(to: middlePoint)
            ctx.addArc(center: center, radius: radius, startAngle: sAngle, endAngle: eAngle, clockwise: false)
        }
        ctx.addArc(tangent1End: firstPoint, tangent2End: center, radius: cornerRadius)
        ctx.addLine(to: center)
        if tooSmallAngle {
            ctx.move(to: middlePoint)
        } else {
            ctx.move(to: middlePoint)
            let sAngle = midAngle - (CGFloat.pi / 2)
            let eAngle = self.endAngle - dAngle - (CGFloat.pi / 2)
            ctx.addArc(center: center, radius: radius, startAngle: sAngle, endAngle: eAngle, clockwise: true)
        }
        ctx.addArc(tangent1End: secondPoint, tangent2End: center, radius: cornerRadius)
        ctx.addLine(to: center)
        ctx.fillPath()
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
