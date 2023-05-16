//
//  BaseSectionView.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/3.
//

import UIKit
import RxSwift

class BaseSectionView<T: BaseSectionVM>: UITableViewHeaderFooterView, ImplementViewModelProtocol {
    
    private(set) var disposeBag = DisposeBag()
    
    private(set) var viewModel: T! {
        didSet {
            self.bindViewModel()
            self.updateViews()
        }
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.disposeBag = DisposeBag()
    }
    
    func setupViews() {
        
    }
    
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
