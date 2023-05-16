//
//  ConversationInputTextViewVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/6/2.
//

import RxSwift
import RxCocoa

class ConversationInputTextViewVM: BaseViewModel {
    enum InputStatus {
        case start, end, suspend
    }
    
    struct Input {
        let beginEditing = PublishSubject<Void>()
        let endEditing = PublishSubject<Void>()
        let suspended: BehaviorRelay<SuspendType?>
    }
    
    struct Output {
        let hintMessage: BehaviorRelay<String> = BehaviorRelay(value: Localizable.inputHint)
        let status: BehaviorRelay<InputStatus> = BehaviorRelay(value: .end)
        let textStringHeight: BehaviorRelay<CGFloat> = BehaviorRelay(value: 40)
        let textFont: UIFont = .midiumParagraphLargeLeft
        let padding: CGFloat = 8
        let content: BehaviorRelay<String?> = BehaviorRelay(value: nil)
        let resetContent = PublishSubject<Void>()
        let isInputOverOneCharactor: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    }
    
    var disposeBag = DisposeBag()
    let input: Input
    let output: Output = Output.init()
    let originalContent: String
    
    private(set) var status: InputStatus = .end {
        didSet {
            self.output.status.accept(status)
        }
    }
    
    let maxTextViewHeight: CGFloat = 196
    let minTextViewHeight: CGFloat = 40
    
    required init(with suspended: SuspendType? = nil, originalContent: String) {
        self.originalContent = originalContent
        self.output.content.accept(originalContent)
        self.input = Input.init(suspended: BehaviorRelay(value: suspended))
        super.init()
        self.initBinding()
    }
    
    func clearMessage() {
        self.output.resetContent.onNext(())
    }
    
    func updateStatusToEnd() {
        self.status = .end
    }
    
    func calculateTextView(_ textView: UITextView, replacementText text: String) {
        guard text == "" else {
            self.heightForTextView(textView: textView, text: textView.text + text)
            return
        }
        
        guard !textView.text.isEmpty else {
            self.heightForTextView(textView: textView, text: textView.text)
            return
        }
        
        let index: String.Index = textView.text.index(textView.text.startIndex, offsetBy: textView.text.count - 1)
        let subString: String = String(textView.text[..<index])
        self.heightForTextView(textView: textView, text: subString)
    }
    
    func heightForTextView(textView: UITextView, text: String) {
        let size = output.textFont.size(OfString: text, constrainedToWidth: textView.frame.width)
        let totHeight = max(size.height + 2 * output.padding, minTextViewHeight)
        output.textStringHeight.accept(min(totHeight, maxTextViewHeight))
    }
}

private extension ConversationInputTextViewVM {
    func initBinding() {
        self.input.beginEditing.subscribeSuccess { [unowned self] in
            guard self.input.suspended.value == nil else {
                return
            }
            self.status = .start
        }.disposed(by: self.disposeBag)
        
        self.input.endEditing.subscribeSuccess { [unowned self] in
            guard self.input.suspended.value == nil else {
                return
            }
            self.status = .end
        }.disposed(by: self.disposeBag)
        
        self.input.suspended.distinctUntilChanged().subscribeSuccess { [unowned self] suspended in
            self.setupSuspend(suspend: suspended)
        }.disposed(by: self.disposeBag)
    }
    
    func setupSuspend(suspend: SuspendType? = nil) {
        guard let suspend = suspend else {
            self.status = .end
            self.output.hintMessage.accept(Localizable.inputHint)
            return
        }
              
        self.status = .suspend
        self.output.hintMessage.accept(suspend.text)
    }
}
