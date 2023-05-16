//
//  BsseViewModelView.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/15.
//

import UIKit
import RxSwift

class BaseViewModelView<T: BaseViewModel>: UIView, ImplementViewModelProtocol {
    private(set) var disposeBag = DisposeBag()
    
    private(set) var viewModel: T! {
        willSet {
            self.unbindViewModel()
        }
        didSet {
            self.bindViewModel()
            self.updateViews()
        }
    }
    
    // MARK: - override function
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupViews()
    }
    
    // MARK: - custom init function
    convenience init(with viewModel: T) {
        self.init()
        self.viewModel = viewModel
        self.bindViewModel()
        self.updateViews()
    }
    
    // MARK: - personal function
    func unbindViewModel() {
        self.disposeBag = DisposeBag()
    }
    
    func setupViews() {
        
    }
    
    // MARK: - protocol
    func setupViewModel(viewModel: BaseViewModel) {
        if let vm = viewModel as? T {
            self.viewModel = vm
        }
    }
    
    func bindViewModel() {
        
    }
    
    func updateViews() {
        
    }
}
