import Foundation
import UIKit

final class LeafView: UIControl {
    private enum Const {
        static let highlightedAlpha: CGFloat = 0.95
    }
    private var _leafLayer: LeafLayer

    init(frame: CGRect, color: UIColor, startAngle: CGFloat, endAngle: CGFloat, radius: CGFloat) {
        precondition(radius >= .zero)
        _leafLayer = LeafLayer(color: color, startAngle: startAngle, endAngle: endAngle, radius: radius)
        super.init(frame: frame)
        layer.addSublayer(_leafLayer)
    }

    @available(*, unavailable)
    required init() {
        fatalError("init() has not been implemented")
    }

    @available(*, unavailable)
    override init(frame: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        _leafLayer.frame = bounds
    }

    // MARK: Accessors & Mutators
    var color: UIColor {
        get {
            _leafLayer.color
        }
        set {
            _leafLayer.color = newValue
        }
    }

    var startAngle: CGFloat {
        get {
            _leafLayer.startAngle
        }
        set {
            _leafLayer.startAngle = newValue
        }
    }

    var endAngle: CGFloat {
        get {
            _leafLayer.endAngle
        }
        set {
            _leafLayer.endAngle = newValue
        }
    }

    var radius: CGFloat {
        get {
            _leafLayer.radius
        }
        set {
            _leafLayer.endAngle = newValue
        }
    }

    var leafLayer: CALayer {
        _leafLayer
    }

    override var isHighlighted: Bool {
        get {
            super.isHighlighted
        }
        set {
            super.isHighlighted = newValue
            self.alpha = newValue ? Const.highlightedAlpha : 1
        }
    }

    // MARK: Touches
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let distance = point.distance(to: point)

        if (distance < radius) {
            let x = point.x - center.x
            let y = center.y - point.y
            var angle: CGFloat = 0
            if !CGFloatEqual(y, 0) {
                angle = atan2(x, y)
                angle = angle < 0 ? angle + CGFloat.pi * 2 : angle
            } else {
                angle = x > 0 ? CGFloat.pi/2 : 3 * CGFloat.pi/2
            }
            if isAngleInside(angle: angle, start: startAngle, end: endAngle) {
                return self
            }
        }
        return nil
    }
}

extension LeafView {
    struct Model: Equatable {
        let startAngle: CGFloat
        let endAngle: CGFloat
        let radius: CGFloat
        let color: UIColor
    }

    convenience init(frame: CGRect, model: Model) {
        self.init(frame: frame, color: model.color, startAngle: model.startAngle, endAngle: model.endAngle, radius: model.radius)
    }
}

private extension CGPoint {
    func distance(to: CGPoint) -> CGFloat {
        let x = (x - to.x)
        let y = (y - to.y)
        return sqrt(x * x + y * y)
    }
}

private func isAngleInside(angle: CGFloat, start: CGFloat, end: CGFloat) -> Bool {
    let endAngle = CGFloatNormalizedAngle(end)
    let startAngle = CGFloatNormalizedAngle(start)
    if endAngle <= startAngle && !CGFloatEqual(start, end) {
        if CGFloatCompare(angle, endAngle) != .orderedDescending || CGFloatCompare(angle, startAngle) != .orderedAscending {
            return true
        }
    } else if CGFloatCompare(angle, startAngle) == .orderedDescending && CGFloatCompare(angle, endAngle) == .orderedAscending {
        return true
    }
    return false
}

