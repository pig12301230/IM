//
//  ConversationToolBar.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/6/2.
//

import UIKit
import RxSwift

class ConversationToolBar: BaseViewModelView<ConversationToolBarVM> {
    
    private lazy var inputTextView: ConversationInputTextView = {
        let view = ConversationInputTextView.init()
        return view
    }()
    
    private lazy var attachmentView: AttachmentView = {
        let view = AttachmentView.init()
        return view
    }()
    
    private lazy var btnSend: UIButton = {
        let btn = UIButton.init(type: .custom)
        btn.setImage(UIImage.init(named: "buttonSendFill"), for: .normal)
        return btn
    }()
    
    private lazy var btnAdd: UIButton = {
        let btn = UIButton.init(type: .custom)
        btn.setImage(UIImage.init(named: "iconIconPlusAttachment"), for: .normal)
        return btn
    }()
    /*
    private lazy var btnSticker: UIButton = {
        let btn = UIButton.init(type: .custom)
        btn.setImage(UIImage.init(named: "iconIconSmile"), for: .normal)
        return btn
    }()*/
    
    override func setupViews() {
        super.setupViews()
        self.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        
        self.addSubview(self.inputTextView)
        self.addSubview(self.btnAdd)
        self.addSubview(self.btnSend)
//        self.addSubview(self.btnSticker)
        self.addSubview(self.attachmentView)
    }
    
    override func updateViews() {
        super.updateViews()
        self.inputTextView.setupViewModel(viewModel: self.viewModel.inputTextViewModel)
        self.attachmentView.setupViewModel(viewModel: self.viewModel.attachmentViewModel)
        
        let trailing = self.viewModel.input.suspended.value == .userBlocked ? -16 : -56
        self.inputTextView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(trailing)
            make.top.equalToSuperview().offset(8)
            make.bottom.equalTo(self.attachmentView.snp.top).offset(-8)
        }
        
        self.remakeAttachmentViewHeight(height: 0)
        
        self.btnSend.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.width.height.equalTo(32)
            make.centerY.equalTo(self.inputTextView)
        }
        
        self.btnAdd.snp.makeConstraints { make in
            make.trailing.width.height.equalTo(self.btnSend)
            make.centerY.equalTo(self.inputTextView)
        }
        /*
        self.btnSticker.snp.makeConstraints { make in
            make.trailing.equalTo(self.btnAdd.snp.leading).offset(-8)
            make.bottom.width.height.equalTo(self.btnAdd)
        }*/
        
    }
    
    override func bindViewModel() {
        super.bindViewModel()
        self.viewModel.output.status.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] status in
            self.setupView(with: status)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.output.isInputOverOneCharactor.distinctUntilChanged().subscribeSuccess { [unowned self] isInputOverOneCharactor in
            switch self.viewModel.input.suspended.value {
            case .userBlocked, .messageNotAllowed:
                self.btnSend.isHidden = true
                self.btnAdd.isHidden = true
            default:
                self.btnSend.isHidden = !isInputOverOneCharactor
                self.btnAdd.isHidden = isInputOverOneCharactor
            }
        }.disposed(by: self.disposeBag)
        
        self.btnAdd.rx.controlEvent(.touchUpInside).throttle(.seconds(2), scheduler: MainScheduler.instance).bind(to: self.viewModel.input.attachment).disposed(by: self.disposeBag)
//        self.btnSticker.rx.controlEvent(.touchUpInside).throttle(.seconds(2), scheduler: MainScheduler.instance).bind(to: self.viewModel.input.sticker).disposed(by: self.disposeBag)
        self.btnSend.rx.controlEvent(.touchUpInside).throttle(.seconds(2), scheduler: MainScheduler.instance).bind(to: self.viewModel.input.send).disposed(by: self.disposeBag)
    }
    
    private func setupView(with status: ConversationToolBarVM.ToolBarStatus) {
        guard status != .suspend, self.viewModel.input.suspended.value == nil else {
            self.setupSuspendUI()
            return
        }
//        self.btnSticker.isHidden = status == .typing
        self.attachmentView.isHidden = status != .sticker && status != .attachment
        
        // TODO: 等有 sticker 功能時, show sticker View
        switch status {
        case .attachment:
            self.showAttachmentView(with: 110)
        case .endTyping:
            self.btnSend.isHidden = !self.viewModel.output.isInputOverOneCharactor.value
            self.btnAdd.isHidden = self.viewModel.output.isInputOverOneCharactor.value
            self.remakeInputTextViewConstraints(trailing: -56)
            self.remakeAttachmentViewHeight(height: 0)
        case .typing:
            self.remakeInputTextViewConstraints(trailing: -56)
            self.remakeAttachmentViewHeight(height: 0)
        default:
            self.remakeAttachmentViewHeight(height: 0)
        }
    }
    
    func setupSuspendUI() {
        self.btnSend.isHidden = true
        self.btnAdd.isHidden = true
//        self.btnSticker.isHidden = true
        self.attachmentView.isHidden = true
        self.remakeAttachmentViewHeight(height: 0)
        self.remakeInputTextViewConstraints(trailing: -16)
    }

    func showAttachmentView(with height: CGFloat) {
        // attachmentView出現與聊天室內容ScrollToBottom為一個完整動作
        UIView.animate(withDuration: 0) {
            self.remakeAttachmentViewHeight(height: height)
            self.viewModel.output.attachmentAppear.accept(())
        }
    }
    
    func remakeAttachmentViewHeight(height: CGFloat) {
        self.attachmentView.snp.remakeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(height)
        }
    }
    
    func remakeInputTextViewConstraints(trailing: CGFloat) {
        self.inputTextView.snp.remakeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(trailing)
            make.top.equalToSuperview().offset(8)
            make.bottom.equalTo(self.attachmentView.snp.top).offset(-8)
        }
    }
}
