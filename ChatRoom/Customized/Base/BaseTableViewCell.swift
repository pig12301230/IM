//
//  BaseTableViewCell.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/3.
//

import UIKit
import RxSwift

class BaseTableViewCell<T: BaseViewModel>: UITableViewCell, ImplementViewModelProtocol {
    var disposeBag = DisposeBag()
    
    private(set) var viewModel: T! {
        willSet {
            self.disposeBag = DisposeBag()
        }
        didSet {
            self.bindViewModel()
            self.updateViews()
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupViews()
        self.initBinding()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.disposeBag = DisposeBag()
    }
    
    func initBinding() {
        
    }
    
    func setupViews() {
        
    }
    
    /// protpcol
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
