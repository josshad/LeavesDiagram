//  Created by Danila Gusev on 09/10/22.
//  Copyright © 2022 josshad. All rights reserved.

import Foundation
import UIKit

public protocol LeavesDiagramViewDelegate: AnyObject {
    func diagramView(_ diagramView: LeavesDiagramView, didTapOn index: Int)
}

/**
 Datasource for LeavesDiagramView
 */
public protocol LeavesDiagramViewDataSource: AnyObject {
    /**
     Variable should return number of leaves for the diagram. It's called after reload()/reload(animated:) calls
     */
    var numberOfLeaves: Int { get }

    /**
     Color for a specific leaf. This variable called after reload()/reload(animated:) calls
     */
    func colorForLeaf(at index: Int) -> UIColor

    /**
     Value for a specific leaf. Can be provided as a percentage or as a specific value.
     */
    func valueForLeaf(at index: Int) -> Double
}

/**
 Custom diagram view that is able to present/reload its content with animation
 */
public final class LeavesDiagramView: UIView {
    typealias Model = LeafView.Model

    public enum LeafSelectionStyle {
        case none
        case opacity(CGFloat)
        case scale(CGFloat)

        public static let scale: Self = .scale(Const.highlightedScale)
        public static let opacity: Self = .opacity(Const.highlightedOpacity)
    }

    /**
     Delegate to handle selection of leaf
     */
    public weak var delegate: LeavesDiagramViewDelegate?

    /**
     Datasource to provide data to create diagram
     */
    public weak var dataSource: LeavesDiagramViewDataSource?

    /**
     Defines type of animation when highlight leaf.
     * opacity — changes alpha of the leaf (default — `0.95`)
     * scale — scales leaf (default — `1.1`)
     */
    public var leafSelectionStyle: LeafSelectionStyle = .scale

    private enum Const {
        static let minRadiusRatio: CGFloat = 1.5
        static let leafIntersection: CGFloat = 0.02
        static let highlightedOpacity: CGFloat = 0.95
        static let highlightedScale: CGFloat = 1.1
    }

    private var leaves: [LeafView] = []
    private var prevBounds: CGRect = .zero
    private var prevReloadCancelled = false
    private let radius: CGFloat
    private let fullAngle: CGFloat
    private let strokeColor: UIColor?

    /**
     - parameter radius: Maximum leaf radius. If not specified — than radius will be `min(height, width)/2`
     - parameter fullAngle: Angle between first and last leaf. Default is 2π (360°) — full circle
     - parameter strokeColor: Stroke color of each leaf. If not specified — same color as for leaf
     */
    public init(frame: CGRect, radius: CGFloat = .zero, fullAngle: CGFloat = .pi * 2, strokeColor: UIColor? = nil) {
        precondition(radius >= .zero)
        self.radius = radius
        self.fullAngle = fullAngle
        self.strokeColor = strokeColor
        super.init(frame: frame)
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
        radius > .zero ? radius : (min(rect.width, rect.height) / 2)
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
    public func reloadData(animated: Bool, completion: @escaping (Bool) -> Void = { _ in }) {
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
        let leavesCount = dataSource.numberOfLeaves
        guard leavesCount > 0 else { return [] }

        var models: [Model] = []
        var angle: CGFloat = 0
        var radius = leafRadius(for: bounds)
        let minRadius = radius / Const.minRadiusRatio
        let radiusDelta = (radius - minRadius) / CGFloat(leavesCount)
        let values = (0..<leavesCount).map { dataSource.valueForLeaf(at: $0) }
        let fullSum = values.reduce(0, +)

        for i in 0..<leavesCount {
            let color = dataSource.colorForLeaf(at: i)
            let startAngle = max(0, angle - Const.leafIntersection);
            let percent = values[i]/fullSum
            angle += percent * fullAngle
            let endAngle = angle;
            let model = Model(
                startAngle: startAngle,
                endAngle: endAngle,
                radius: radius,
                color: color,
                strokeColor: strokeColor
            )
            radius = max(minRadius, radius - radiusDelta);
            models.append(model)
        }
        return models
    }

    private func createLeafSubview(with model: Model) -> LeafView {
        let leaf = LeafView(frame: frame, model: model)
        leaf.selectionStyle = leafSelectionStyle.leafStyle
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

            let startKey = #keyPath(LeafLayer.startAngle)
            let startAnimation = wrapAnimation(for: leaf, with: startKey)

            let angleAnimation = CAAnimationGroup()
            angleAnimation.animations = [endAnimation, startAnimation]
            leaf.leafLayer.add(angleAnimation, forKey: endKey)

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

            let startKey = #keyPath(LeafLayer.startAngle)
            let startAnimation = unwrapAnimation(for: leaf, with: startKey)

            let angleAnimation = CAAnimationGroup()
            angleAnimation.animations = [endAnimation, startAnimation]
            if #available(iOS 15, *) {
                angleAnimation.preferredFrameRateRange = .init(minimum: 0, maximum: 0, preferred: nil)
            }

            leaf.leafLayer.add(angleAnimation, forKey: endKey)

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

private extension LeavesDiagramView.LeafSelectionStyle {
    var leafStyle: LeafView.SelectionStyle {
        switch self {
        case .none: return .identity
        case .opacity(let opacity): return .opacity(opacity)
        case .scale(let scale): return .scale(scale)
        }
    }
}
