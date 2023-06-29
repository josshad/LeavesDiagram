//
//  ViewController.swift
//  Snail
//
//  Created by Danila Gusev on 21.06.2023.
//

import UIKit
import LeavesDiagram

class ViewController: UIViewController {
    private enum Const {
        static let contentHeight: CGFloat = 320
        static let diagramRadius: CGFloat = 150
        static let centerCircleSide: CGFloat = 40
        static let centerCircleShadowOffset = CGSize(width: 0, height: 4)
    }
    private var selectedSnail: Int = 0
    private var colors: [UIColor] = []

    lazy var diagramView: LeavesDiagramView = {
        let view = LeavesDiagramView(frame: .zero, radius: Const.diagramRadius)
        view.leafSelectionStyle = .scale(0.9)
        view.delegate = self
        view.dataSource = self
        return view
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(refresh), for: .valueChanged)
        control.tintColor = .black
        return control
    }()

    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView(frame: .zero)
        view.showsVerticalScrollIndicator = false
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.alwaysBounceVertical = true
        view.refreshControl = refreshControl
        return view
    }()

    private lazy var circle: UIView = {
        let circle = UIView(frame: CGRect(x: 0, y: 0, width: Const.centerCircleSide, height: Const.centerCircleSide))
        circle.backgroundColor = .white
        circle.layer.cornerRadius = Const.centerCircleSide/2
        circle.layer.shadowOpacity = 0.2
        circle.layer.shadowColor = UIColor.lightGray.cgColor
        circle.layer.shadowOffset = Const.centerCircleShadowOffset
        return circle
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.addSubview(diagramView)
        view.addSubview(circle)
        return view
    }()

    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        refresh()
        self.view = view
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentView.frame = CGRectMake(0, 0, view.bounds.width, Const.contentHeight)
        diagramView.frame = contentView.bounds
        circle.center = diagramView.center
    }

    @objc private func refresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.reload()
        }
    }

    private func reload() {
        refreshControl.endRefreshing()
        selectedSnail = Int.random(in: 0..<Preview.leaves.count)
        colors = percents.map { _ in
            UIColor.color(with: Int.random(in: 0x444444...0xffffff))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + CATransaction.animationDuration()) {
            self.diagramView.reloadData(animated: true) { _ in }
        }
    }
}

extension ViewController: LeavesDiagramViewDataSource, LeavesDiagramViewDelegate {
    private enum Preview {
        static let leaves1: [Double] = [0.54, 0.11, 0.1, 0.08, 0.06, 0.06, 0.05]
        static let leaves2: [Double] = [50, 30, 20, 10, 5, 4, 4, 3, 2, 1]
        static let leaves3: [Double] = [1, 1, 3, 5]
        static let leaves4: [Double] = [0.25, 0.2, 0.2, 0.2, 0.15]

        static let leaves: [[Double]] = [leaves1, leaves2, leaves3, leaves4]
    }
    private var percents: [Double] {
        Preview.leaves[selectedSnail]
    }

    var numberOfLeaves: Int {
        percents.count
    }

    func valueForLeaf(at index: Int) -> Double {
        percents[index]
    }

    func colorForLeaf(at index: Int) -> UIColor {
        colors[index]
    }

    func diagramView(_ diagramView: LeavesDiagramView, didTapOn index: Int) {
        let alert = UIAlertController(
            title: "Selected leaf \(index)",
            message: "Percent for leaf: \(percents[index])",
            preferredStyle: .alert
        )
        alert.addAction(.init(
            title: "Ok",
            style: .default
        ) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        self.present(alert, animated: true)
    }
}

private extension UIColor {
    static func color(with hex: Int) -> UIColor {
        let bComponent = CGFloat(hex & 0xFF)
        let gComponent = CGFloat(hex >> 8 & 0xFF)
        let rComponent = CGFloat(hex >> 16 & 0xFF)

        return UIColor(red: rComponent/255.0, green: gComponent/255.0, blue: bComponent/255.0, alpha: 1)
    }
}
