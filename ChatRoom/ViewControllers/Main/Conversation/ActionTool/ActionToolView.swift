//
//  ActionToolView.swift
//  ChatRoom
//
//  Created by ZoeLin on 2022/2/25.
//

import UIKit
import RxSwift

class ActionToolView: BaseViewModelView<ActionToolVM> {
    private let actionItemWidth: CGFloat = 56
    private lazy var anchorTopImage: UIImageView = {
        let img = UIImageView(image: UIImage(named: "gereralTooltipsTooltipPointerUp"))
        img.transform = CGAffineTransform(scaleX: 1, y: -1)
        return img
    }()
    
    private lazy var anchorBottomImage: UIImageView = {
        let img = UIImageView(image: UIImage(named: "gereralTooltipsTooltipPointerUp"))
        return img
    }()
    
    private lazy var stackView: UIStackView = {
        let sView = UIStackView()
        sView.axis = .horizontal
        sView.distribution = .fillEqually
        sView.spacing = 0
        sView.layer.cornerRadius = 4
        sView.theme_backgroundColor = Theme.c_07_neutral_700.rawValue
        return sView
    }()
    
    override func setupViews() {
        super.setupViews()
        self.addSubview(anchorTopImage)
        self.addSubview(anchorBottomImage)
        self.addSubview(stackView)
        self.backgroundColor = .clear
        
        anchorTopImage.frame.origin.y = 0
        anchorBottomImage.frame.origin.y = actionItemWidth
        anchorTopImage.alpha = 0
        anchorBottomImage.alpha = 0
    }
    
    override func bindViewModel() {
        super.bindViewModel()
        
        viewModel.output.actions.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] actions in
            self.setupActions(actions)
        }.disposed(by: disposeBag)
        
        viewModel.output.visible.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] visible  in
            self.alpha = visible ? 1 : 0
            guard visible else {
                return
            }
            self.setup(anchor: self.viewModel.setting.anchor)
        }.disposed(by: disposeBag)
    }
    
    func setup(anchor: AnchorPosition) {
        if anchor == .top {
            anchorTopImage.alpha = 0
            anchorBottomImage.alpha = 1
        } else {
            anchorTopImage.alpha = 1
            anchorBottomImage.alpha = 0
        }
    }
    
    private func setupActions(_ actions: [ActionType]) {
        alpha = 0
        stackView.frame.size.width = CGFloat(actions.count) * actionItemWidth
        
        stackView.removeAllArrangedSubviews()
        for (index, act) in actions.enumerated() {
            let view = ActionView.init(with: ActionView.Config(action: act, needLeftSeparate: index != 0))
            view.doAction = { [weak self] actionType in
                self?.viewModel.activeAction(actionType)
            }
            stackView.addArrangedSubview(view)
        }
        updateViewsLayout(count: actions.count)
    }
    
    private func updateViewsLayout(count: Int) {
        let stackWidth = CGFloat(count) * actionItemWidth
        setup(anchor: viewModel.setting.anchor)
        
        guard viewModel.setting.sender == .oneself else {
            anchorTopImage.frame.origin.x = actionItemWidth
            anchorBottomImage.frame.origin.x = actionItemWidth
            stackView.frame = CGRect(x: 52, y: viewModel.setting.anchor == .top ? 0 : 8, width: stackWidth, height: 64)
            UIView.animate(withDuration: 0.3) {
                self.alpha = 1
            }
            return
        }
        
        let positionX = frame.size.width - 36
        anchorTopImage.frame.origin.x = positionX
        anchorBottomImage.frame.origin.x = positionX
        stackView.frame = CGRect(x: frame.size.width - 8 - stackWidth, y: viewModel.setting.anchor == .top ? 0 : 8, width: stackWidth, height: 64)
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }
}
