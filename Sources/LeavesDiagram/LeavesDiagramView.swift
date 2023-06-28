import Foundation
import UIKit

public protocol LeavesDiagramViewDelegate: AnyObject {
    func diagramView(_ diagramView: LeavesDiagramView, didTapOn index: Int)
}

public protocol LeavesDiagramViewDataSource: AnyObject {
    var numberOfLeavesForLeavesDiagramView: Int { get }
    func colorForLeaf(at index: Int) -> UIColor
    func percentForLeaf(at index: Int) -> Double
}

public final class LeavesDiagramView: UIView {
    typealias Model = LeafView.Model

    public weak var delegate: LeavesDiagramViewDelegate?
    public weak var dataSource: LeavesDiagramViewDataSource?

    private enum Const {
        static let minRadiusRatio: CGFloat = 1.5
        static let leafIntersection: CGFloat = 0.02
    }

    private var leaves: [LeafView] = []
    private var prevBounds: CGRect = .zero
    private var prevReloadCancelled = false
    private let radius: CGFloat
    private let snailFullAngle: CGFloat


    public init(frame: CGRect, radius: CGFloat, snailFullAngle: CGFloat = .pi * 2) {
        precondition(radius >= .zero)
        self.radius = radius
        self.snailFullAngle = snailFullAngle
        super.init(frame: frame)
    }

    public override convenience init(frame: CGRect) {
        self.init(frame: frame, radius: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Layouting
    override public func layoutSubviews() {
        super.layoutSubviews()

        defer { prevBounds = bounds }

        let prevRadius = leafRadius(for: prevBounds)
        let newRadius = leafRadius(for: bounds)
        let needToUpdateRadius = !CGFloatEqual(prevRadius, newRadius)

        if (needToUpdateRadius) {
            updateLeavesRadius()
        }

        leaves.forEach { l in
            if !CGRectEqualToRect(l.frame, bounds) {
                l.frame = bounds
                l.setNeedsLayout()
            }
        }
    }

    private func leafRadius(for rect: CGRect) -> CGFloat {
        radius > .zero ? radius : CGRectGetMidX(bounds)
    }

    private func updateLeavesRadius() {
        let newModels = createModels()
        guard newModels.count == leaves.count else {
            // inconsistent number of leaves and models. Skip updating radius.
            return;
        }

        for i in 0..<newModels.count {
            self.leaves[i].radius = newModels[i].radius;
        }
    }

    // MARK: Reload data
    public func reloadData(animated: Bool, completion: @escaping (Bool) -> Void) {
        self.cancelAnimations()
        guard animated else {
            reloadData()
            completion(true)
            return
        }
        wrap { [weak self] finished in
            guard let self = self else { return }
            guard finished else {
                completion(false)
                return
            }
            let models = self.createModels()
            self.unwrap(models: models, completion: completion)
        }
    }

    func reloadData() {
        leaves.forEach { $0.removeFromSuperview() }

        let models = createModels()
        var leaves: [LeafView] = []
        for model in models {
            let leaf = createLeafSubview(with: model)
            insertSubview(leaf, at: .zero)
            leaves.append(leaf)
        }
        self.leaves = leaves
    }

    private func cancelAnimations() {
        guard let leafLayer = leaves.first?.leafLayer, let animations = leafLayer.animationKeys(), !animations.isEmpty else {
            return
        }

        prevReloadCancelled = true
        leaves.map(\.layer).forEach { $0.removeAllAnimations() }
    }

    private func createModels() -> [Model] {
        guard let dataSource = dataSource else { return [] }
        let leavesCount = dataSource.numberOfLeavesForLeavesDiagramView
        guard leavesCount > 0 else { return [] }

        var models: [Model] = []
        var angle: CGFloat = 0
        var radius = leafRadius(for: bounds)
        let minRadius = radius / Const.minRadiusRatio
        let radiusDelta = (radius - minRadius) / CGFloat(leavesCount)
        for i in 0..<leavesCount {
            let color = dataSource.colorForLeaf(at: i)
            let startAngle = max(0, angle - Const.leafIntersection);
            let percent = dataSource.percentForLeaf(at: i)
            angle += percent * CGFloat.pi * 2
            let endAngle = angle;
            let model = Model(startAngle: startAngle, endAngle: endAngle, radius: radius, color: color)
            radius = max(minRadius, radius - radiusDelta);
            models.append(model)
        }
        return models
    }

    private func createLeafSubview(with model: Model) -> LeafView {
        let leaf = LeafView(frame: frame, model: model)

        leaf.addTarget(self, action: #selector(didTapOnLeaf), for: .touchUpInside)
        return leaf;
    }

    // MARK: Touches
    @objc private func didTapOnLeaf(_ leaf: LeafView) {
        guard let delegate = delegate else { return }
        guard let index = leaves.firstIndex(of: leaf) else { return }
        delegate.diagramView(self, didTapOn: index)
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if self == view {
            return nil
        }
        return view
    }
}

// MARK: Animations
private extension LeavesDiagramView {
    func wrap(completion: @escaping (Bool) -> Void) {
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            completion(!self.prevReloadCancelled)
            self.prevReloadCancelled = false
        }

        for leaf in leaves {
            let endKey = #keyPath(LeafLayer.endAngle)
            let endAnimation = wrapAnimation(for: leaf, with: endKey)
            leaf.leafLayer.add(endAnimation, forKey: endKey)

            let startKey = #keyPath(LeafLayer.startAngle)
            let startAnimation = wrapAnimation(for: leaf, with: startKey)
            leaf.leafLayer.add(startAnimation, forKey: startKey)
            leaf.endAngle = 0;
            leaf.startAngle = 0;
        }

        CATransaction.commit()
    }

    func unwrap(models: [Model], completion: @escaping (Bool) -> Void) {
        leaves.forEach { $0.removeFromSuperview() }

        var leaves: [LeafView] = []

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            completion(!self.prevReloadCancelled)
            self.prevReloadCancelled = false
        }

        for model in models {
            let leaf = createLeafSubview(with: model)
            insertSubview(leaf, at: 0)

            let endKey = #keyPath(LeafLayer.endAngle)
            let endAnimation = unwrapAnimation(for: leaf, with: endKey)
            leaf.leafLayer.add(endAnimation, forKey: endKey)

            let startKey = #keyPath(LeafLayer.startAngle)
            let startAnimation = unwrapAnimation(for: leaf, with: startKey)
            leaf.leafLayer.add(startAnimation, forKey: startKey)

            leaves.append(leaf)
        }
        self.leaves = leaves
        CATransaction.commit()
    }

    func wrapAnimation(for leaf: LeafView, with key: String) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: key)
        animation.duration = CATransaction.animationDuration()
        animation.fromValue = leaf.leafLayer.presentation()?.value(forKey: key) as? CGFloat
        animation.toValue = 0
        return animation
    }

    func unwrapAnimation(for leaf: LeafView, with key: String) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: key)
        animation.duration = CATransaction.animationDuration()
        animation.fromValue = 0
        animation.toValue = leaf.leafLayer.value(forKey: key) as? CGFloat
        return animation;
    }

}
