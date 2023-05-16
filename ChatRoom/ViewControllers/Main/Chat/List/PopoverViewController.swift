//
//  PopoverViewController.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/6/29.
//

import UIKit

class PopoverView: UIView {
    private lazy var containerBG: UIImageView = {
        let capInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 32)
        let capImage = UIImage(named: "Tooltip_Top_Right.9")?.resizableImage(withCapInsets: capInset, resizingMode: .stretch)
        return UIImageView(image: capImage)
    }()
    
    private lazy var popupContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var actionContainer: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.distribution = .fillEqually
        return view
    }()
    
    private lazy var tap: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(close))
        return gesture
    }()
    
    private let actionHeight: CGFloat = 48
    private let itemsTopEdge: CGFloat = 8
    
    func show(at target: UIView?, actions: [UIView]) {
        guard let target = target else { return }
        actions.forEach {
            actionContainer.addArrangedSubview($0)
        }
        addGestureRecognizer(tap)
        
        addSubview(popupContainer)
        
        let totalActionHeight: CGFloat = CGFloat(actions.count) * actionHeight
        let targetPoint = target.convert(CGPoint(x: (target.frame.minX + target.frame.maxX) / 2,
                                                 y: target.frame.maxY),
                                         to: appDelegate?.window)
        
        let actionWidth: CGFloat = 160
        popupContainer.snp.makeConstraints {
            let trailing = targetPoint.x - UIScreen.main.bounds.width + 20
            let top = targetPoint.y - 4
            $0.trailing.equalTo(trailing)
            $0.top.equalTo(top)
            $0.width.equalTo(actionWidth)
            $0.height.equalTo(totalActionHeight + itemsTopEdge)
        }

        popupContainer.addSubview(containerBG)
        containerBG.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        popupContainer.addSubview(actionContainer)
        actionContainer.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.top.equalToSuperview().offset(itemsTopEdge)
        }
        
        self.frame = appDelegate?.window?.bounds ?? .zero
        appDelegate?.window?.addSubview(self)
    }
    
    func updateView(actionViews: [UIView]) {
        actionContainer.removeAllArrangedSubviews()
        actionViews.forEach {
            actionContainer.addArrangedSubview($0)
        }
        
        let totalActionHeight: CGFloat = CGFloat(actionViews.count) * actionHeight
        popupContainer.snp.updateConstraints {
            $0.height.equalTo(totalActionHeight + itemsTopEdge)
        }
    }
}

@objc extension PopoverView {
    func close() {
        self.removeFromSuperview()
    }
}
