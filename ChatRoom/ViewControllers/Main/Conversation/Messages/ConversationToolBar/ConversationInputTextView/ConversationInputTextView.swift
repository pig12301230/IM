//
//  ConversationInputTextView.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/6/2.
//

import UIKit
import RxSwift

class ConversationInputTextView: BaseViewModelView<ConversationInputTextViewVM>, UITextViewDelegate {
    
    private lazy var textView: UITextView = {
        let view = UITextView.init()
        view.delegate = self
        view.theme_backgroundColor = Theme.c_07_neutral_100.rawValue
        view.keyboardType = .default
        return view
    }()
    
    private lazy var lblPlaceholder: UILabel = {
        let lbl = UILabel.init()
        lbl.font = .midiumParagraphLargeLeft
        lbl.textAlignment = .left
        lbl.theme_textColor = Theme.c_07_neutral_400.rawValue
        return lbl
    }()
    
    override func setupViews() {
        super.setupViews()
        self.layer.cornerRadius = 4
        self.clipsToBounds = true
        
        self.addSubview(self.textView)
        self.addSubview(self.lblPlaceholder)
        
        self.textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(40)
        }
        
        self.lblPlaceholder.snp.makeConstraints { make in
            make.leading.equalTo(self.textView.snp.leading).offset(16)
            make.trailing.equalTo(self.textView.snp.trailing).offset(-16)
            make.top.equalTo(self.textView.snp.top).offset(8)
        }
    }
    
    override func bindViewModel() {
        super.bindViewModel()
        self.textView.rx.didBeginEditing.bind(to: self.viewModel.input.beginEditing).disposed(by: self.disposeBag)
        self.textView.rx.didEndEditing.bind(to: self.viewModel.input.endEditing).disposed(by: self.disposeBag)
        self.textView.rx.text.map { !($0?.isEmpty ?? true) }.distinctUntilChanged().subscribeSuccess { [weak self] isOverOneCharactor in
            guard let self = self else { return }
            self.lblPlaceholder.isHidden = isOverOneCharactor
            self.viewModel.output.isInputOverOneCharactor.accept(isOverOneCharactor)
        }.disposed(by: self.disposeBag)
        self.viewModel.output.hintMessage.bind(to: self.lblPlaceholder.rx.text).disposed(by: self.disposeBag)
        self.viewModel.output.status.distinctUntilChanged().subscribeSuccess { [unowned self] staus in
            self.setupView(with: staus)
        }.disposed(by: self.disposeBag)
        
        // 沒有 suspend 狀態時, 才可以進行文字編輯
        self.viewModel.input.suspended.map { $0 == nil }.bind(to: self.textView.rx.isEditable).disposed(by: self.disposeBag)
        
        self.viewModel.output.textStringHeight.distinctUntilChanged().observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] height in
            self.textView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
                make.height.equalTo(height)
            }
        }.disposed(by: self.disposeBag)
        
        self.viewModel.output.resetContent.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] in
            self.textView.text = ""
            self.viewModel.calculateTextView(self.textView, replacementText: "")
        }.disposed(by: self.disposeBag)
        
        self.textView.text = self.viewModel.originalContent
        self.textView.rx.text.bind(to: self.viewModel.output.content).disposed(by: self.disposeBag)
    }
    
    override func updateViews() {
        super.updateViews()
        textView.font = viewModel.output.textFont
        textView.textContainerInset = UIEdgeInsets.init(top: viewModel.output.padding, left: 12, bottom: viewModel.output.padding, right: 12)
    }
    
    private func setupView(with status: ConversationInputTextViewVM.InputStatus) {
        if status == .suspend {
            self.textView.theme_backgroundColor = Theme.c_07_neutral_200.rawValue
            self.textView.text = nil
            self.lblPlaceholder.textAlignment = .center
            self.lblPlaceholder.font = .regularParagraphLargeLeft
        } else {
            self.textView.theme_backgroundColor = Theme.c_07_neutral_100.rawValue
            self.lblPlaceholder.textAlignment = .left
            self.lblPlaceholder.font = .midiumParagraphLargeLeft
            
            viewModel.calculateTextView(textView, replacementText: textView.text)
        }
        
        guard status == .end else {
            return
        }
        
        self.textView.resignFirstResponder()
    }
    
    private func resetInput() {
        self.textView.text = ""
    }
    
    // MARK: - text view delegate
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        viewModel.calculateTextView(textView, replacementText: text)
        return true
    }
}
