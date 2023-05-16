//
//  GroupStatusCell.swift
//  ChatRoom
//
//  Created by Saffi Peng on 2021/7/20.
//

import UIKit
import RxSwift

class GroupStatusCell<T: GroupStatusCellVM>: ConversationBaseCell<T> {

    private lazy var textView: GroupStatusTextView = {
        let textView = GroupStatusTextView()
        textView.isUserInteractionEnabled = false
        return textView
    }()
    
    private lazy var hongBaoStatusView: HongBaoGroupStatusView = {
        let view = HongBaoGroupStatusView()
        return view
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        containerView.subviews.forEach {
            $0.removeFromSuperview()
        }
    }
    
    private func setupContentView(view: UIView) {
        containerView.addSubview(view)
        view.snp.makeConstraints { make in
            make.top.bottom.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
            make.height.greaterThanOrEqualTo(24)
        }
    }
    
    override func bindViewModel() {
        super.bindViewModel()
        
        // 根據 MessageType 決定 GroupStatus
        switch self.viewModel.type {
        case .hongBaoClaim:
            setupContentView(view: hongBaoStatusView)
        default:
            setupContentView(view: textView)
        }
        
        self.viewModel.groupStatus.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] status in
            switch self.viewModel.type {
            case .hongBaoClaim:
                self.hongBaoStatusView.setup(status: status)
            default:
                self.textView.text = status
                self.textView.sizeToFit()
            }
        }.disposed(by: self.disposeBag)
    }
}
